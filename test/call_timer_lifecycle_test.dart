import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';

void main() {
  group('Call State Machine Lifecycle & Transitions', () {
    late CallStateMachine stateMachine;

    setUp(() {
      stateMachine = CallStateMachine();
    });

    test('Initial state is idle', () {
      expect(stateMachine.state, CallState.idle);
    });

    test('Valid transition from idle -> incomingRinging -> connecting -> connected -> ended -> idle', () {
      expect(stateMachine.transitionTo(CallState.incomingRinging, callId: 'c1'), true);
      expect(stateMachine.state, CallState.incomingRinging);

      expect(stateMachine.transitionTo(CallState.connecting, callId: 'c1'), true);
      expect(stateMachine.state, CallState.connecting);

      expect(stateMachine.transitionTo(CallState.connected, callId: 'c1'), true);
      expect(stateMachine.state, CallState.connected);

      expect(stateMachine.transitionTo(CallState.ended, callId: 'c1'), true);
      expect(stateMachine.state, CallState.ended);

      expect(stateMachine.transitionTo(CallState.idle), true);
      expect(stateMachine.state, CallState.idle);
    });

    test('Direct accept from idle -> connecting -> connected is valid', () {
      expect(stateMachine.transitionTo(CallState.connecting, callId: 'c2'), true);
      expect(stateMachine.state, CallState.connecting);

      expect(stateMachine.transitionTo(CallState.connected, callId: 'c2'), true);
      expect(stateMachine.state, CallState.connected);
    });

    test('Decline from connecting state is valid', () {
      expect(stateMachine.transitionTo(CallState.connecting, callId: 'c3'), true);
      expect(stateMachine.transitionTo(CallState.declined, callId: 'c3'), true);
      expect(stateMachine.state, CallState.declined);
    });

    test('Invalid transition from idle directly to connected is rejected', () {
      expect(stateMachine.transitionTo(CallState.connected, callId: 'c4'), false);
      expect(stateMachine.state, CallState.idle);
    });

    test('teardownCall is idempotent across dual IDs (consultationId and callId)', () async {
      GlobalCallService.stateMachine.reset();
      GlobalCallService.stateMachine.transitionTo(CallState.connecting, callId: 'SESSION-100', consultationId: 'CONSULT-100');

      // First teardown using session ID
      await GlobalCallService.teardownCall(
        callId: 'SESSION-100',
        consultationId: 'CONSULT-100',
        reason: CallTerminalReason.hangup,
        source: 'test_teardown_1',
      );

      expect(GlobalCallService.isTerminalCallRecentlySeen('SESSION-100'), true);
      expect(GlobalCallService.isTerminalCallRecentlySeen('CONSULT-100'), true);

      // Second duplicate teardown using consultation ID after state machine is back to idle
      await GlobalCallService.teardownCall(
        callId: 'CONSULT-100',
        consultationId: 'CONSULT-100',
        reason: CallTerminalReason.hangup,
        source: 'test_teardown_2',
      );

      // State machine must remain safely in idle without throwing or rejecting transitions
      expect(GlobalCallService.stateMachine.state, CallState.idle);
    });

    test('dispatchAccept rejects unauthorized sources', () async {
      GlobalCallService.stateMachine.reset();
      await IncomingCallActionDispatcher.dispatchAccept(
        'CONSULT-200',
        'CONSULT-200',
        {},
        source: 'UNAUTHORIZED_AUTO_ACCEPT',
      );
      expect(IncomingCallActionDispatcher.hasBeenAccepted('CONSULT-200'), false);
    });
  });
}
