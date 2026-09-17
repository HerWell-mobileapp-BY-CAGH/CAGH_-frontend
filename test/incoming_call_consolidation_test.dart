import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GlobalCallService.stateMachine.reset();
    GlobalCallService.currentUserId = 'user_111';
  });

  tearDown(() async {
    await GlobalCallService.teardownCall(
      callId: 'VOICE-123',
      consultationId: 'VOICE-123',
      reason: CallTerminalReason.hangup,
      source: 'test_teardown',
    );
    await GlobalCallService.teardownCall(
      callId: 'VOICE-456',
      consultationId: 'VOICE-456',
      reason: CallTerminalReason.hangup,
      source: 'test_teardown',
    );
    GlobalCallService.stateMachine.reset();
  });

  group('Incoming Voice-Call UI Consolidation & Deduplication Tests', () {
    test('Test 1 — FCM only incoming call produces canonical IncomingCallEvent', () async {
      final fcmPayload = {
        'action': 'incoming_call',
        'call_id': 'VOICE-123',
        'consultation_id': 'VOICE-123',
        'caller_name': 'Dr. Jane Smith',
        'caller_id': 'caller_789',
      };

      final event = IncomingCallEvent.fromMap(fcmPayload);
      expect(event.callId, 'VOICE-123');
      expect(event.callerName, 'Dr Jane Smith');
      expect(event.callerId, 'caller_789');
    });

    test('Test 2 — WebSocket only incoming call produces canonical IncomingCallEvent', () async {
      final wsPayload = {
        'type': 'call_offer',
        'call_id': 'VOICE-123',
        'consultation_id': 'VOICE-123',
        'caller_name': 'Dr. Jane Smith',
        'caller_id': 'caller_789',
      };

      final event = IncomingCallEvent.fromMap(wsPayload);
      expect(event.callId, 'VOICE-123');
      expect(event.callerName, 'Dr Jane Smith');
      expect(event.callerId, 'caller_789');
    });

    test('Test 3 — FCM then WebSocket for same call_id: WebSocket event is deduplicated by state machine/processed ids', () async {
      final eventId = 'VOICE-123';
      
      // Simulate FCM event transitioning state machine to incomingRinging
      final transitioned = GlobalCallService.stateMachine.transitionTo(
        CallState.incomingRinging,
        callId: eventId,
        consultationId: eventId,
      );
      expect(transitioned, isTrue);

      final wsEvent = IncomingCallEvent.fromMap({
        'type': 'call_offer',
        'call_id': eventId,
        'consultation_id': eventId,
        'caller_id': 'caller_789',
      });

      // Subsequent WebSocket event for the exact same call_id must be ignored since state != idle
      final wsHandled = await GlobalCallService.handleIncomingCallEvent(wsEvent);
      expect(wsHandled, isFalse, reason: 'Duplicate WebSocket event for same call_id must be deduplicated and ignored when ringing');
    });

    test('Test 4 — WebSocket then FCM for same call_id: FCM event is deduplicated by state machine/processed ids', () async {
      final eventId = 'VOICE-123';

      // Simulate WebSocket event transitioning state machine to incomingRinging
      final transitioned = GlobalCallService.stateMachine.transitionTo(
        CallState.incomingRinging,
        callId: eventId,
        consultationId: eventId,
      );
      expect(transitioned, isTrue);

      final fcmEvent = IncomingCallEvent.fromMap({
        'action': 'incoming_call',
        'call_id': eventId,
        'consultation_id': eventId,
        'caller_id': 'caller_789',
      });

      // Subsequent FCM event for the exact same call_id must be ignored
      final fcmHandled = await GlobalCallService.handleIncomingCallEvent(fcmEvent);
      expect(fcmHandled, isFalse, reason: 'Duplicate FCM event for same call_id must be deduplicated and ignored when ringing');
    });

    test('Test 5 — Different calls (VOICE-123 and VOICE-456) are handled independently', () async {
      final event1 = IncomingCallEvent.fromMap({
        'action': 'incoming_call',
        'call_id': 'VOICE-123',
        'consultation_id': 'VOICE-123',
        'caller_id': 'caller_789',
      });

      final event2 = IncomingCallEvent.fromMap({
        'type': 'call_offer',
        'call_id': 'VOICE-456',
        'consultation_id': 'VOICE-456',
        'caller_id': 'caller_999',
      });

      expect(event1.callId, 'VOICE-123');
      expect(event2.callId, 'VOICE-456');
      expect(event1.callId != event2.callId, isTrue);
    });

    test('Test 6 — Declined call marks call_id terminal; subsequent duplicate events do not reopen UI', () async {
      final callId = 'VOICE-123';
      await GlobalCallService.teardownCall(
        callId: callId,
        consultationId: callId,
        reason: CallTerminalReason.decline,
        source: 'unit_test_decline',
      );

      expect(GlobalCallService.isTerminalCallRecentlySeen(callId), isTrue);

      final duplicateFcmEvent = IncomingCallEvent.fromMap({
        'action': 'incoming_call',
        'call_id': callId,
        'consultation_id': callId,
        'caller_id': 'caller_789',
      });

      final handled = await GlobalCallService.handleIncomingCallEvent(duplicateFcmEvent);
      expect(handled, isFalse, reason: 'Incoming call event for recently declined call must be suppressed');
    });

    test('Test 7 — Accepted call state prevents duplicate incoming UI from appearing', () async {
      final callId = 'VOICE-123';
      
      // Simulate state machine entering connecting/connected state upon accept
      GlobalCallService.stateMachine.transitionTo(
        CallState.connecting,
        callId: callId,
        consultationId: callId,
      );

      final duplicateWsEvent = IncomingCallEvent.fromMap({
        'type': 'call_offer',
        'call_id': callId,
        'consultation_id': callId,
        'caller_id': 'caller_789',
      });

      final handled = await GlobalCallService.handleIncomingCallEvent(duplicateWsEvent);
      expect(handled, isFalse, reason: 'Incoming call event for accepted call must be suppressed');
    });
  });
}
