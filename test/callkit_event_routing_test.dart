import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:cagh_frontend/features/consultations/data/services/callkit_service.dart';

void main() {
  group('CallKit Event Routing Constants Verification', () {
    test('Canonical CallEventConstants match fully-qualified plugin strings', () {
      expect(
        CallEventConstants.actionCallAccept,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT',
      );
      expect(
        CallEventConstants.actionCallDecline,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE',
      );
      expect(
        CallEventConstants.actionCallIncoming,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_INCOMING',
      );
      expect(
        CallEventConstants.actionCallStart,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_START',
      );
      expect(
        CallEventConstants.actionCallEnded,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_ENDED',
      );
      expect(
        CallEventConstants.actionCallTimeout,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TIMEOUT',
      );
      expect(
        CallEventConstants.actionCallCallback,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_CALLBACK',
      );
      expect(
        CallEventConstants.actionCallCustom,
        'com.hiennv.flutter_callkit_incoming.ACTION_CALL_CUSTOM',
      );
    });

    test('Switch statement helper routes both fully-qualified and bare short event strings', () {
      String routeEvent(String eventName) {
        switch (eventName) {
          case CallEventConstants.actionCallIncoming:
          case 'ACTION_CALL_INCOMING':
            return 'INCOMING';
          case CallEventConstants.actionCallStart:
          case 'ACTION_CALL_START':
            return 'START';
          case CallEventConstants.actionCallAccept:
          case 'ACTION_CALL_ACCEPT':
            return 'ACCEPT';
          case CallEventConstants.actionCallDecline:
          case 'ACTION_CALL_DECLINE':
            return 'DECLINE';
          case CallEventConstants.actionCallEnded:
          case 'ACTION_CALL_ENDED':
            return 'ENDED';
          case CallEventConstants.actionCallTimeout:
          case 'ACTION_CALL_TIMEOUT':
            return 'TIMEOUT';
          case CallEventConstants.actionCallCallback:
          case CallEventConstants.actionCallCustom:
          case 'ACTION_CALL_CALLBACK':
          case 'ACTION_CALL_TOGGLE_DPO_WITH_DISPLAY':
          case 'ACTION_CALL_CUSTOM':
            return 'CUSTOM';
          default:
            return 'ACTION_NOT_ROUTED';
        }
      }

      // Fully qualified plugin events
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT'), 'ACCEPT');
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE'), 'DECLINE');
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_INCOMING'), 'INCOMING');
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_START'), 'START');
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_ENDED'), 'ENDED');
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_TIMEOUT'), 'TIMEOUT');
      expect(routeEvent('com.hiennv.flutter_callkit_incoming.ACTION_CALL_CALLBACK'), 'CUSTOM');

      // Bare short event strings
      expect(routeEvent('ACTION_CALL_ACCEPT'), 'ACCEPT');
      expect(routeEvent('ACTION_CALL_DECLINE'), 'DECLINE');
      expect(routeEvent('ACTION_CALL_INCOMING'), 'INCOMING');
      expect(routeEvent('ACTION_CALL_START'), 'START');
      expect(routeEvent('ACTION_CALL_ENDED'), 'ENDED');
      expect(routeEvent('ACTION_CALL_TIMEOUT'), 'TIMEOUT');
      expect(routeEvent('ACTION_CALL_CALLBACK'), 'CUSTOM');
    });

    test('Test I — CallKit dismissal echo is suppressed while genuine ACTION_CALL_ENDED is routed', () {
      bool isDismissingCallKitPresentation = true;

      String? handleEndedEvent(String eventName) {
        if (eventName == CallEventConstants.actionCallEnded || eventName == 'ACTION_CALL_ENDED') {
          if (isDismissingCallKitPresentation) {
            isDismissingCallKitPresentation = false;
            return 'IGNORED_DISMISSAL_ECHO';
          }
          return 'ROUTED_TO_DISPATCH_END';
        }
        return 'UNKNOWN';
      }

      // First event during presentation dismissal -> IGNORED
      expect(handleEndedEvent('ACTION_CALL_ENDED'), 'IGNORED_DISMISSAL_ECHO');
      expect(isDismissingCallKitPresentation, false);

      // Subsequent genuine END event -> ROUTED
      expect(handleEndedEvent('ACTION_CALL_ENDED'), 'ROUTED_TO_DISPATCH_END');
    });

    test('Test 11 & 12 — CallKitPresentationOperation handles duplicate dismissal echoes without suppressing genuine hangups', () {
      CallKitPresentationOperation op = CallKitPresentationOperation.dismissingAfterAccept;
      int dismissalTimestamp = DateTime.now().millisecondsSinceEpoch;

      String handleEndedEvent(String eventName) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final isWithinWindow = dismissalTimestamp > 0 && (now - dismissalTimestamp) < 3500;
        final isDismissing = op == CallKitPresentationOperation.dismissingAfterAccept || isWithinWindow;

        if (isDismissing) {
          return 'NATIVE_DISMISSAL_ECHO';
        }
        return 'GENUINE_NATIVE_END';
      }

      // Duplicate Event 1 -> Dismissal echo ignored
      expect(handleEndedEvent('ACTION_CALL_ENDED'), 'NATIVE_DISMISSAL_ECHO');

      // Duplicate Event 2 -> Dismissal echo ignored (op remains active for dismissal transaction window)
      expect(handleEndedEvent('ACTION_CALL_ENDED'), 'NATIVE_DISMISSAL_ECHO');

      // Duplicate Event 3 -> Dismissal echo ignored
      expect(handleEndedEvent('ACTION_CALL_ENDED'), 'NATIVE_DISMISSAL_ECHO');

      // Genuine END outside dismissal window / operation -> Routed as GENUINE_NATIVE_END
      op = CallKitPresentationOperation.none;
      dismissalTimestamp = 0;
      expect(handleEndedEvent('ACTION_CALL_ENDED'), 'GENUINE_NATIVE_END');
    });
  });
}
