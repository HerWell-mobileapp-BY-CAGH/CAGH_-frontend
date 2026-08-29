import 'dart:io';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/main.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();

  factory CallKitService() {
    return _instance;
  }

  CallKitService._internal();

  Future<void> init() async {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;
      try {
        Map extra = {};
        String consultationId = '';
        String callerName = 'Care Provider';

        try {
          final dynamic dynEvent = event;
          final params = dynEvent.callKitParams;
          if (params != null) {
            extra = params.extra ?? {};
            consultationId = (extra['consultation_id'] ?? params.id ?? '').toString();
            callerName = NameFormatter.format((extra['caller_name'] ?? extra['sender_name'] ?? params.nameCaller ?? 'Care Provider').toString());
          } else {
            final body = (dynEvent.body as Map?) ?? {};
            extra = Map<String, dynamic>.from(body['extra'] ?? {});
            consultationId = (extra['consultation_id'] ?? body['id'] ?? '').toString();
          }
        } catch (e) {
          AppLogger.d('CallKitService: Error parsing call event params: $e');
        }

        switch (event.eventName) {
          case 'ACTION_CALL_INCOMING':
            break;
          case 'ACTION_CALL_START':
            break;
          case 'ACTION_CALL_ACCEPT':
            RingtoneService.stopRingtone();
            GlobalCallService.isRingingShown = false;
            final navStateAccept = globalNavigatorKey.currentState;
            if (navStateAccept != null && navStateAccept.canPop()) {
              navStateAccept.pop();
            }
            if (consultationId.isNotEmpty) {
              try {
                await FlutterCallkitIncoming.setCallConnected(consultationId);
                GlobalCallService.isCallActive = true;
              } catch (e) {
                AppLogger.d('CallKitService setCallConnected error: $e');
              }
              await FlutterCallkitIncoming.endAllCalls();
              try {
                await ConsultationApiService().acceptVoiceSession(consultationId);
              } catch (e) {
                AppLogger.d('CallKitService: Error calling acceptVoiceSession: $e');
              }
              final mapExtra = Map<String, dynamic>.from(extra);
              final callerId = GlobalCallService.extractId(mapExtra['caller_id'] ?? mapExtra['sender_id'] ?? mapExtra['caller'] ?? mapExtra['sender'] ?? mapExtra['user_id']);
              final receiverId = GlobalCallService.extractId(mapExtra['receiver_id'] ?? mapExtra['recipient_id'] ?? mapExtra['receiver'] ?? mapExtra['recipient'] ?? mapExtra['midwife_id']);
              final receiverName = GlobalCallService.extractPersonName(mapExtra, isSender: false);
              final recipientDisplayName = receiverName.isNotEmpty && receiverName != 'Recipient' ? receiverName : 'Midwife';

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
                      midwifeName: recipientDisplayName,
                    ),
                    isCaller: false,
                  ),
                ),
              );
            }
            break;
          case 'ACTION_CALL_DECLINE':
            RingtoneService.stopRingtone();
            GlobalCallService.isCallActive = false;
            GlobalCallService.isRingingShown = false;
            final navStateDecline = globalNavigatorKey.currentState;
            if (navStateDecline != null && navStateDecline.canPop()) {
              navStateDecline.pop();
            }
            if (consultationId.isNotEmpty) {
              GlobalCallService.declineCall(consultationId);
            }
            await FlutterCallkitIncoming.endAllCalls();
            break;
          case 'ACTION_CALL_ENDED':
            // If the call is already active (e.g. the in-app overlay accepted it and
            // dismissed CallKit), don't tear it down — just close the native UI.
            if (!GlobalCallService.isCallActive && consultationId.isNotEmpty) {
              try {
                await ConsultationApiService().endVoiceSession(consultationId);
              } catch (e) {
                AppLogger.d('CallKitService: Error ending voice session: $e');
              }
            }
            await FlutterCallkitIncoming.endAllCalls();
            break;
          case 'ACTION_CALL_TIMEOUT':
            // Ignore a timeout for an already-active call (e.g. accepted via the
            // in-app overlay); otherwise mark it missed.
            if (!GlobalCallService.isCallActive && consultationId.isNotEmpty) {
              try {
                await ConsultationApiService().missedVoiceSession(consultationId);
              } catch (e) {
                AppLogger.d('CallKitService: Error marking voice session missed: $e');
              }
            }
            await FlutterCallkitIncoming.endAllCalls();
            break;
          default:
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
  }) async {
    final params = CallKitParams(
      id: consultationId,
      nameCaller: name,
      appName: 'CAGH Digital Midwife',
      avatar: avatar,
      handle: 'End-to-End Encrypted Voice Call',
      type: 0,
      duration: 30000,
      extra: extra,
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: AppColors.primaryGreenHex,
        actionColor: AppColors.accentGreenHex,
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
        isShowFullLockedScreen: true,
        textAccept: 'Accept',
        textDecline: 'Decline',
      ),
      ios: const IOSParams(
        supportsVideo: false,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
