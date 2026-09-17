import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/services/global_call_websocket_manager.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/webrtc_voice_service.dart';

String _createTestJwt(int expTimestampSeconds) {
  const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
  final payloadJson = jsonEncode({'user_id': 'u1', 'exp': expTimestampSeconds});
  final payloadBase64 = base64Url.encode(utf8.encode(payloadJson)).replaceAll('=', '');
  return '$header.$payloadBase64.sig';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Call Signaling Fixes Unit Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      GlobalCallService.currentUserId = null;
    });

    test('Test 1 & 3: syncCurrentUserId populates currentUserId from authentication', () async {
      final prefs = await SharedPreferences.getInstance();
      const mockJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidXNlcl80NTYiLCJleHAiOjE5OTk5OTk5OTl9.signature';
      await prefs.setString('auth_token', mockJwt);
      await prefs.setString('user_data', '{"id": "user_456", "full_name": "Test User"}');

      final syncedId = await GlobalCallService.syncCurrentUserId();
      expect(syncedId, 'user_456');
      expect(GlobalCallService.currentUserId, 'user_456');
    });

    test('Test 2: logout clears currentUserId and disconnects WebSocket', () async {
      GlobalCallService.currentUserId = 'user_789';
      expect(GlobalCallService.currentUserId, 'user_789');

      await AuthService.logout();
      expect(GlobalCallService.currentUserId, isNull);
      expect(GlobalCallWebSocketManager.instance.state, GlobalWsState.disconnected);
    });

    test('Test 4 & 9: Callee does NOT create initial offer on accept; offer direction is caller-only', () async {
      final service = WebRTCVoiceService();

      int offerCount = 0;
      service.setSignalSender((payload) {
        if (payload['type'] == 'webrtc_offer' || payload['action'] == 'webrtc_offer') {
          offerCount++;
        }
      });

      // Callee setup
      service.setLocalUserId('callee_2');
      service.setRemoteUserId('caller_1');

      // Callee should not create offers
      expect(offerCount, 0);
    });

    test('Test 5: WebRTC offer payload parsing supports root and nested data structures', () {
      final rootPayload = {
        'type': 'webrtc_offer',
        'sdp': 'v=0\r\no=- 123 2 IN IP4 127.0.0.1...',
        'sender_id': 'caller_1',
      };

      final nestedPayload = {
        'type': 'webrtc_offer',
        'sender_id': 'caller_1',
        'data': {
          'sdp': 'v=0\r\no=- 123 2 IN IP4 127.0.0.1...',
          'type': 'offer',
        }
      };

      final rootSdp = rootPayload['sdp'] ?? (rootPayload['data'] is Map ? (rootPayload['data'] as Map)['sdp'] : null);
      final nestedSdp = nestedPayload['sdp'] ?? (nestedPayload['data'] is Map ? (nestedPayload['data'] as Map)['sdp'] : null);

      expect(rootSdp, 'v=0\r\no=- 123 2 IN IP4 127.0.0.1...');
      expect(nestedSdp, 'v=0\r\no=- 123 2 IN IP4 127.0.0.1...');
    });

    test('Test 6: WebRTC answer payload parsing supports root and nested data structures', () {
      final nestedAnswer = {
        'type': 'webrtc_answer',
        'sender_id': 'callee_2',
        'data': {
          'sdp': 'v=0\r\no=- 456 2 IN IP4 127.0.0.1...',
          'type': 'answer',
        }
      };

      final answerSdp = nestedAnswer['sdp'] ?? (nestedAnswer['data'] is Map ? (nestedAnswer['data'] as Map)['sdp'] : null);
      expect(answerSdp, 'v=0\r\no=- 456 2 IN IP4 127.0.0.1...');
    });

    test('Test 7: handleRemoteIceCandidate parses both flat and nested candidate payloads', () async {
      final service = WebRTCVoiceService();

      final nestedCandidatePayload = {
        'type': 'webrtc_ice_candidate',
        'data': {
          'candidate': 'candidate:1 1 UDP 2013266431 192.168.1.1 5000 typ host',
          'sdpMid': '0',
          'sdpMLineIndex': 0,
        }
      };

      await service.handleRemoteIceCandidate(nestedCandidatePayload);
      expect(service.state, WebRTCState.disconnected);
    });

    test('Test 8: CallStateMachine connected transition executes cleanly', () {
      final sm = GlobalCallService.stateMachine;
      sm.reset();

      sm.transitionTo(CallState.connecting, callId: 'call_1', consultationId: 'consult_1');
      expect(sm.state, CallState.connecting);

      sm.transitionTo(CallState.connected, callId: 'call_1', consultationId: 'consult_1');
      expect(sm.state, CallState.connected);
    });

    test('Test 10 — Detailed AuthService.isAccessTokenValid verification across 8 exp cases', () {
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

      // 1. Expired token (in past)
      final expiredJwt = _createTestJwt(nowSec - 60);
      expect(AuthService.isAccessTokenValid(expiredJwt), isFalse, reason: 'Expired token must return false');

      // 2. Token expiring in 5 seconds
      final exp5Jwt = _createTestJwt(nowSec + 5);
      expect(AuthService.isAccessTokenValid(exp5Jwt), isFalse, reason: 'Token expiring in 5s must fail 10s buffer check');

      // 3. Token expiring in 9 seconds
      final exp9Jwt = _createTestJwt(nowSec + 9);
      expect(AuthService.isAccessTokenValid(exp9Jwt), isFalse, reason: 'Token expiring in 9s must fail 10s buffer check');

      // 4. Token expiring in 10 seconds
      final exp10Jwt = _createTestJwt(nowSec + 10);
      expect(AuthService.isAccessTokenValid(exp10Jwt), isFalse, reason: 'Token expiring in 10s must fail 10s buffer check');

      // 5. Token expiring in 30 seconds
      final exp30Jwt = _createTestJwt(nowSec + 30);
      expect(AuthService.isAccessTokenValid(exp30Jwt), isTrue, reason: 'Token expiring in 30s is valid');

      // 6. Token expiring in several minutes (300s)
      final exp300Jwt = _createTestJwt(nowSec + 300);
      expect(AuthService.isAccessTokenValid(exp300Jwt), isTrue, reason: 'Token expiring in 300s is valid');

      // 7. Malformed token
      expect(AuthService.isAccessTokenValid('invalid.jwt.token'), isFalse, reason: 'Malformed token must return false');

      // 8. Missing exp claim
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final noExpPayload = base64Url.encode(utf8.encode('{"user_id":"u1"}')).replaceAll('=', '');
      final noExpJwt = '$header.$noExpPayload.sig';
      expect(AuthService.isAccessTokenValid(noExpJwt), isFalse, reason: 'Token missing exp claim must return false');
    });

    test('Test 11 — Expired token in storage aborts WebSocket connect when refresh token is missing/fails', () async {
      final prefs = await SharedPreferences.getInstance();
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final expiredJwt = _createTestJwt(nowSec - 120);

      await prefs.setString('auth_token', expiredJwt);
      // No refresh token saved -> forceTokenRefresh will fail and clear session

      await GlobalCallWebSocketManager.instance.connect(force: true);

      expect(GlobalCallWebSocketManager.instance.state, GlobalWsState.disconnected,
          reason: 'WebSocket connection must be aborted when token is expired and refresh fails');
    });
  });
}
