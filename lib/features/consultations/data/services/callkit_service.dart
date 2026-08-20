import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();

  factory CallKitService() {
    return _instance;
  }

  CallKitService._internal();

  Future<void> init(BuildContext context) async {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.eventName) {
        case 'ACTION_CALL_INCOMING':
          // Call incoming event
          break;
        case 'ACTION_CALL_START':
          // Call start event
          break;
        case 'ACTION_CALL_ACCEPT':
          // TODO: Navigate to VoiceCallScreen
          break;
        case 'ACTION_CALL_DECLINE':
          // TODO: Send decline signal to backend
          break;
        case 'ACTION_CALL_ENDED':
          // Call ended
          break;
        case 'ACTION_CALL_TIMEOUT':
          // Missed call
          break;
        default:
          break;
      }
    });
  }

  Future<void> showCallkitIncoming(String uuid, String name, String avatar) async {
    final params = CallKitParams(
      id: uuid,
      nameCaller: name,
      appName: 'Digital Midwife',
      avatar: avatar,
      handle: 'Incoming Voice Call',
      type: 0,
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      duration: 30000,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      headers: <String, dynamic>{'apiKey': 'xxxxxxx'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: false,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
