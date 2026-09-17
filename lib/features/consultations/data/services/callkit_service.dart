import 'dart:io';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
// TODO: confirm the real import paths for these two and uncomment —
// they are referenced below but were not imported in the original file.
// import 'package:cagh_frontend/core/services/incoming_call_action_dispatcher.dart';
// import 'package:cagh_frontend/core/services/call_navigation_coordinator.dart';

enum CallKitPresentationOperation {
  none,
  dismissingAfterAccept,
  dismissingAfterDecline,
  dismissingAfterEnd,
}

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();

  factory CallKitService() {
    return _instance;
  }

  CallKitService._internal();

  // Single source of truth for the echo-suppression window. Previously this
  // value was duplicated in three places (the presentationOperation setter,
  // dismissIncomingCallKitPresentation, and the ACTION_CALL_ENDED handler)
  // with two different durations (3500ms vs 3000ms), which opened a race
  // window where a genuine native "call ended" echo would stop being
  // suppressed 500ms before the timestamp-based check expected it to.
  static const Duration _dismissalWindowDuration = Duration(milliseconds: 3500);

  static String? _activeConsultationId;
  static Map<String, dynamic> _activeExtra = {};
  static String _activeCallerName = 'Care Provider';
  static CallKitPresentationOperation _presentationOperation = CallKitPresentationOperation.none;
  static int _dismissalWindowTimestamp = 0;

  CallKitPresentationOperation get presentationOperation => _presentationOperation;
  set presentationOperation(CallKitPresentationOperation op) => _openDismissalWindow(op);

  /// Opens (or re-opens) the echo-suppression window. This is now the only
  /// place that mutates `_presentationOperation` / `_dismissalWindowTimestamp`
  /// — both the public setter and `dismissIncomingCallKitPresentation` route
  /// through here so the "how long do we suppress echoes" duration can never
  /// drift out of sync with the window-expiry check in the event handler.
  void _openDismissalWindow(CallKitPresentationOperation op) {
    _presentationOperation = op;
    if (op == CallKitPresentationOperation.none) return;
    _dismissalWindowTimestamp = DateTime.now().millisecondsSinceEpoch;
    Future.delayed(_dismissalWindowDuration, () {
      if (_presentationOperation == op) {
        _presentationOperation = CallKitPresentationOperation.none;
      }
    });
  }

  /// Opens a suppression window without a specific operation label — used
  /// when the accept/decline flow is driven from in-app UI rather than the
  /// native CallKit UI, but a subsequent native ACTION_CALL_ENDED echo still
  /// needs to be ignored. Previously this only stamped the timestamp and
  /// never set `_presentationOperation`, so the suppression check (which
  /// requires both conditions) silently never fired for this code path.
  void recordDismissalWindow({
    CallKitPresentationOperation operation = CallKitPresentationOperation.dismissingAfterAccept,
  }) {
    _openDismissalWindow(operation);
  }

  Map<String, dynamic> _parseCallData(dynamic call) {
    if (call == null) return {};
    if (call is CallKitParams) {
      return {
        'id': call.id,
        'nameCaller': call.nameCaller,
        'extra': call.extra,
      };
    }
    if (call is Map) {
      return Map<String, dynamic>.from(call);
    }
    try {
      final dyn = call as dynamic;
      final id = (dyn.id ?? '').toString();
      final nameCaller = (dyn.nameCaller ?? '').toString();
      final extra = (dyn.extra is Map) ? Map<String, dynamic>.from(dyn.extra) : <String, dynamic>{};
      return {
        'id': id,
        'nameCaller': nameCaller,
        'extra': extra,
      };
    } catch (_) {
      return {};
    }
  }

  bool _isInitialized = false;

  /// Matches an event's name against a known constant safely. Using this
  /// instead of a `switch` on `event.eventName` avoids Dart's compile-time
  /// "duplicate case value" error, which the original code was exposed to:
  /// if `CallEventConstants.actionCallIncoming` (etc.) is itself defined as
  /// the literal string `'ACTION_CALL_INCOMING'`, having both
  /// `case CallEventConstants.actionCallIncoming:` and
  /// `case 'ACTION_CALL_INCOMING':` in the same switch is two case labels
  /// for one value — illegal in Dart. Plain `==` comparisons in an if/else
  /// chain tolerate that overlap safely.
  bool _eventIs(String eventName, List<String> candidates) {
    return candidates.contains(eventName);
  }

  Future<void> init() async {
    if (_isInitialized) {
      AppLogger.d('[CALL][CALLKIT_LISTENER_REGISTERED] Listener already active, skipping re-registration');
      return;
    }
    _isInitialized = true;
    AppLogger.d('[CALL][CALLKIT_LISTENER_REGISTERED] Registering CallKit event listener singleton');

    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls.isNotEmpty) {
        final rawCall = activeCalls.first;
        final callMap = _parseCallData(rawCall);
        final extraMap = Map<String, dynamic>.from(callMap['extra'] ?? {});
        final id = (extraMap['consultation_id'] ?? extraMap['call_id'] ?? callMap['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _activeConsultationId = id;
          _activeExtra = extraMap;
          _activeCallerName = (extraMap['caller_name'] ?? callMap['nameCaller'] ?? 'Care Provider').toString();
          AppLogger.d('CallKitService: Restored active call info on init for consultation: $id');
        }
      }
    } catch (e) {
      AppLogger.d('CallKitService: error inspecting activeCalls on init: $e');
    }

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;
      try {
        Map<String, dynamic> extra = {};
        String consultationId = '';
        String callerName = 'Care Provider';

        try {
          CallKitParams? params;
          Map<String, dynamic> bodyMap = {};
          String? eventId;

          if (event is CallEventActionCallIncoming) {
            params = event.callKitParams;
          } else if (event is CallEventActionCallStart) {
            params = event.callKitParams;
          } else if (event is CallEventActionCallAccept) {
            params = event.callKitParams;
          } else if (event is CallEventActionCallDecline) {
            params = event.callKitParams;
          } else if (event is CallEventActionCallEnded) {
            params = event.callKitParams;
          } else if (event is CallEventActionCallCustom) {
            bodyMap = Map<String, dynamic>.from(event.body);
          } else if (event is CallEventActionCallTimeout) {
            eventId = event.id;
          } else if (event is CallEventActionCallConnected) {
            eventId = event.id;
          } else if (event is CallEventActionCallCallback) {
            eventId = event.id;
          }

          if (params != null) {
            if (params.extra != null && params.extra is Map) {
              extra.addAll(Map<String, dynamic>.from(params.extra!));
            }
            consultationId = (extra['consultation_id'] ?? extra['call_id'] ?? params.id ?? '').toString();
            final name = (extra['caller_name'] ?? extra['sender_name'] ?? params.nameCaller ?? '').toString();
            if (name.isNotEmpty) callerName = NameFormatter.format(name);
          }

          if (bodyMap.isNotEmpty) {
            if (bodyMap['extra'] != null && bodyMap['extra'] is Map) {
              extra.addAll(Map<String, dynamic>.from(bodyMap['extra']));
            }
            if (consultationId.isEmpty || consultationId == 'null') {
              consultationId = (extra['consultation_id'] ?? extra['call_id'] ?? bodyMap['id'] ?? bodyMap['consultation_id'] ?? '').toString();
            }
            if (callerName.isEmpty || callerName == 'Care Provider') {
              final name = (extra['caller_name'] ?? extra['sender_name'] ?? bodyMap['nameCaller'] ?? bodyMap['caller_name'] ?? '').toString();
              if (name.isNotEmpty) callerName = NameFormatter.format(name);
            }
          }

          if ((consultationId.isEmpty || consultationId == 'null') && eventId != null && eventId.isNotEmpty) {
            consultationId = eventId;
          }
        } catch (e) {
          AppLogger.d('CallKitService: Error parsing call event params: $e');
        }

        // Multi-tier fallback to stored active call parameters
        if (consultationId.isEmpty || consultationId == 'null') {
          consultationId = _activeConsultationId ?? GlobalCallService.activeConsultationId ?? '';
        }
        if (extra.isEmpty && _activeExtra.isNotEmpty) {
          extra = Map<String, dynamic>.from(_activeExtra);
        }
        if ((callerName.isEmpty || callerName == 'Care Provider') && _activeCallerName.isNotEmpty) {
          callerName = _activeCallerName;
        }

        final currentState = GlobalCallService.stateMachine.state;
        final eventName = event.eventName;
        AppLogger.d('[CALLKIT-LIFECYCLE] event=$eventName callId=$consultationId state=$currentState presentationOperation=$_presentationOperation');

        if (_eventIs(eventName, [CallEventConstants.actionCallIncoming, 'ACTION_CALL_INCOMING'])) {
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=INCOMING event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
        } else if (_eventIs(eventName, [CallEventConstants.actionCallStart, 'ACTION_CALL_START'])) {
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=START event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
        } else if (_eventIs(eventName, [CallEventConstants.actionCallAccept, 'ACTION_CALL_ACCEPT'])) {
          AppLogger.d('[CALL_TRACE] CALL_ACCEPT_REQUESTED source=CALLKIT_USER_ACCEPT call_id=$consultationId');
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=ACCEPT event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=ACCEPT event=ROUTING_TO_DISPATCHER call_id=$consultationId');
          final mapExtra = Map<String, dynamic>.from(extra);
          await IncomingCallActionDispatcher.dispatchAccept(consultationId, consultationId, mapExtra, source: 'CALLKIT_USER_ACCEPT');
        } else if (_eventIs(eventName, [CallEventConstants.actionCallDecline, 'ACTION_CALL_DECLINE'])) {
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=DECLINE event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
          if (currentState == CallState.connecting || currentState == CallState.connected) {
            AppLogger.d('[CALLKIT] Ignored ACTION_CALL_DECLINE echo generated after call acceptance (call_id=$consultationId state=$currentState)');
          } else {
            await IncomingCallActionDispatcher.dispatchDecline(consultationId, consultationId);
          }
        } else if (_eventIs(eventName, [CallEventConstants.actionCallEnded, 'ACTION_CALL_ENDED'])) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final isWithinWindow = _dismissalWindowTimestamp > 0 &&
              (now - _dismissalWindowTimestamp) < _dismissalWindowDuration.inMilliseconds;
          final isDismissalEcho = isWithinWindow && _presentationOperation != CallKitPresentationOperation.none;

          AppLogger.d('[CALLKIT-LIFECYCLE] event=ACTION_CALL_ENDED callId=$consultationId state=$currentState presentationOperation=$_presentationOperation withinWindow=$isWithinWindow source=${isDismissalEcho ? "NATIVE_DISMISSAL_ECHO" : "GENUINE_NATIVE_END"}');

          if (isDismissalEcho) {
            AppLogger.d('[CALLKIT] Ignored ACTION_CALL_ENDED generated by presentation dismissal echo (call_id=$consultationId)');
          } else {
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=END event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            await IncomingCallActionDispatcher.dispatchEnd(consultationId, consultationId);
          }
        } else if (_eventIs(eventName, [CallEventConstants.actionCallTimeout, 'ACTION_CALL_TIMEOUT'])) {
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=TIMEOUT event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
          await GlobalCallService.teardownCall(callId: consultationId, consultationId: consultationId, reason: CallTerminalReason.timeout, source: 'callkit_timeout');
          await dismissIncomingCallKitPresentation(operation: CallKitPresentationOperation.dismissingAfterEnd);
        } else if (_eventIs(eventName, [
          CallEventConstants.actionCallCallback,
          CallEventConstants.actionCallCustom,
          'ACTION_CALL_CALLBACK',
          'ACTION_CALL_TOGGLE_DPO_WITH_DISPLAY',
          'ACTION_CALL_CUSTOM',
        ])) {
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=CUSTOM event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
          if (consultationId.isNotEmpty && !GlobalCallService.isCallActive) {
            CallNavigationCoordinator.checkAndNavigatePendingCall();
          }
        } else {
          AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=UNKNOWN event=ACTION_NOT_ROUTED call_id=$consultationId raw_event=$eventName');
        }
      } catch (e) {
        AppLogger.d('CallKitService event handling error: $e');
      }
    });
    // Android 14+ requires the full-screen-intent permission for the incoming call
    // to appear over a locked screen (WhatsApp/Telegram parity). No-op on older Android.
    if (Platform.isAndroid) {
      try {
        await FlutterCallkitIncoming.requestFullIntentPermission();
      } catch (e) {
        AppLogger.d('CallKitService: requestFullIntentPermission notice: $e');
      }
    }
  }

  Future<void> showCallkitIncoming({
    required String consultationId,
    required String name,
    String avatar = 'assets/images/logo.png',
    Map<String, dynamic> extra = const {},
    bool isFullScreen = false,
  }) async {
    _activeConsultationId = consultationId;
    _activeExtra = Map<String, dynamic>.from(extra);
    _activeCallerName = name;
    AppLogger.d('[CALL_TRACE] Native CallKit UI suppressed in favor of custom VoiceCallScreen (call_id=$consultationId)');
  }

  /// Dismisses the native CallKit notification UI presentation on Android/iOS.
  /// Note: This only clears the local notification banner UI and does NOT terminate the backend voice call session.
  Future<void> dismissIncomingCallKitPresentation({
    CallKitPresentationOperation operation = CallKitPresentationOperation.dismissingAfterAccept,
  }) async {
    _openDismissalWindow(operation);
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      AppLogger.d('CallKitService dismissIncomingCallKitPresentation notice: $e');
    } finally {
      // Deliberately NOT clearing _activeConsultationId/_activeExtra here.
      // endAllCalls() above can synchronously re-enter the onEvent listener
      // with an ACTION_CALL_ENDED echo; that handler's fallback chain
      // (`_activeConsultationId ?? GlobalCallService.activeConsultationId`)
      // needs these values to still resolve the call id for logging/
      // suppression during the dismissal window. They'll be naturally
      // overwritten the next time showCallkitIncoming() runs, so nothing
      // is leaked long-term — clear them once the window actually closes.
      Future.delayed(_dismissalWindowDuration, () {
        if (_presentationOperation == CallKitPresentationOperation.none) {
          _activeConsultationId = null;
          _activeExtra = {};
        }
      });
    }
  }

  /// Alias for backward compatibility
  Future<void> endAllCalls() => dismissIncomingCallKitPresentation(operation: CallKitPresentationOperation.dismissingAfterEnd);
}