import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/features/consultations/data/services/agora_voice_service.dart';

void main() {
  test('AgoraVoiceService - streams initialized properly', () {
    final service = AgoraVoiceService();

    expect(service.onUserJoined, isA<Stream<int>>());
    expect(service.onUserOffline, isA<Stream<Map<String, dynamic>>>());
    expect(service.onJoinSuccess, isA<Stream<bool>>());
    expect(service.onError, isA<Stream<String>>());
    expect(service.isJoined, false);
  });
}
