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
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/callkit_service.dart';
import 'package:cagh_frontend/core/services/global_call_websocket_manager.dart';

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

      AppLogger.d('[PENDING ACTION] Replaying queued $typeStr action for call $callId');
      if (typeStr == 'accept') {
        await IncomingCallActionDispatcher.dispatchAccept(callId, consultationId, extra);
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
    });
  }
}

class IncomingCallActionDispatcher {
  static final Map<String, int> _actionTimestamps = {};
  static const int _dedupTtlMs = 10000;

  static bool _isDuplicate(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _actionTimestamps[key];
    if (last != null && (now - last) < _dedupTtlMs) {
      return true;
    }
    _actionTimestamps[key] = now;
    return false;
  }

  static bool _acceptInProgress = false;

  static Future<void> dispatchAccept(String callId, String consultationId, Map<String, dynamic> extra) async {
    final effectiveConsultationId = (consultationId.isNotEmpty && consultationId != 'null')
        ? consultationId
        : (callId.isNotEmpty && callId != 'null' ? callId : (GlobalCallService.activeConsultationId ?? ''));

    if (effectiveConsultationId.isEmpty) {
      AppLogger.d('[CALL][UNKNOWN][ACCEPT_ABORTED] reason=missing_consultation_id');
      return;
    }

    if (_acceptInProgress ||
        GlobalCallService.stateMachine.state == CallState.connecting ||
        GlobalCallService.stateMachine.state == CallState.connected) {
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_ABORTED] reason=already_processing_or_connected');
      return;
    }
    _acceptInProgress = true;

    final key = 'accept_$effectiveConsultationId';
    if (_isDuplicate(key)) {
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_ABORTED] reason=already_processing');
      _acceptInProgress = false;
      return;
    }

    AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_ACCEPT_ENTER] Starting accept action execution');
    RingtoneService.stopRingtone();

    // 1. Non-blocking credentials check / restore attempt
    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_AUTH_START] Validating stored credentials');
    final isAuthValid = await AuthService.trySilentAuthRestore();
    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_AUTH_CHECK] result=$isAuthValid');

    // 2. Execute Backend ACCEPT Operation
    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_API_START] POST /voice-session/accept/');
    int statusCode = await ConsultationApiService().acceptVoiceSessionDetailed(effectiveConsultationId);
    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_API_RESPONSE] status=$statusCode');
    
    // HTTP 401 Unauthorized -> Refresh token once & retry ACCEPT once
    if (statusCode == 401) {
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_API_START] Retrying after auth refresh');
      final refreshed = await AuthService.trySilentAuthRestore();
      if (refreshed) {
        statusCode = await ConsultationApiService().acceptVoiceSessionDetailed(effectiveConsultationId);
        AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_API_RESPONSE] status=$statusCode');
      }
    }

    // Handle Status Code Cases (200, 201, 409 = success or already active)
    if (statusCode == 409) {
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_NOTICE] Session already accepted or active (409). Proceeding to ongoing VoiceCallScreen.');
    } else if (statusCode == 401) {
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_ABORTED] reason=auth_failure_401');
      _acceptInProgress = false;
      await GlobalCallService.teardownCall(callId: effectiveConsultationId, consultationId: effectiveConsultationId, reason: CallTerminalReason.authFailure);
      CallKitService().dismissIncomingCallKitPresentation();
      return;
    } else if (statusCode != 200 && statusCode != 201) {
      AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_ABORTED] reason=api_failure_$statusCode');
      _acceptInProgress = false;
      await GlobalCallService.teardownCall(callId: effectiveConsultationId, consultationId: effectiveConsultationId, reason: CallTerminalReason.authFailure);
      CallKitService().dismissIncomingCallKitPresentation();
      return;
    }

    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_BACKEND_SUCCESS] Backend ACCEPT confirmed');

    // 3. Broadcast WebSocket signal to remote caller + local event
    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_WS_START] Broadcasting call_accepted WS signal');
    await GlobalCallService.broadcastWsSignal(effectiveConsultationId, 'call_accepted');
    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_WS_SUCCESS] WS signal dispatched');

    GlobalCallService.sendCallEvent({
      'action': 'call_accepted',
      'type': 'call_accepted',
      'consultation_id': effectiveConsultationId,
    });
    GlobalCallService.stateMachine.transitionTo(CallState.connecting, callId: effectiveConsultationId, consultationId: effectiveConsultationId);

    // 4. Dismiss native notification after backend ACCEPT and WS signaling complete
    CallKitService().dismissIncomingCallKitPresentation();

    // 5. Navigate to VoiceCallScreen
    final callerId = GlobalCallService.extractId(extra['caller_id'] ?? extra['sender_id'] ?? extra['caller']);
    final receiverId = GlobalCallService.extractId(extra['receiver_id'] ?? extra['recipient_id'] ?? extra['receiver']);
    final callerName = NameFormatter.format((extra['caller_name'] ?? extra['sender_name'] ?? 'Care Provider').toString());
    final receiverName = GlobalCallService.extractPersonName(extra, isSender: false);

    AppLogger.d('[CALL][$effectiveConsultationId][ACCEPT_NAVIGATION_START] Navigating to VoiceCallScreen');
    CallNavigationCoordinator.navigateToVoiceCallScreen(
      consultationId: effectiveConsultationId,
      callId: effectiveConsultationId,
      callerName: callerName,
      receiverName: receiverName,
      callerId: callerId,
      receiverId: receiverId,
    );
    _acceptInProgress = false;
    AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_ACCEPT_COMPLETE] Accept flow complete');
  }

  static Future<void> dispatchDecline(String callId, String consultationId) async {
    final effectiveConsultationId = (consultationId.isNotEmpty && consultationId != 'null')
        ? consultationId
        : (callId.isNotEmpty && callId != 'null' ? callId : (GlobalCallService.activeConsultationId ?? ''));

    if (effectiveConsultationId.isEmpty) {
      AppLogger.d('[CALL][UNKNOWN][DECLINE_ABORTED] reason=missing_consultation_id');
      return;
    }

    final key = 'decline_$effectiveConsultationId';
    if (_isDuplicate(key)) {
      AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_ABORTED] reason=already_processing');
      return;
    }

    AppLogger.d('[CALL][$effectiveConsultationId][DISPATCH_DECLINE_ENTER] Starting decline action execution');
    RingtoneService.stopRingtone();

    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_API_START] POST /voice-session/decline/');
    final ok = await ConsultationApiService().declineVoiceSession(effectiveConsultationId);
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_API_RESPONSE] status=${ok ? 200 : 500}');
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_BACKEND_SUCCESS] Backend DECLINE confirmed');

    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_WS_START] Broadcasting call_declined WS signal');
    await GlobalCallService.broadcastWsSignal(effectiveConsultationId, 'call_declined');
    AppLogger.d('[CALL][$effectiveConsultationId][DECLINE_WS_SUCCESS] WS signal dispatched');

    await GlobalCallService.teardownCall(
      callId: effectiveConsultationId,
      consultationId: effectiveConsultationId,
      reason: CallTerminalReason.decline,
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
    final isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final context = globalNavigatorKey.currentContext;

    if (isForeground && context != null) {
      AppLogger.d('[PRESENTATION] Single Owner -> Flutter Canonical Bottom-Sheet Overlay');
      GlobalCallService.showIncomingCallModal(event.rawData, event.consultationId);
    } else {
      AppLogger.d('[PRESENTATION] Single Owner -> Android CallKit System Notification with Full-Screen Intent');
      await CallKitService().showCallkitIncoming(
        consultationId: event.consultationId,
        name: event.callerName,
        extra: event.rawData,
      );
    }
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
        if (newState == CallState.incomingRinging || newState == CallState.outgoingRinging) {
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

    AppLogger.d('[CALL STATE MACHINE] Transition: $_state -> $newState (callId: $callId, consultationId: $consultationId)');
    _state = newState;
    if (callId != null) _activeCallId = callId;
    if (consultationId != null) _activeConsultationId = consultationId;

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
  static bool get _isRingingShown => isRingingShown;
  static set _isRingingShown(bool v) => isRingingShown = v;
  static bool isCallActive = false;
  static String? currentUserId;

  static final StreamController<Map<String, dynamic>> _callEventController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onCallEvent => _callEventController.stream;

  static Future<void> teardownCall({
    required String callId,
    required String consultationId,
    required CallTerminalReason reason,
  }) async {
    AppLogger.d('[TEARDOWN] Executing teardown for call $callId (reason: $reason)');
    _terminalCallTtlCache[callId] = DateTime.now().millisecondsSinceEpoch;

    RingtoneService.stopRingtone();
    stateMachine.transitionTo(CallState.ended, callId: callId, consultationId: consultationId);

    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}

    isCallActive = false;
    isRingingShown = false;

    await Future.delayed(const Duration(milliseconds: 300));
    stateMachine.transitionTo(CallState.idle);

    final now = DateTime.now().millisecondsSinceEpoch;
    _terminalCallTtlCache.removeWhere((id, timestamp) => (now - timestamp) > _terminalTtlMs);
    _processedCallIds.remove(callId);
  }

  static bool isTerminalCallRecentlySeen(String callId) {
    if (callId.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ts = _terminalCallTtlCache[callId];
    if (ts != null && (now - ts) < _terminalTtlMs) {
      return true;
    }
    return false;
  }

  static String? get activeConsultationId => stateMachine.activeConsultationId;

  static void sendCallEvent(Map<String, dynamic> event) {
    if (!_callEventController.isClosed) {
      _callEventController.add(event);
    }
  }

  static Future<void> broadcastWsSignal(String consultationId, String action, {Map<String, dynamic>? extraPayload}) async {
    try {
      final token = await _getSanitizedToken();
      if (token.isEmpty || consultationId.isEmpty || consultationId == 'null') return;

      final Map<String, dynamic> payload = {
        'action': action,
        'type': action,
        'consultation_id': consultationId,
      };
      if (extraPayload != null && extraPayload.isNotEmpty) {
        payload.addAll(extraPayload);
      }

      AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Broadcasting signal: $action');

      // 1. Primary: Persistent Global User Calls WebSocket
      final sentViaGlobalWs = GlobalCallWebSocketManager.instance.send(payload);
      if (sentViaGlobalWs) {
        AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Signal $action delivered via primary user-calls WS socket');
        return;
      }

      // 2. Fallback: Active cached appointment channel
      if (_appointmentChannels.containsKey(consultationId)) {
        try {
          _appointmentChannels[consultationId]?.sink.add(jsonEncode(payload));
          AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Signal $action delivered via active appointment channel');
          return;
        } catch (e) {
          AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Active channel send notice: $e');
        }
      }

      // 3. Fallback: Connect temporary room socket only if primary sockets are disconnected
      final wsUrlString = '${ApiConfig.wsUrl}/consultation/$consultationId/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      final channel = WebSocketChannel.connect(wsUrl);
      await Future.delayed(const Duration(milliseconds: 200));
      channel.sink.add(jsonEncode(payload));
      await Future.delayed(const Duration(milliseconds: 300));
      channel.sink.close();
      AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Delivered $action to fallback consultation room WS');
    } catch (e, s) {
      AppLogger.d('[CALL][$consultationId][WS_SIGNAL] Error sending WS signal $action: $e\n$s');
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
    // 1. Check call deduplication and state machine
    if (_processedCallIds.contains(event.callId) || stateMachine.state != CallState.idle) {
      AppLogger.d('[CALL][DEDUP] Duplicate or active call event ignored for callId: ${event.callId} (state: ${stateMachine.state})');
      return false;
    }
    _processedCallIds.add(event.callId);

    // 2. Self-call prevention
    final myId = currentUserId ?? await getAuthenticatedUserId();
    if (myId != null && myId.isNotEmpty && event.callerId.isNotEmpty && myId == event.callerId) {
      AppLogger.d('[CALL][SELF_CALL] Ignored self-initiated call event for callerId: ${event.callerId}');
      return false;
    }

    // 3. Verify backend call validity
    final isActiveOnBackend = await ConsultationApiService().verifyVoiceSessionActive(event.consultationId);
    if (!isActiveOnBackend) {
      AppLogger.d('[CALL][VALIDITY] Call session is no longer active on backend for consultationId: ${event.consultationId}');
      return false;
    }

    // 4. Transition State Machine
    final transitioned = stateMachine.transitionTo(
      CallState.incomingRinging,
      callId: event.callId,
      consultationId: event.consultationId,
    );
    if (!transitioned) return false;

    // 5. Single Canonical Presentation Owner (Android Heads-Up Call Notification)
    AppLogger.d('[CALL][PRESENTATION] Displaying canonical Android incoming-call notification banner');
    await CallKitService().showCallkitIncoming(
      consultationId: event.consultationId,
      name: event.callerName,
      extra: event.rawData,
    );

    return true;
  }

  static void showIncomingCallModal(Map<String, dynamic> data, String defaultAppointmentId) {
    final event = IncomingCallEvent.fromMap(data, defaultAppointmentId: defaultAppointmentId);
    handleIncomingCallEvent(event);
  }

  static Future<void> initUserCallListener({bool force = false}) async {
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
      _isRingingShown = false;
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
    _isRingingShown = false;
    isCallActive = false;
  }
}
