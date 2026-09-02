import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cagh_frontend/features/consultations/data/services/agora_voice_service.dart';

class FakeRtcEngine extends Fake implements RtcEngine {
  RtcEngineEventHandler? eventHandler;
  bool initializeCalled = false;
  bool leaveChannelCalled = false;
  bool releaseCalled = false;
  bool? speakerphoneEnabled;
  int setEnableSpeakerphoneCallCount = 0;
  bool throwOnSetEnableSpeakerphone = false;

  @override
  Future<void> initialize(RtcEngineContext context) async {
    initializeCalled = true;
  }

  @override
  void registerEventHandler(RtcEngineEventHandler handler) {
    eventHandler = handler;
  }

  @override
  void unregisterEventHandler(RtcEngineEventHandler handler) {
    eventHandler = null;
  }

  @override
  Future<void> setClientRole({required ClientRoleType role, ClientRoleOptions? options}) async {}

  @override
  Future<void> enableAudio() async {}

  @override
  Future<void> setAudioProfile({required AudioProfileType profile, AudioScenarioType scenario = AudioScenarioType.audioScenarioDefault}) async {}

  @override
  Future<void> setEnableSpeakerphone(bool speaker) async {
    setEnableSpeakerphoneCallCount++;
    if (throwOnSetEnableSpeakerphone) {
      throw AgoraRtcException(code: -3, message: "ERR_NOT_READY");
    }
    speakerphoneEnabled = speaker;
  }

  @override
  Future<void> enableLocalAudio(bool enabled) async {}

  @override
  Future<void> muteLocalAudioStream(bool mute) async {}

  @override
  Future<void> muteAllRemoteAudioStreams(bool mute) async {}

  @override
  Future<void> adjustRecordingSignalVolume(int volume) async {}

  @override
  Future<void> adjustPlaybackSignalVolume(int volume) async {}

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  }) async {}

  @override
  Future<void> leaveChannel({LeaveChannelOptions? options}) async {
    leaveChannelCalled = true;
  }

  @override
  Future<void> release({bool sync = false}) async {
    releaseCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AgoraVoiceService Lifecycle & Diagnostic Tests', () {
    test('Streams and initial state initialized properly', () {
      final service = AgoraVoiceService();

      expect(service.onUserJoined, isA<Stream<int>>());
      expect(service.onUserOffline, isA<Stream<Map<String, dynamic>>>());
      expect(service.onJoinSuccess, isA<Stream<bool>>());
      expect(service.onError, isA<Stream<String>>());
      expect(service.isJoined, false);
      expect(service.rtcState, AgoraRtcState.disconnected);
    });

    test('Test 1: Speaker requested while RTC is connecting retains desired state without exception', () async {
      final fakeEngine = FakeRtcEngine();
      final service = AgoraVoiceService();

      await service.initialize('test_app_id', customEngine: fakeEngine, skipPermissionCheck: true);
      await service.joinChannel(channelId: 'test_channel', token: 'test_token', uid: 12345);

      expect(service.rtcState, AgoraRtcState.joining);

      // Toggling speaker while joining should queue desired state without throwing error
      await service.toggleSpeaker(false);

      expect(service.desiredSpeakerState, false);
      expect(fakeEngine.setEnableSpeakerphoneCallCount, 0);
    });

    test('Test 2: RTC subsequently joins applies queued speaker state', () async {
      final fakeEngine = FakeRtcEngine();
      final service = AgoraVoiceService();

      await service.initialize('test_app_id', customEngine: fakeEngine, skipPermissionCheck: true);
      await service.joinChannel(channelId: 'test_channel', token: 'test_token', uid: 12345);

      await service.toggleSpeaker(false);
      expect(fakeEngine.setEnableSpeakerphoneCallCount, 0);

      // Trigger onJoinChannelSuccess
      fakeEngine.eventHandler?.onJoinChannelSuccess?.call(
        const RtcConnection(channelId: 'test_channel', localUid: 12345),
        100,
      );

      expect(service.rtcState, AgoraRtcState.connected);
      expect(fakeEngine.setEnableSpeakerphoneCallCount, 1);
      expect(fakeEngine.speakerphoneEnabled, false);
      expect(service.isSpeakerphoneEnabled, false);
    });

    test('Test 3: RTC join fails cancels timeout, emits failure event, and transitions to failed state', () async {
      final fakeEngine = FakeRtcEngine();
      final service = AgoraVoiceService();

      await service.initialize('test_app_id', customEngine: fakeEngine, skipPermissionCheck: true);
      await service.joinChannel(channelId: 'test_channel', token: 'test_token', uid: 12345);

      final errors = <String>[];
      final sub = service.onError.listen(errors.add);

      fakeEngine.eventHandler?.onConnectionStateChanged?.call(
        const RtcConnection(channelId: 'test_channel', localUid: 12345),
        ConnectionStateType.connectionStateFailed,
        ConnectionChangedReasonType.connectionChangedInvalidToken,
      );

      await Future.delayed(Duration.zero);

      expect(service.rtcState, AgoraRtcState.failed);
      expect(errors.any((e) => e.contains('[AGORA][JOIN_FAILURE]')), isTrue);
      await sub.cancel();
    });

    test('Test 4: Successful join cancels timeout and transitions state to connected', () async {
      final fakeEngine = FakeRtcEngine();
      final service = AgoraVoiceService();

      await service.initialize('test_app_id', customEngine: fakeEngine, skipPermissionCheck: true);
      await service.joinChannel(channelId: 'test_channel', token: 'test_token', uid: 12345);

      final joinSuccessFuture = service.onJoinSuccess.first;

      fakeEngine.eventHandler?.onJoinChannelSuccess?.call(
        const RtcConnection(channelId: 'test_channel', localUid: 12345),
        50,
      );

      final joinSuccessEmitted = await joinSuccessFuture;

      expect(service.rtcState, AgoraRtcState.connected);
      expect(service.isJoined, isTrue);
      expect(joinSuccessEmitted, isTrue);
    });

    test('Test 5: Repeated teardown is safe and idempotent', () async {
      final fakeEngine = FakeRtcEngine();
      final service = AgoraVoiceService();

      await service.initialize('test_app_id', customEngine: fakeEngine, skipPermissionCheck: true);
      await service.joinChannel(channelId: 'test_channel', token: 'test_token', uid: 12345);

      // Call leaveChannel and dispose concurrently / repeatedly
      await Future.wait([
        service.leaveChannel(),
        service.leaveChannel(),
        service.dispose(),
        service.dispose(),
      ]);

      expect(service.rtcState, AgoraRtcState.released);
      expect(fakeEngine.releaseCalled, isTrue);
    });
  });
}
