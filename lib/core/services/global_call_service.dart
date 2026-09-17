import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cagh_frontend/main.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/callkit_service.dart';
import 'package:cagh_frontend/core/services/global_call_websocket_manager.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';

enum CallSignalType {
  callOffer,
  callAccepted,
  callDeclined,
  callEnded,
  callCancelled,
  pingPong,
  unknown,
}

enum CallState {
  idle,
  incomingRinging,
  outgoingRinging,
  connecting,
  connected,
  declined,
  cancelled,
  missed,
  ended,
}

class IncomingCallEvent {
  final String callId;
  final String consultationId;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String callType;
  final int timestamp;
  final Map<String, dynamic> rawData;

  IncomingCallEvent({
    required this.callId,
    required this.consultationId,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    this.callType = 'voice',
    int? timestamp,
    required this.rawData,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory IncomingCallEvent.fromMap(Map<String, dynamic> map, {String defaultConsultationId = '', String defaultAppointmentId = ''}) {
    final effectiveDefaultId = defaultConsultationId.isNotEmpty ? defaultConsultationId : defaultAppointmentId;
    final consultationId = (map['consultation_id'] ?? map['appointment_id'] ?? effectiveDefaultId).toString();
    final callId = (map['call_id'] ?? map['id'] ?? consultationId).toString();
    final callerId = GlobalCallService.extractId(
      map['caller_id'] ?? map['sender_id'] ?? map['caller'] ?? map['sender'] ?? map['user_id']
    );
    final calleeId = GlobalCallService.extractId(
      map['callee_id'] ?? map['receiver_id'] ?? map['recipient_id'] ?? map['receiver'] ?? map['recipient']
    );
    final rawName = (map['caller_name'] ?? map['sender_name'] ?? map['sender_full_name'] ?? map['caller']?['name'] ?? 'Care Provider').toString();
    final callerName = NameFormatter.format(rawName);
    final callType = (map['call_type'] ?? map['type'] ?? 'voice').toString();
    final tsRaw = map['timestamp'];
    int? ts;
    if (tsRaw != null) {
      ts = int.tryParse(tsRaw.toString());
    }

    return IncomingCallEvent(
      callId: callId.isNotEmpty ? callId : consultationId,
      consultationId: consultationId,
      callerId: callerId,
      callerName: callerName.isNotEmpty ? callerName : 'Care Provider',
      calleeId: calleeId,
      callType: callType,
      timestamp: ts,
      rawData: map,
    );
  }
}

enum CallTerminalReason { decline, hangup, cancel, timeout, remoteOffline, authFailure, stale409 }
enum CallFailureReason { stale409, authentication, network, backend, invalidState }

class PendingCallAction {
  final String type;
  final String callId;
  final String consultationId;
  final int timestamp;
  final Map<String, dynamic> extra;

  PendingCallAction({
    required this.type,
    required this.callId,
    required this.consultationId,
    int? timestamp,
    required this.extra,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  static const String _prefKey = 'pending_call_action_json';
  static const int _pendingMaxAgeMs = 60000;

  static Future<void> persist(PendingCallAction action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode({
      'type': action.type,
      'call_id': action.callId,
      'consultation_id': action.consultationId,
      'timestamp': action.timestamp,
      'extra': action.extra,
    }));
  }

  static Future<void> processIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr == null || jsonStr.isEmpty) return;

    try {
      final map = jsonDecode(jsonStr);
      final tsRaw = map['timestamp'];
      final ts = tsRaw != null ? int.tryParse(tsRaw.toString()) ?? 0 : 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (ts > 0 && (now - ts) > _pendingMaxAgeMs) {
        AppLogger.d('[PENDING ACTION] Pending action expired (>60s), discarding safely');
        await prefs.remove(_prefKey);
        return;
      }

      final typeStr = (map['type'] ?? '').toString();
      final callId = (map['call_id'] ?? '').toString();
      final consultationId = (map['consultation_id'] ?? '').toString();
      final extra = Map<String, dynamic>.from(map['extra'] ?? {});

      final effectiveId = consultationId.isNotEmpty ? consultationId : callId;
      if (IncomingCallActionDispatcher.hasBeenAccepted(effectiveId) ||
          GlobalCallService.isCallActive ||
          GlobalCallService.stateMachine.state == CallState.connecting ||
          GlobalCallService.stateMachine.state == CallState.connected) {
        AppLogger.d('[PENDING ACTION] Call $effectiveId already accepted or active, discarding pending $typeStr action');
        await prefs.remove(_prefKey);
        return;
      }

      AppLogger.d('[PENDING ACTION] Replaying queued $typeStr action for call $callId');
      if (typeStr == 'accept') {
        await IncomingCallActionDispatcher.dispatchAccept(callId, consultationId, extra, source: 'RESTORE_PENDING_CALL');
      } else if (typeStr == 'decline') {
        await IncomingCallActionDispatcher.dispatchDecline(callId, consultationId);
      }
      await prefs.remove(_prefKey);
    } catch (e) {
      AppLogger.d('[PENDING ACTION] Error replaying queued action: $e');
    }
  }
}

class CallNavigationCoordinator {
  static bool _isNavigating = false;
  static Map<String, dynamic>? _pendingAcceptedCallMap;
  static String? _activeConsultationIdNavigated;

  static bool get hasCallNavigationActiveOrPending =>
      _isNavigating ||
      _pendingAcceptedCallMap != null ||
      GlobalCallService.isCallActive ||
      GlobalCallService.stateMachine.state == CallState.connecting ||
      GlobalCallService.stateMachine.state == CallState.connected;

  static void checkAndNavigatePendingCall() {
    if (_pendingAcceptedCallMap != null && globalNavigatorKey.currentContext != null) {
      final map = Map<String, dynamic>.from(_pendingAcceptedCallMap!);
      _pendingAcceptedCallMap = null;
      AppLogger.d('[CALL NAVIGATION] Replaying pending accepted call navigation');
      navigateToVoiceCallScreen(
        consultationId: (map['consultationId'] ?? '').toString(),
        callId: (map['callId'] ?? '').toString(),
        callerName: (map['callerName'] ?? '').toString(),
        receiverName: (map['receiverName'] ?? '').toString(),
        callerId: (map['callerId'] ?? '').toString(),
        receiverId: (map['receiverId'] ?? '').toString(),
      );
    }
  }

  static void navigateToVoiceCallScreen({
    required String consultationId,
    required String callId,
    required String callerName,
    required String receiverName,
    required String callerId,
    required String receiverId,
  }) {
    if (_isNavigating) {
      AppLogger.d('[CALL NAVIGATION] VoiceCallScreen navigation already in progress');
      return;
    }
    if (GlobalCallService.isCallActive && _activeConsultationIdNavigated == consultationId) {
      AppLogger.d('[CALL NAVIGATION] Already on VoiceCallScreen for consultation $consultationId, skipping duplicate push.');
      return;
    }
    _isNavigating = true;

    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      AppLogger.d('[CALL NAVIGATION] globalNavigatorKey context is null, storing pending accepted call navigation');
      _pendingAcceptedCallMap = {
        'consultationId': consultationId,
        'callId': callId,
        'callerName': callerName,
        'receiverName': receiverName,
        'callerId': callerId,
        'receiverId': receiverId,
      };
      _isNavigating = false;
      return;
    }

    _pendingAcceptedCallMap = null;
    _activeConsultationIdNavigated = consultationId;
    GlobalCallService.isCallActive = true;
    globalNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => VoiceCallScreen(
          consultationId: consultationId,
          appointment: Appointment(
            appointmentId: consultationId,
            userId: callerId,
            midwifeId: receiverId,
            date: '',
            startTime: '',
            endTime: '',
            appointmentType: 'VIRTUAL_VOICE',
            status: AppointmentStatus.confirmed,
            userFullName: callerName,
            midwifeName: receiverName.isNotEmpty && receiverName != 'Recipient' ? receiverName : 'Midwife',
          ),
          isCaller: false,
          isIncomingCall: true,
        ),
      ),
    ).then((_) {
      _isNavigating = false;
      _activeConsultationIdNavigated = null;
    });
  }
}

class IncomingCallActionDispatcher {
  static final Map<String, int> _actionTimestamps = {};
  static const int _dedupTtlMs = 1500;

  static bool _isDuplicate(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _actionTimestamps[key];
    if (last != null && (now - last) < _dedupTtlMs) {
      return true;
    }
    _actionTimestamps[key] = now;
    return false;
  }

  static final Set<String> _acceptedConsultationIds = {};
  static bool _acceptInProgress = false;

  static bool hasBeenAccepted(String id) {
    if (id.isEmpty || id == 'null') return false;
    return _acceptedConsultationIds.contains(id);
  }

  static Future<void> dispatchAccept(
    String callId,
    String consultationId,
    Map<String, dynamic> extra, {
    required String source,
  }) async {
    final effectiveConsultationId = (consultationId.isNotEmpty && consultationId != 'null')
        ? consultationId
        : (callId.isNotEmpty && callId != 'null' ? callId : (GlobalCallService.activeConsultationId ?? ''));

    final currentState = GlobalCallService.stateMachine.state;
    AppLogger.d('[CALL ACCEPT V2] dispatchAccept execution started source=$source call_id=$effectiveConsultationId state=$currentState');
    AppLogger.d('[CALL_TRACE] CALL_ACCEPT_REQUESTED source=$source call_id=$effectiveConsultationId');
    AppLogger.d('[CALL-LIFECYCLE] ACCEPTED source=$source call_id=$effectiveConsultationId');
    AppLogger.d('[CALL ACCEPT TRACE] source=$source call_id=$effectiveConsultationId state=$currentState');

    // Strict Source Authorization Requirement:
    // Only explicit user button taps or native CallKit user answer actions are permitted to invoke accept.
    if (source != 'VOICE_SCREEN_ACCEPT_BUTTON' &&
        source != 'CALLKIT_USER_ACCEPT' &&
        source != 'RESTORE_PENDING_CALL' &&
        source != 'NOTIFICATION_ACCEPT') {
      AppLogger.d('[CALL ACCEPT TRACE][REJECTED] source=$source reason=unauthorized_accept_source call_id=$effectiveConsultationId');
      return;
    }

    // A user tapping Accept dismisses the incoming-call banner immediately.
    FcmService.dismissIncomingCallNotification();

    if (effectiveConsultationId.isEmpty) {
      AppLogger.d('[CALL ACCEPT TRACE][ABORTED] source=$source reason=missing_consultation_id');
      return;
    }

    if (_acceptedConsultationIds.contains(effectiveConsultationId)) {
      AppLogger.d('[CALL ACCEPT TRACE][ABORTED] source=$source reason=already_accepted call_id=$effectiveConsultationId');
      return;
    }

    if (_acceptInProgress) {
      AppLogger.d('[CALL ACCEPT TRACE][ABORTED] source=$source reason=accept_in_progress call_id=$effectiveConsultationId state=$currentState');
      return;
    }

    if (currentState == CallState.connected || currentState == CallState.connecting) {
      AppLogger.d('[CALL ACCEPT TRACE][ABORTED] source=$source reason=already_in_call_state state=$currentState call_id=$effectiveConsultationId');
      return;
    }

    _acceptedConsultationIds.add(effectiveConsultationId);
    _acceptInProgress = true;
    GlobalCallService.stateMachine.transitionTo(CallState.connecting, callId: effectiveConsultationId, consultationId: effectiveConsultationId);

    try {
      final key = 'accept_$effectiveConsultationId';
      if (_isDuplicate(key)) {
        AppLogger.d('[CALL-ACTION-FE] action=ACCEPT event=IDEMPOTENCY_BLOCKED call_id=$effectiveConsultationId state=${GlobalCallService.stateMachine.state}');
        AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_ABORTED] reason=already_processing');
        return;
      }

      final reqId = 'ACCE-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
      AppLogger.d('[CALL-ACCEPT-DIAG] req_id=$reqId source=$source consultation_id=$effectiveConsultationId state=$currentState accept_in_progress=$_acceptInProgress accepted_ids=$_acceptedConsultationIds');
      AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_ACCEPT_ENTER] req_id=$reqId Starting accept action execution');
      RingtoneService.stopRingtone();

      // 1. Non-blocking credentials check / restore attempt
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_AUTH_START] req_id=$reqId Validating stored credentials');
      final isAuthValid = await AuthService.trySilentAuthRestore();
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_AUTH_CHECK] req_id=$reqId result=$isAuthValid');

      // 2. Execute Backend ACCEPT Operation
      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=ACCEPT req_id=$reqId event=BACKEND_REQUEST_START call_id=$effectiveConsultationId');
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_API_START] req_id=$reqId POST /voice-session/accept/');
      int statusCode = await ConsultationApiService().acceptVoiceSessionDetailed(effectiveConsultationId);
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_API_RESPONSE] req_id=$reqId status=$statusCode');
      
      // Handle Status Code Cases (200, 201, 409 = success or already active)
      if (statusCode == 409) {
        AppLogger.d('[CALL-ACCEPT] req_id=$reqId surface=DISPATCHER action=ACCEPT event=BACKEND_REQUEST_SUCCESS call_id=$effectiveConsultationId notice=already_active_409');
        AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_NOTICE] req_id=$reqId Session already accepted or active (409). Proceeding to ongoing VoiceCallScreen.');
      } else if (statusCode != 200 && statusCode != 201) {
        _acceptedConsultationIds.remove(effectiveConsultationId);
        AppLogger.d('[CALL-ACCEPT] req_id=$reqId surface=DISPATCHER action=ACCEPT event=BACKEND_REQUEST_FAILED status=$statusCode call_id=$effectiveConsultationId');
        AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_FAILED] req_id=$reqId ACCEPT request failed with status=$statusCode. Cleanly tearing down call.');
        await GlobalCallService.teardownCall(callId: effectiveConsultationId, consultationId: effectiveConsultationId, reason: CallTerminalReason.authFailure, source: 'accept_failed');
        CallKitService().dismissIncomingCallKitPresentation();
        return;
      }

      AppLogger.d('[CALL_TRACE] CALL_ACCEPTED consultation_id=$effectiveConsultationId status=$statusCode');
      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=ACCEPT event=BACKEND_REQUEST_SUCCESS call_id=$effectiveConsultationId');
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_BACKEND_SUCCESS] Backend ACCEPT confirmed');

      // 3. Broadcast WebSocket signal to remote caller + local event
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_WS_START] Broadcasting call_accepted WS signal');
      await GlobalCallService.broadcastWsSignal(effectiveConsultationId, 'call_accepted');
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_WS_SUCCESS] WS signal dispatched');
      FcmService.dismissIncomingCallNotification();

      GlobalCallService.sendCallEvent({
        'action': 'call_accepted',
        'type': 'call_accepted',
        'consultation_id': effectiveConsultationId,
      });

      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=ACCEPT event=STATE_CONNECTING call_id=$effectiveConsultationId');
      GlobalCallService.stateMachine.transitionTo(CallState.connecting, callId: effectiveConsultationId, consultationId: effectiveConsultationId);

      // 4. Dismiss native notification after backend ACCEPT and WS signaling complete
      if (source == 'CALLKIT_USER_ACCEPT') {
        CallKitService().presentationOperation = CallKitPresentationOperation.dismissingAfterAccept;
        CallKitService().recordDismissalWindow();
      } else {
        CallKitService().dismissIncomingCallKitPresentation(operation: CallKitPresentationOperation.dismissingAfterAccept);
      }

      // 5. Navigate to VoiceCallScreen
      final callerId = GlobalCallService.extractId(extra['caller_id'] ?? extra['sender_id'] ?? extra['caller']);
      final receiverId = GlobalCallService.extractId(extra['receiver_id'] ?? extra['recipient_id'] ?? extra['receiver'] ?? GlobalCallService.currentUserId);
      final callerName = NameFormatter.format((extra['caller_name'] ?? extra['sender_name'] ?? 'Care Provider').toString());
      final receiverName = GlobalCallService.extractPersonName(extra, isSender: false);

      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=ACCEPT event=WEBRTC_INITIALIZATION_START call_id=$effectiveConsultationId');
      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=ACCEPT event=NAVIGATION_START call_id=$effectiveConsultationId');
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_NAVIGATION_START] Navigating to VoiceCallScreen');
      CallNavigationCoordinator.navigateToVoiceCallScreen(
        consultationId: effectiveConsultationId,
        callId: effectiveConsultationId,
        callerName: callerName,
        receiverName: receiverName,
        callerId: callerId,
        receiverId: receiverId,
      );
      AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_ACCEPT_COMPLETE] Accept flow complete');
    } catch (e) {
      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=ACCEPT event=EXCEPTION error_type=${e.runtimeType} call_id=$effectiveConsultationId');
      rethrow;
    } finally {
      _acceptInProgress = false;
    }
  }

  static Future<void> dispatchDecline(String callId, String consultationId) async {
    final effectiveConsultationId = (consultationId.isNotEmpty && consultationId != 'null')
        ? consultationId
        : (callId.isNotEmpty && callId != 'null' ? callId : (GlobalCallService.activeConsultationId ?? ''));

    AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=DECLINE event=ENTERED call_id=$effectiveConsultationId');

    if (effectiveConsultationId.isEmpty) {
      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=DECLINE event=EARLY_RETURN reason=missing_consultation_id call_id=unknown');
      AppLogger.d('[CALL][UNKNOWN][DECLINE_ABORTED] reason=missing_consultation_id');
      return;
    }

    if (GlobalCallService.stateMachine.state == CallState.connecting || GlobalCallService.stateMachine.state == CallState.connected) {
      AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=DECLINE event=EARLY_RETURN reason=already_accepted call_id=$effectiveConsultationId state=${GlobalCallService.stateMachine.state}');
      AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_ABORTED] reason=already_accepted');
      return;
    }

    final key = 'decline_$effectiveConsultationId';
    if (_isDuplicate(key)) {
      AppLogger.d('[CALL-ACTION-FE] action=DECLINE event=IDEMPOTENCY_BLOCKED call_id=$effectiveConsultationId state=${GlobalCallService.stateMachine.state}');
      AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_ABORTED] reason=already_processing');
      return;
    }

    AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_DECLINE_ENTER] Starting decline action execution');
    RingtoneService.stopRingtone();

    AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=DECLINE event=BACKEND_REQUEST_START call_id=$effectiveConsultationId');
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_API_START] POST /voice-session/decline/');
    final ok = await ConsultationApiService().declineVoiceSession(effectiveConsultationId);
    AppLogger.d('[CALL-ACTION-FE] surface=DISPATCHER action=DECLINE event=BACKEND_REQUEST_SUCCESS call_id=$effectiveConsultationId');
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_API_RESPONSE] status=${ok ? 200 : 500}');
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_BACKEND_SUCCESS] Backend DECLINE confirmed');
    FcmService.dismissIncomingCallNotification();

    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_WS_START] Broadcasting call_declined WS signal');
    await GlobalCallService.broadcastWsSignal(effectiveConsultationId, 'call_declined');
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_WS_SUCCESS] WS signal dispatched');

    await GlobalCallService.teardownCall(
      callId: effectiveConsultationId,
      consultationId: effectiveConsultationId,
      reason: CallTerminalReason.decline,
      source: 'local_decline',
    );

    CallKitService().dismissIncomingCallKitPresentation();
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_COMPLETE] Decline flow complete');
  }

  static Future<void> dispatchEnd(String callId, String consultationId) async {
    final effectiveConsultationId = (consultationId.isNotEmpty && consultationId != 'null')
        ? consultationId
        : (callId.isNotEmpty && callId != 'null' ? callId : (GlobalCallService.activeConsultationId ?? ''));

    if (effectiveConsultationId.isEmpty) {
      AppLogger.d('[CALL][UNKNOWN][END_ABORTED] reason=missing_consultation_id');
      return;
    }

    final key = 'end_$effectiveConsultationId';
    if (_isDuplicate(key)) {
      AppLogger.d('[CALL][$effectiveConsultationId][END_ABORTED] reason=already_processing');
      return;
    }

    AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_END_ENTER] Starting end action execution');
    RingtoneService.stopRingtone();

    AppLogger.d('[CALL][$effectiveConsultationId][END_API_START] POST /voice-session/end/');
    final ok = await ConsultationApiService().endVoiceSession(effectiveConsultationId);
    AppLogger.d('[CALL][$effectiveConsultationId][END_API_RESPONSE] status=${ok ? 200 : 500}');
    AppLogger.d('[CALL][$effectiveConsultationId][END_BACKEND_SUCCESS] Backend END confirmed');

    AppLogger.d('[CALL][$effectiveConsultationId][END_WS_START] Broadcasting call_ended WS signal');
    await GlobalCallService.broadcastWsSignal(effectiveConsultationId, 'call_ended');
    AppLogger.d('[CALL][$effectiveConsultationId][END_WS_SUCCESS] WS signal dispatched');

    await GlobalCallService.teardownCall(
      callId: effectiveConsultationId,
      consultationId: effectiveConsultationId,
      reason: CallTerminalReason.hangup,
      source: 'local_hangup',
    );

    CallKitService().dismissIncomingCallKitPresentation();
    AppLogger.d('[CALL][$effectiveConsultationId][END_COMPLETE] End call flow complete');
  }
}

class PresentationCoordinator {
  static Future<void> present(IncomingCallEvent event) async {
    if (GlobalCallService.isTerminalCallRecentlySeen(event.callId)) {
      AppLogger.d('[PRESENTATION] Suppressing incoming call offer for recently ended callId: ${event.callId}');
      return;
    }
    AppLogger.d('[PRESENTATION] Single Owner -> Presenting VoiceCallScreen (Image 1)');
    GlobalCallService.showIncomingCallModal(
      event.rawData,
      defaultAppointmentId: event.consultationId,
      defaultConsultationId: event.consultationId,
    );
  }
}

class CallStateMachine {
  CallState _state = CallState.idle;
  String? _activeCallId;
  String? _activeConsultationId;

  CallState get state => _state;
  String? get activeCallId => _activeCallId;
  String? get activeConsultationId => _activeConsultationId;

  final StreamController<CallState> _stateController = StreamController<CallState>.broadcast();
  Stream<CallState> get onStateChanged => _stateController.stream;

  bool transitionTo(CallState newState, {String? callId, String? consultationId}) {
    if (_state == newState) return false;

    bool isValid = false;
    switch (_state) {
      case CallState.idle:
        if (newState == CallState.incomingRinging ||
            newState == CallState.outgoingRinging ||
            newState == CallState.connecting) {
          isValid = true;
        }
        break;
      case CallState.incomingRinging:
        if (newState == CallState.connecting ||
            newState == CallState.declined ||
            newState == CallState.cancelled ||
            newState == CallState.missed ||
            newState == CallState.ended ||
            newState == CallState.idle) {
          isValid = true;
        }
        break;
      case CallState.outgoingRinging:
        if (newState == CallState.connecting ||
            newState == CallState.cancelled ||
            newState == CallState.declined ||
            newState == CallState.ended ||
            newState == CallState.idle) {
          isValid = true;
        }
        break;
      case CallState.connecting:
        if (newState == CallState.connected ||
            newState == CallState.ended ||
            newState == CallState.cancelled ||
            newState == CallState.declined ||
            newState == CallState.idle) {
          isValid = true;
        }
        break;
      case CallState.connected:
        if (newState == CallState.ended || newState == CallState.idle) {
          isValid = true;
        }
        break;
      case CallState.declined:
      case CallState.cancelled:
      case CallState.missed:
      case CallState.ended:
        if (newState == CallState.idle) {
          isValid = true;
        }
        break;
    }

    if (!isValid) {
      AppLogger.d('[CALL STATE MACHINE] REJECTED invalid state transition from $_state to $newState');
      return false;
    }

    final effectiveId = consultationId ?? callId ?? _activeConsultationId ?? 'unknown';
    AppLogger.d('[CALL][$effectiveId][STATE] $newState');
    AppLogger.d('[CALL STATE MACHINE] Transition: $_state -> $newState (callId: $callId, consultationId: $consultationId)');
    _state = newState;
    if (callId != null) _activeCallId = callId;
    if (consultationId != null) _activeConsultationId = consultationId;

    if (newState == CallState.connected) {
      AppLogger.d('[CALL_TRACE] CALL_STATE_ACTIVE call_id=${callId ?? _activeCallId} consultation_id=${consultationId ?? _activeConsultationId}');
    }

    if (newState == CallState.idle) {
      _activeCallId = null;
      _activeConsultationId = null;
    }

    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
    return true;
  }

  void reset() {
    _state = CallState.idle;
    _activeCallId = null;
    _activeConsultationId = null;
    if (!_stateController.isClosed) {
      _stateController.add(CallState.idle);
    }
  }
}

class GlobalCallService {
  static final CallStateMachine stateMachine = CallStateMachine();
  static final Set<String> _processedCallIds = {};
  static final Map<String, int> _terminalCallTtlCache = {};
  static const int _terminalTtlMs = 60000;
  static WebSocketChannel? _userCallChannel;
  static final Map<String, WebSocketChannel> _appointmentChannels = {};
  static Timer? _heartbeatTimer;
  static bool isRingingShown = false;
  static bool isCallActive = false;
  static String? currentUserId;

  static Future<String?> syncCurrentUserId({String? overrideId}) async {
    if (overrideId != null && overrideId.isNotEmpty && overrideId != 'null') {
      currentUserId = overrideId;
      AppLogger.d('[GLOBAL_CALL_USER_ID_SET] currentUserId set to $currentUserId');
      return currentUserId;
    }
    final authId = await getAuthenticatedUserId();
    if (authId != null && authId.isNotEmpty) {
      currentUserId = authId;
      AppLogger.d('[GLOBAL_CALL_USER_ID_SET] currentUserId synced to $currentUserId');
    } else {
      AppLogger.d('[GLOBAL_CALL_USER_ID_SET] Could not determine authenticated user ID');
    }
    return currentUserId;
  }

  static final StreamController<Map<String, dynamic>> _callEventController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onCallEvent => _callEventController.stream;

  static bool isTerminalCallRecentlySeen(String id) {
    if (id.isEmpty || id == 'null') return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ts = _terminalCallTtlCache[id];
    if (ts != null && (now - ts) < _terminalTtlMs) {
      return true;
    }
    return false;
  }

  static Future<void> teardownCall({
    required String callId,
    required String consultationId,
    required CallTerminalReason reason,
    String source = 'unknown',
  }) async {
    final effectiveConsultationId = (consultationId.isNotEmpty && consultationId != 'null')
        ? consultationId
        : (callId.isNotEmpty && callId != 'null' ? callId : (stateMachine.activeConsultationId ?? ''));
    final effectiveCallId = (callId.isNotEmpty && callId != 'null') ? callId : effectiveConsultationId;
    final displayId = effectiveConsultationId.isNotEmpty ? effectiveConsultationId : effectiveCallId;

    AppLogger.d('[CALL-LIFECYCLE] ENDING source=$source reason=$reason call_id=$displayId');
    AppLogger.d('[CALL][consultation=$effectiveConsultationId][session=$effectiveCallId][TERMINAL_EVENT] source=$source reason=$reason');

    if (isTerminalCallRecentlySeen(effectiveConsultationId) || isTerminalCallRecentlySeen(effectiveCallId)) {
      AppLogger.d('[CALL-LIFECYCLE] ENDED (already_terminal) source=$source call_id=$displayId');
      AppLogger.d('[CALL][$displayId][TERMINAL_IGNORED] source=$source reason=already_terminal');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (effectiveConsultationId.isNotEmpty && effectiveConsultationId != 'null') {
      _terminalCallTtlCache[effectiveConsultationId] = now;
    }
    if (effectiveCallId.isNotEmpty && effectiveCallId != 'null') {
      _terminalCallTtlCache[effectiveCallId] = now;
    }

    AppLogger.d('[CALL][$displayId][TERMINAL_ACCEPTED] source=$source reason=$reason');
    AppLogger.d('[TEARDOWN] Executing teardown for call $displayId (source: $source, reason: $reason)');

    RingtoneService.stopRingtone();
    FcmService.dismissIncomingCallNotification();
    stateMachine.transitionTo(CallState.ended, callId: effectiveCallId, consultationId: effectiveConsultationId);

    // Emit ONE normalized local terminal event for subscribers (like VoiceCallScreen)
    sendCallEvent({
      'action': 'call_ended',
      'type': 'call_ended',
      'consultation_id': effectiveConsultationId,
      'reason': reason.toString(),
      'source': source,
    });

    try {
      CallKitService().dismissIncomingCallKitPresentation();
    } catch (_) {}

    isCallActive = false;
    isRingingShown = false;

    await Future.delayed(const Duration(milliseconds: 300));
    stateMachine.transitionTo(CallState.idle);

    AppLogger.d('[CALL-LIFECYCLE] ENDED complete call_id=$displayId source=$source');

    final cleanNow = DateTime.now().millisecondsSinceEpoch;
    _terminalCallTtlCache.removeWhere((id, timestamp) => (cleanNow - timestamp) > _terminalTtlMs);
    if (effectiveConsultationId.isNotEmpty) {
      _processedCallIds.remove(effectiveConsultationId);
      IncomingCallActionDispatcher._acceptedConsultationIds.remove(effectiveConsultationId);
    }
    if (effectiveCallId.isNotEmpty) {
      _processedCallIds.remove(effectiveCallId);
      IncomingCallActionDispatcher._acceptedConsultationIds.remove(effectiveCallId);
    }
  }

  static String? get activeConsultationId => stateMachine.activeConsultationId;

  static void sendCallEvent(Map<String, dynamic> event) {
    final typeLower = (event['type'] ?? event['action'] ?? event['event'] ?? '').toString().toLowerCase();
    if (typeLower.contains('accepted')) {
      final callId = (event['call_id'] ?? event['consultation_id'] ?? '').toString();
      AppLogger.d('[WEBRTC_TRACE_02_CALL_ACCEPTED_EVENT_DISPATCHED] call_id=$callId');
    }
    if (!_callEventController.isClosed) {
      _callEventController.add(event);
    }
  }

  static Future<void> broadcastWsSignal(String consultationId, String action, {Map<String, dynamic>? extraPayload}) async {
    try {
      final token = await _getSanitizedToken();
      if (token.isEmpty || consultationId.isEmpty || consultationId == 'null') return;

      final currentAuthUserId = currentUserId ?? await getAuthenticatedUserId() ?? 'unknown';

      final Map<String, dynamic> payload = {
        'action': action,
        'type': action,
        'consultation_id': consultationId,
        'sender_id': currentAuthUserId,
      };
      if (extraPayload != null && extraPayload.isNotEmpty) {
        payload.addAll(extraPayload);
      }

      final effectiveCallId = (payload['call_id'] ?? consultationId).toString();
      final recipientId = extractId(payload['receiver_id'] ?? payload['recipient_id'] ?? payload['recipient'] ?? payload['receiver']);
      final isWsConnected = GlobalCallWebSocketManager.instance.state == GlobalWsState.connected;

      if (action == 'webrtc_offer') {
        AppLogger.d('[WEBRTC_TRACE_11_OFFER_SEND_ATTEMPT] consultation_id=$consultationId call_id=$effectiveCallId action=$action sender_id=$currentAuthUserId recipient_id=$recipientId ws_connected=$isWsConnected');
      } else if (action == 'webrtc_answer') {
        AppLogger.d('[WEBRTC_TRACE_24_ANSWER_SENT] consultation_id=$consultationId call_id=$effectiveCallId action=$action sender_id=$currentAuthUserId recipient_id=$recipientId ws_connected=$isWsConnected');
      } else if (action == 'webrtc_ice_candidate') {
        AppLogger.d('[WEBRTC_TRACE_31_LOCAL_ICE_SENT] consultation_id=$consultationId call_id=$effectiveCallId sender_id=$currentAuthUserId recipient_id=$recipientId ws_connected=$isWsConnected');
      } else {
        AppLogger.d('[WS_SIGNAL_OUT] action=$action consultation_id=$consultationId call_id=$effectiveCallId sender_id=$currentAuthUserId recipient_id=$recipientId ws_connected=$isWsConnected');
      }

      // Ensure global WS is connected if it dropped
      if (!isWsConnected) {
        AppLogger.d('[WS] Global WS disconnected when broadcasting $action. Reconnecting...');
        await GlobalCallWebSocketManager.instance.connect(force: true);
      }

      // 1. Primary: Persistent Global User Calls WebSocket
      final sentViaGlobalWs = GlobalCallWebSocketManager.instance.send(payload);
      if (sentViaGlobalWs) {
        if (action == 'webrtc_offer') {
          AppLogger.d('[WEBRTC_TRACE_12_OFFER_SEND_COMPLETED] consultation_id=$consultationId call_id=$effectiveCallId action=$action sender_id=$currentAuthUserId recipient_id=$recipientId');
        }
        AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Signal $action delivered via primary user-calls WS socket');
        return;
      }

      // 2. Retry send via primary WebSocket after short delay
      await Future.delayed(const Duration(milliseconds: 300));
      final retrySent = GlobalCallWebSocketManager.instance.send(payload);
      if (retrySent) {
        if (action == 'webrtc_offer') {
          AppLogger.d('[WEBRTC_TRACE_12_OFFER_SEND_COMPLETED] consultation_id=$consultationId call_id=$effectiveCallId action=$action sender_id=$currentAuthUserId recipient_id=$recipientId (retry)');
        }
        AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Signal $action delivered via primary WS retry');
        return;
      }

      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=broadcastWsSignal consultation_id=$consultationId call_id=$effectiveCallId sender_id=$currentAuthUserId recipient_id=$recipientId error=Failed to send $action over WS');
    } catch (e) {
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=broadcastWsSignal call_id=$consultationId error=$e');
    }
  }

  static String extractId(dynamic val) {
    if (val == null) return '';
    if (val is Map) return (val['id'] ?? val['user_id'] ?? val['pk'] ?? val['uid'] ?? '').toString();
    return val.toString();
  }

  static String extractPersonName(Map<String, dynamic> data, {bool isSender = false}) {
    final topName = isSender
        ? (data['sender_name'] ?? data['sender_full_name'] ?? data['caller_name'] ?? data['patient_name'] ?? data['user_full_name'])
        : (data['receiver_name'] ?? data['receiver_full_name'] ?? data['recipient_name'] ?? data['midwife_name'] ?? data['midwife_full_name']);
    if (topName != null && topName.toString().trim().isNotEmpty && topName.toString() != 'null') {
      return NameFormatter.format(topName.toString());
    }
    final keysToTry = isSender
        ? ['sender', 'caller', 'patient_detail', 'patient', 'user_detail', 'user']
        : ['receiver', 'recipient', 'midwife_detail', 'midwife_profile', 'midwife'];
    for (final key in keysToTry) {
      if (data[key] != null) {
        final res = NameFormatter.format(data[key].toString());
        if (res.isNotEmpty && res.toLowerCase() != 'recipient') return res;
      }
    }
    return isSender ? 'Caller' : 'Care Provider';
  }

  static CallSignalType parseSignalType(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['action'] ?? data['event'] ?? '').toString().toLowerCase();
    if (type.contains('offer')) return CallSignalType.callOffer;
    if (type.contains('accept')) return CallSignalType.callAccepted;
    if (type.contains('decline') || type.contains('reject')) return CallSignalType.callDeclined;
    if (type.contains('end') || type.contains('hangup') || type.contains('cancel')) return CallSignalType.callEnded;
    if (type.contains('ping') || type.contains('pong')) return CallSignalType.pingPong;
    return CallSignalType.unknown;
  }

  static String? _getUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decodedBytes = base64Url.decode(payload);
      final decodedMap = jsonDecode(utf8.decode(decodedBytes));
      if (decodedMap is Map) {
        final id = decodedMap['user_id'] ?? decodedMap['id'] ?? decodedMap['user']?['id'] ?? decodedMap['sub'];
        return id?.toString();
      }
    } catch (e) {
      debugPrint('Error decoding JWT user_id: $e');
    }
    return null;
  }

  static Future<String> _getSanitizedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? prefs.getString('access') ?? '';
    var token = rawToken.trim();
    if (token.startsWith('Bearer ')) token = token.substring(7).trim();
    return token.replaceAll('"', '').replaceAll("'", '').trim();
  }

  static Future<String?> getAuthenticatedUserId() async {
    final token = await _getSanitizedToken();
    return _getUserIdFromJwt(token);
  }

  static Future<bool> handleIncomingCallEvent(IncomingCallEvent event) async {
    final effectiveId = event.callId.isNotEmpty ? event.callId : event.consultationId;
    AppLogger.d('[CALL FLOW V2] incoming event handling call_id=${event.callId} consultation_id=${event.consultationId}');

    // 1. Check call deduplication, terminal state, accepted state, and state machine.
    //    Dedup is CALL-SCOPED: keyed only on this call's id, never on
    //    consultationId. A consultation can host multiple sequential calls
    //    (retry after a missed/hung-up call), so keying on consultationId
    //    would permanently block every subsequent call for it.
    if (_processedCallIds.contains(effectiveId) ||
        isTerminalCallRecentlySeen(effectiveId) ||
        IncomingCallActionDispatcher.hasBeenAccepted(effectiveId) ||
        stateMachine.state != CallState.idle) {
      AppLogger.d('[CALL][DEDUP] Duplicate, terminal, or active call event ignored for callId: $effectiveId (state: ${stateMachine.state})');
      return false;
    }
    _processedCallIds.add(effectiveId);

    // Release the dedup marker on any early-return path so a dropped attempt
    // never poisons future calls for this session.
    void releaseDedup() {
      _processedCallIds.remove(effectiveId);
    }

    // 2. Self-call prevention
    final myId = currentUserId ?? await getAuthenticatedUserId();
    if (myId != null && myId.isNotEmpty && event.callerId.isNotEmpty && myId == event.callerId) {
      AppLogger.d('[CALL][SELF_CALL] Ignored self-initiated call event for callerId: ${event.callerId}');
      releaseDedup();
      return false;
    }

    // 3. Verify backend call validity
    final isActiveOnBackend = await ConsultationApiService().verifyVoiceSessionActive(event.consultationId);
    if (!isActiveOnBackend) {
      AppLogger.d('[CALL][VALIDITY] Call session is no longer active on backend for consultationId: ${event.consultationId}');
      releaseDedup();
      return false;
    }

    // 4. Transition State Machine
    final transitioned = stateMachine.transitionTo(
      CallState.incomingRinging,
      callId: event.callId,
      consultationId: event.consultationId,
    );
    if (!transitioned) {
      releaseDedup();
      return false;
    }

    // 5. Play Ringtone
    RingtoneService.playIncomingRingtone();

    // 6. Heads-up push notification: surface an Android status-bar banner (call
    //    category + full-screen intent) alongside the in-app caller UI so the
    //    device visibly rings even if the user is on another screen/another app.
    try {
      FcmService.showIncomingCallNotification(
        title: event.callerName,
        body: 'Incoming voice call',
        data: event.rawData,
      );
    } catch (_) {}

    // 7. Navigate directly to VoiceCallScreen (The single custom full screen caller UI)
    final receiverId = extractId(event.rawData['receiver_id'] ?? event.rawData['recipient_id'] ?? event.rawData['receiver'] ?? currentUserId);
    final receiverName = extractPersonName(event.rawData, isSender: false);

    AppLogger.d('[CALL FLOW V2] opening VoiceCallScreen call_id=${event.callId} consultation_id=${event.consultationId}');
    CallNavigationCoordinator.navigateToVoiceCallScreen(
      consultationId: event.consultationId,
      callId: event.callId,
      callerName: event.callerName,
      receiverName: receiverName,
      callerId: event.callerId,
      receiverId: receiverId,
    );

    return true;
  }

  static void showIncomingCallModal(
    Map<String, dynamic> data,
    {String defaultAppointmentId = '',
    String defaultConsultationId = ''}
  ) {
    final event = IncomingCallEvent.fromMap(
      data,
      defaultAppointmentId: defaultAppointmentId,
      defaultConsultationId: defaultConsultationId,
    );
    handleIncomingCallEvent(event);
  }

  static Future<void> initUserCallListener({bool force = false}) async {
    await syncCurrentUserId();
    await GlobalCallWebSocketManager.instance.connect(force: force);
  }

  static Future<void> initMultiple(List<String> appointmentIds) async {
    await initUserCallListener();
  }

  static Future<void> init(String appointmentId) async {
    await initUserCallListener();
  }

  static void declineCall(String consultationId) async {
    try {
      debugPrint('[DECLINE SENT] Callee tapped decline for consultation: $consultationId');
      
      RingtoneService.stopRingtone();
      FcmService.dismissIncomingCallNotification();
      isRingingShown = false;
      stateMachine.transitionTo(CallState.declined);
      stateMachine.transitionTo(CallState.idle);

      try {
        FlutterCallkitIncoming.endAllCalls();
      } catch (_) {}

      try {
        ConsultationApiService().declineVoiceSession(consultationId);
      } catch (_) {}

      sendCallEvent({
        'type': 'call_declined',
        'action': 'call_declined',
        'consultation_id': consultationId,
      });

      final token = await _getSanitizedToken();
      if (token.isEmpty || consultationId.isEmpty || consultationId == 'null') return;

      if (_appointmentChannels.containsKey(consultationId)) {
        _appointmentChannels[consultationId]?.sink.add(jsonEncode({
          'action': 'call_declined',
          'type': 'call_declined',
          'consultation_id': consultationId,
        }));
        debugPrint('[DECLINE SENT] Sent via existing appointment channel for consultation: $consultationId');
        return;
      }

      final wsUrlString = '${ApiConfig.wsUrl}/consultation/$consultationId/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      final channel = WebSocketChannel.connect(wsUrl);
      
      await Future.delayed(const Duration(milliseconds: 250));
      channel.sink.add(jsonEncode({
        'action': 'call_declined',
        'type': 'call_declined',
        'consultation_id': consultationId,
      }));
      debugPrint('[DECLINE SENT] Sent via temporary WebSocket channel for consultation: $consultationId');
      await Future.delayed(const Duration(milliseconds: 300));
      channel.sink.close();
    } catch (e) {
      debugPrint('Failed to send declineCall WS frame: $e');
    }
  }

  static void dispose() {
    _heartbeatTimer?.cancel();
    RingtoneService.stopRingtone();
    _userCallChannel?.sink.close();
    for (var channel in _appointmentChannels.values) {
      channel.sink.close();
    }
    _appointmentChannels.clear();
    isRingingShown = false;
    isCallActive = false;
  }
}

class _IncomingCallOverlayCardWidget extends StatefulWidget {
  final String callerName;
  final VoidCallback onTapCard;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  const _IncomingCallOverlayCardWidget({
    required this.callerName,
    required this.onTapCard,
    required this.onDecline,
    required this.onAccept,
  });

  @override
  State<_IncomingCallOverlayCardWidget> createState() => _IncomingCallOverlayCardWidgetState();
}

class _IncomingCallOverlayCardWidgetState extends State<_IncomingCallOverlayCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'DM';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(widget.callerName);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28, left: 16, right: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTapCard,
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.black12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Double-Ring Avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Pulsing Ring
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF315E26).withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        // Inner Border Ring
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF315E26).withValues(alpha: 0.3),
                              width: 2.5,
                            ),
                          ),
                        ),
                        // Main Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF315E26),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Caller Name (Strongest Text Element)
                Text(
                  widget.callerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),

                SizedBox(height: 4),

                // Status Line
                Text(
                  AppLocalizations.of(context)!.incomingVoiceCall,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Security Badge (Understated Shield Badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 13, color: Color(0xFF315E26)),
                      SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.encryptedCall,
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: widget.onDecline,
                            splashColor: Colors.white24,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEF4444),
                              ),
                              child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.decline,
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Accept Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: widget.onAccept,
                            splashColor: Colors.white24,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF315E26),
                              ),
                              child: const Icon(Icons.call, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.accept,
                          style: TextStyle(
                            color: Color(0xFF315E26),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
