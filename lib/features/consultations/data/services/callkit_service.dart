import 'dart:io';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

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

  static String? _activeConsultationId;
  static Map<String, dynamic> _activeExtra = {};
  static String _activeCallerName = 'Care Provider';
  static CallKitPresentationOperation _presentationOperation = CallKitPresentationOperation.none;
  static int _dismissalWindowTimestamp = 0;

  CallKitPresentationOperation get presentationOperation => _presentationOperation;
  set presentationOperation(CallKitPresentationOperation op) {
    _presentationOperation = op;
    if (op != CallKitPresentationOperation.none) {
      _dismissalWindowTimestamp = DateTime.now().millisecondsSinceEpoch;
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (_presentationOperation == op) {
          _presentationOperation = CallKitPresentationOperation.none;
        }
      });
    }
  }

  void recordDismissalWindow() {
    _dismissalWindowTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> _parseCallData(dynamic call) {
    if (call == null) return {};
    if (call is CallKitParams) {
      return {
        'id': call.id ?? '',
        'nameCaller': call.nameCaller ?? '',
        'extra': call.extra ?? {},
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

  Future<void> init() async {
    if (_isInitialized) {
      AppLogger.d('[CALL][CALLKIT_LISTENER_REGISTERED] Listener already active, skipping re-registration');
      return;
    }
    _isInitialized = true;
    AppLogger.d('[CALL][CALLKIT_LISTENER_REGISTERED] Registering CallKit event listener singleton');

    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls is List && activeCalls.isNotEmpty) {
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
        AppLogger.d('[CALLKIT-LIFECYCLE] event=${event.eventName} callId=$consultationId state=$currentState presentationOperation=$_presentationOperation');

        switch (event.eventName) {
          case CallEventConstants.actionCallIncoming:
          case 'ACTION_CALL_INCOMING':
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=INCOMING event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            break;
          case CallEventConstants.actionCallStart:
          case 'ACTION_CALL_START':
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=START event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            break;
          case CallEventConstants.actionCallAccept:
          case 'ACTION_CALL_ACCEPT':
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=ACCEPT event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=ACCEPT event=ROUTING_TO_DISPATCHER call_id=$consultationId');
            final mapExtra = Map<String, dynamic>.from(extra);
            await IncomingCallActionDispatcher.dispatchAccept(consultationId, consultationId, mapExtra, source: 'CALLKIT_USER_ACCEPT');
            break;
          case CallEventConstants.actionCallDecline:
          case 'ACTION_CALL_DECLINE':
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=DECLINE event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            await IncomingCallActionDispatcher.dispatchDecline(consultationId, consultationId);
            break;
          case CallEventConstants.actionCallEnded:
          case 'ACTION_CALL_ENDED':
            final now = DateTime.now().millisecondsSinceEpoch;
            final isWithinWindow = _dismissalWindowTimestamp > 0 && (now - _dismissalWindowTimestamp) < 3500;
            final isDismissingAccept = isWithinWindow && _presentationOperation != CallKitPresentationOperation.none;

            AppLogger.d('[CALLKIT-LIFECYCLE] event=ACTION_CALL_ENDED callId=$consultationId state=$currentState presentationOperation=$_presentationOperation withinWindow=$isWithinWindow source=${isDismissingAccept ? "NATIVE_DISMISSAL_ECHO" : "GENUINE_NATIVE_END"}');

            if (isDismissingAccept) {
              AppLogger.d('[CALLKIT] Ignored ACTION_CALL_ENDED generated by presentation dismissal echo (call_id=$consultationId)');
              break;
            }
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=END event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            await IncomingCallActionDispatcher.dispatchEnd(consultationId, consultationId);
            break;
          case CallEventConstants.actionCallTimeout:
          case 'ACTION_CALL_TIMEOUT':
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=TIMEOUT event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            await GlobalCallService.teardownCall(callId: consultationId, consultationId: consultationId, reason: CallTerminalReason.timeout, source: 'callkit_timeout');
            await dismissIncomingCallKitPresentation(operation: CallKitPresentationOperation.dismissingAfterEnd);
            break;
          case CallEventConstants.actionCallCallback:
          case CallEventConstants.actionCallCustom:
          case 'ACTION_CALL_CALLBACK':
          case 'ACTION_CALL_TOGGLE_DPO_WITH_DISPLAY':
          case 'ACTION_CALL_CUSTOM':
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=CUSTOM event=NATIVE_ACTION_RECEIVED call_id=$consultationId');
            if (consultationId.isNotEmpty && !GlobalCallService.isCallActive) {
              final mapExtra = Map<String, dynamic>.from(extra);
              // Body tap opens native full-screen CallKit UI while keeping call ringing
              await showCallkitIncoming(
                consultationId: consultationId,
                name: callerName,
                extra: mapExtra,
                isFullScreen: true,
              );
            }
            break;
          default:
            AppLogger.d('[CALL-ACTION-FE] surface=CALLKIT action=UNKNOWN event=ACTION_NOT_ROUTED call_id=$consultationId raw_event=${event.eventName}');
            break;
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

    final params = CallKitParams(
      id: consultationId,
      nameCaller: name,
      appName: 'CAGH Digital Midwife',
      avatar: avatar,
      handle: 'End-to-End Encrypted Voice Call',
      type: 0,
      duration: 30000,
      extra: extra,
      android: AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: AppColors.primaryGreenHex,
        actionColor: AppColors.accentGreenHex,
        incomingCallNotificationChannelName: 'Incoming Voice Calls v5',
        missedCallNotificationChannelName: 'Missed Voice Calls v5',
        isShowFullLockedScreen: isFullScreen,
        isFullScreen: isFullScreen,
        isImportant: true,
        textAccept: 'Answer',
        textDecline: 'Decline',
      ),
      ios: const IOSParams(
        supportsVideo: false,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Dismisses the native CallKit notification UI presentation on Android/iOS.
  /// Note: This only clears the local notification banner UI and does NOT terminate the backend voice call session.
  Future<void> dismissIncomingCallKitPresentation({
    CallKitPresentationOperation operation = CallKitPresentationOperation.dismissingAfterAccept,
  }) async {
    _presentationOperation = operation;
    _dismissalWindowTimestamp = DateTime.now().millisecondsSinceEpoch;
    _activeConsultationId = null;
    _activeExtra = {};
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      AppLogger.d('CallKitService dismissIncomingCallKitPresentation notice: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (_presentationOperation == operation) {
          _presentationOperation = CallKitPresentationOperation.none;
        }
      });
    }
  }

  /// Alias for backward compatibility
  Future<void> endAllCalls() => dismissIncomingCallKitPresentation(operation: CallKitPresentationOperation.dismissingAfterEnd);
}
