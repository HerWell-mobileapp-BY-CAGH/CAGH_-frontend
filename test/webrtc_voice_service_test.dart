import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/features/consultations/data/services/webrtc_voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebRTCVoiceService Unit & State Tests', () {
    test('Initial service state and streams are properly created', () {
      final service = WebRTCVoiceService();

      expect(service.state, WebRTCState.disconnected);
      expect(service.isMuted, false);
      expect(service.isSpeakerOn, true);
      expect(service.isVideoEnabled, false);
      expect(service.isConnected, false);
      expect(service.onConnectionStateChanged, isA<Stream>());
      expect(service.onRemoteVideoStateChanged, isA<Stream<bool>>());
      expect(service.onUserJoined, isA<Stream<bool>>());
      expect(service.onError, isA<Stream<String>>());
    });

    test('Mute and speaker toggle state tracking', () async {
      final service = WebRTCVoiceService();

      await service.toggleMute(true);
      expect(service.isMuted, true);

      await service.toggleMute(false);
      expect(service.isMuted, false);

      await service.toggleSpeaker(false);
      expect(service.isSpeakerOn, false);

      await service.toggleSpeaker(true);
      expect(service.isSpeakerOn, true);
    });

    test('switchCamera handles inactive video track gracefully', () async {
      final service = WebRTCVoiceService();

      expect(service.isVideoEnabled, false);
      // Switch camera when video is disabled should return safely without throwing
      await service.switchCamera();
      expect(service.isVideoEnabled, false);
    });

    test('Remote ICE candidates queue before remote description is set', () async {
      final service = WebRTCVoiceService();

      final candidateMap = {
        'candidate': 'candidate:1 1 UDP 2013266431 192.168.1.1 5000 typ host',
        'sdpMid': 'audio',
        'sdpMLineIndex': 0,
      };

      // Candidate handling before peerConnection is created should not throw
      await service.handleRemoteIceCandidate(candidateMap);
      expect(service.state, WebRTCState.disconnected);
    });

    test('Teardown and leaveChannel executes cleanly and idempotently', () async {
      final service = WebRTCVoiceService();

      await service.leaveChannel();
      expect(service.state, WebRTCState.closed);

      // Concurrent teardown calls must be idempotent
      await Future.wait([
        service.leaveChannel(),
        service.leaveChannel(),
      ]);

      expect(service.state, WebRTCState.closed);
    });
  });
}
