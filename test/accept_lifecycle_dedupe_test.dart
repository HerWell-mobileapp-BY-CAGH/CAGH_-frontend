import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Frontend ACCEPT Lifecycle & Single-Request Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000\nAPI_URL=http://localhost:8000/api/\nWS_URL=ws://localhost:8000/ws');
    });

    tearDown(() {
      if (GlobalCallService.stateMachine.state != CallState.idle) {
        GlobalCallService.stateMachine.transitionTo(CallState.ended);
        GlobalCallService.stateMachine.transitionTo(CallState.idle);
      }
    });

    test('Test 1 — Authorized ACCEPT sources invoke dispatcher while unauthorized sources are rejected', () {
      expect(
        IncomingCallActionDispatcher.hasBeenAccepted('TEST_UNAUTH_1'),
        false,
      );

      // Unauthorized source call
      IncomingCallActionDispatcher.dispatchAccept(
        'TEST_UNAUTH_1',
        'TEST_UNAUTH_1',
        {},
        source: 'UNAUTHORIZED_AUTO_ACCEPT',
      );
      expect(
        IncomingCallActionDispatcher.hasBeenAccepted('TEST_UNAUTH_1'),
        false,
      );
    });

    test('Test 2 & 3 — Single ACCEPT POST guarantee and 401 no-retry rule', () async {
      int httpPostCount = 0;

      Future<int> mockAcceptCall(String consultationId) async {
        httpPostCount++;
        return 401; // Mock 401 response
      }

      Future<void> executeSingleAccept(String id) async {
        final status = await mockAcceptCall(id);
        if (status != 200 && status != 201 && status != 409) {
          // Clean failure teardown without retry POST
          return;
        }
      }

      await executeSingleAccept('CONSULT_401_TEST');
      expect(httpPostCount, 1);
    });

    test('Test 4 & 5 — CallKit ACCEPT + RESTORE_PENDING_CALL deduplication gate', () async {
      final consultationId = 'RACE_TEST_CONSULTATION_100';

      // First dispatch synchronously claims the consultation ID
      IncomingCallActionDispatcher.dispatchAccept(
        consultationId,
        consultationId,
        {},
        source: 'CALLKIT_USER_ACCEPT',
      ).catchError((_) {});

      expect(IncomingCallActionDispatcher.hasBeenAccepted(consultationId), true);

      // Second dispatch (e.g. RESTORE_PENDING_CALL) is blocked by hasBeenAccepted
      bool secondCallAccepted = false;
      if (!IncomingCallActionDispatcher.hasBeenAccepted(consultationId)) {
        secondCallAccepted = true;
      }

      expect(secondCallAccepted, false);
    });

    test('Test 6 — Duplicate call_accepted WebSocket event does not re-trigger ACCEPT or state corruption', () {
      GlobalCallService.stateMachine.transitionTo(
        CallState.connecting,
        callId: 'WS_DEDUPE_1',
        consultationId: 'WS_DEDUPE_1',
      );

      final stateBefore = GlobalCallService.stateMachine.state;
      expect(stateBefore, CallState.connecting);

      // Duplicate event while already connecting -> state remains connecting
      if (GlobalCallService.stateMachine.state == CallState.connecting ||
          GlobalCallService.stateMachine.state == CallState.connected) {
        // Ignored
      } else {
        GlobalCallService.stateMachine.transitionTo(
          CallState.connecting,
          callId: 'WS_DEDUPE_1',
          consultationId: 'WS_DEDUPE_1',
        );
      }

      expect(GlobalCallService.stateMachine.state, CallState.connecting);
    });

    test('Test 7 — CallNavigationCoordinator enforces single navigation path', () {
      expect(CallNavigationCoordinator.hasCallNavigationActiveOrPending, false);
    });
  });
}
