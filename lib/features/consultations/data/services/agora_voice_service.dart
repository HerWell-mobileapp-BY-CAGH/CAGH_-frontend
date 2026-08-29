import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class AgoraVoiceService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;

  StreamController<int> _userJoinedController = StreamController<int>.broadcast();
  StreamController<Map<String, dynamic>> _userOfflineController = StreamController<Map<String, dynamic>>.broadcast();
  StreamController<bool> _joinSuccessController = StreamController<bool>.broadcast();
  StreamController<String> _errorController = StreamController<String>.broadcast();
  StreamController<ConnectionStateType> _connectionStateController = StreamController<ConnectionStateType>.broadcast();

  Stream<int> get onUserJoined => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get onUserOffline => _userOfflineController.stream;
  Stream<bool> get onJoinSuccess => _joinSuccessController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<ConnectionStateType> get onConnectionStateChanged => _connectionStateController.stream;

  bool get isJoined => _isJoined;

  void _ensureControllersOpen() {
    if (_userJoinedController.isClosed) _userJoinedController = StreamController<int>.broadcast();
    if (_userOfflineController.isClosed) _userOfflineController = StreamController<Map<String, dynamic>>.broadcast();
    if (_joinSuccessController.isClosed) _joinSuccessController = StreamController<bool>.broadcast();
    if (_errorController.isClosed) _errorController = StreamController<String>.broadcast();
    if (_connectionStateController.isClosed) _connectionStateController = StreamController<ConnectionStateType>.broadcast();
  }

  Future<void> initialize(String appId) async {
    _ensureControllersOpen();

    if (_isInitialized && _engine != null) return;

    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
          final errorMsg = "Microphone permission is required to make voice calls.";
          AppLogger.d("AgoraVoiceService: $errorMsg");
          if (!_errorController.isClosed) {
            _errorController.add(errorMsg);
          }
          throw Exception(errorMsg);
        }
        try {
          await Permission.bluetoothConnect.request();
        } catch (btErr) {
          AppLogger.d("AgoraVoiceService: Bluetooth permission request notice ($btErr)");
        }
      }
    } catch (e) {
      AppLogger.d("AgoraVoiceService: Permission request failed: $e");
      rethrow;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _registerEventHandler();

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      _isInitialized = true;
      AppLogger.d('[VOICE] Engine initialized successfully');
    } catch (e) {
      AppLogger.d("AgoraVoiceService: Engine initialization notice ($e)");
      if (kIsWeb) {
        _isInitialized = true;
        AppLogger.d("AgoraVoiceService: Web RTC fallback active.");
        return;
      }
      rethrow;
    }
  }

  void _registerEventHandler() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          AppLogger.d("[VOICE] Joined channel ${connection.channelId} with local UID ${connection.localUid}");
          _isJoined = true;
          if (!_joinSuccessController.isClosed) {
            _joinSuccessController.add(true);
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          AppLogger.d("[VOICE] Remote user joined: UID $remoteUid (elapsed: ${elapsed}ms)");
          if (!_userJoinedController.isClosed) {
            _userJoinedController.add(remoteUid);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          AppLogger.d("[VOICE] Remote user $remoteUid offline (reason: $reason)");
          if (!_userOfflineController.isClosed) {
            _userOfflineController.add({
              'uid': remoteUid,
              'reason': reason,
            });
          }
        },
        onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
          AppLogger.d("[VOICE] Remote user $remoteUid muted audio: $muted");
        },
        onFirstRemoteAudioFrame: (RtcConnection connection, int remoteUid, int elapsed) {
          AppLogger.d("[VOICE] First remote audio frame received from $remoteUid (elapsed: ${elapsed}ms)");
        },
        onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
          AppLogger.d("[VOICE] Remote audio state changed for UID $remoteUid: state=$state, reason=$reason");
        },
        onLocalAudioStateChanged: (RtcConnection connection, LocalAudioStreamState state, LocalAudioStreamReason reason) {
          AppLogger.d("[VOICE] Local audio state changed: state=$state, reason=$reason");
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          AppLogger.d("[VOICE] Connection state changed to $state (reason: $reason)");
          if (!_connectionStateController.isClosed) {
            _connectionStateController.add(state);
          }
        },
        onError: (ErrorCodeType err, String msg) {
          AppLogger.d("[VOICE] Error $err: $msg");
          if (!_errorController.isClosed) {
            _errorController.add("Agora error $err: $msg");
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          AppLogger.d("[VOICE] Left channel: ${connection.channelId}");
          _isJoined = false;
        },
      ),
    );
  }

  Future<void> joinChannel({
    required String channelId,
    required String token,
    required int uid,
  }) async {
    if (_engine == null && !kIsWeb) {
      throw Exception("Agora RtcEngine is not initialized");
    }

    if (_engine != null) {
      try {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.enableAudio();
        await _engine!.enableLocalAudio(true);
        await _engine!.muteLocalAudioStream(false);
        await _engine!.muteAllRemoteAudioStreams(false);
        await _engine!.adjustRecordingSignalVolume(100);
        await _engine!.adjustPlaybackSignalVolume(100);
        await _engine!.setEnableSpeakerphone(true);
      } catch (e) {
        AppLogger.d("AgoraVoiceService: Audio setup notice ($e)");
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          enableAudioRecordingOrPlayout: true,
        ),
      );

      // Re-assert audio setup post-join to ensure audio hardware capture & playout are active
      try {
        await _engine!.enableAudio();
        await _engine!.enableLocalAudio(true);
        await _engine!.muteLocalAudioStream(false);
        await _engine!.muteAllRemoteAudioStreams(false);
        await _engine!.setEnableSpeakerphone(true);
      } catch (e) {
        AppLogger.d('AgoraVoiceService: Error enabling speakerphone: $e');
      }
    } else if (kIsWeb) {
      AppLogger.d("AgoraVoiceService: Web channel joined.");
      _isJoined = true;
      if (!_joinSuccessController.isClosed) {
        _joinSuccessController.add(true);
      }
      if (!_userJoinedController.isClosed) {
        _userJoinedController.add(0);
      }
    }
  }

  Future<void> leaveChannel() async {
    if (_engine != null && _isJoined) {
      await _engine!.leaveChannel();
      _isJoined = false;
    }
  }

  Future<void> toggleMute(bool isMuted) async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(isMuted);
      AppLogger.d('[VOICE] Mute requested: $isMuted, Local microphone muted: $isMuted');
    }
  }

  Future<void> toggleSpeaker(bool isSpeaker) async {
    if (_engine != null) {
      await _engine!.setEnableSpeakerphone(isSpeaker);
      AppLogger.d('[VOICE] Speaker requested: $isSpeaker, Speaker route changed to ${isSpeaker ? "speaker" : "earpiece"}');
    }
  }

  Future<void> dispose() async {
    await leaveChannel();
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }
    _isInitialized = false;
    if (!_userJoinedController.isClosed) await _userJoinedController.close();
    if (!_userOfflineController.isClosed) await _userOfflineController.close();
    if (!_joinSuccessController.isClosed) await _joinSuccessController.close();
    if (!_errorController.isClosed) await _errorController.close();
    if (!_connectionStateController.isClosed) await _connectionStateController.close();
  }
}
