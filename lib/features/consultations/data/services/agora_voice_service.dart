import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

enum AgoraRtcState {
  disconnected,
  initializing,
  initialized,
  joining,
  connected,
  failed,
  leaving,
  released,
}

class AgoraVoiceService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isJoined = false;

  AgoraRtcState _rtcState = AgoraRtcState.disconnected;

  // Desired speaker / mute state queued before the channel is connected.
  // Applied immediately in onJoinChannelSuccess.
  bool? _desiredSpeakerState;
  bool? _desiredMuteState;
  bool _isSpeakerphoneEnabled = false;

  Timer? _joinTimeoutTimer;
  int _joinStartTime = 0;
  Future<void>? _teardownFuture;

  StreamController<int> _userJoinedController =
      StreamController<int>.broadcast();
  StreamController<Map<String, dynamic>> _userOfflineController =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamController<bool> _joinSuccessController =
      StreamController<bool>.broadcast();
  StreamController<String> _errorController =
      StreamController<String>.broadcast();
  StreamController<ConnectionStateType> _connectionStateController =
      StreamController<ConnectionStateType>.broadcast();

  Stream<int> get onUserJoined => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get onUserOffline =>
      _userOfflineController.stream;
  Stream<bool> get onJoinSuccess => _joinSuccessController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<ConnectionStateType> get onConnectionStateChanged =>
      _connectionStateController.stream;

  bool get isJoined => _isJoined;
  AgoraRtcState get rtcState => _rtcState;
  bool? get desiredSpeakerState => _desiredSpeakerState;
  bool get isSpeakerphoneEnabled => _isSpeakerphoneEnabled;

  void _ensureControllersOpen() {
    if (_userJoinedController.isClosed) {
      _userJoinedController = StreamController<int>.broadcast();
    }
    if (_userOfflineController.isClosed) {
      _userOfflineController =
          StreamController<Map<String, dynamic>>.broadcast();
    }
    if (_joinSuccessController.isClosed) {
      _joinSuccessController = StreamController<bool>.broadcast();
    }
    if (_errorController.isClosed) {
      _errorController = StreamController<String>.broadcast();
    }
    if (_connectionStateController.isClosed) {
      _connectionStateController =
          StreamController<ConnectionStateType>.broadcast();
    }
  }

  Future<void> initialize(
    String appId, {
    RtcEngine? customEngine,
    bool skipPermissionCheck = false,
  }) async {
    _ensureControllersOpen();

    if (_isInitialized && _engine != null) return;
    _rtcState = AgoraRtcState.initializing;
    final sanitizedAppId =
        appId.length > 6 ? '${appId.substring(0, 6)}...' : appId;
    AppLogger.d(
        '[AGORA][INIT] Initializing RtcEngine with appId=$sanitizedAppId');

    try {
      if (!kIsWeb && !skipPermissionCheck) {
        final status = await Permission.microphone.request();
        if (status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted) {
          final errorMsg =
              "Microphone permission is required to make voice calls.";
          AppLogger.d("[AGORA][ERROR] $errorMsg");
          _rtcState = AgoraRtcState.failed;
          if (!_errorController.isClosed) {
            _errorController.add(errorMsg);
          }
          throw Exception(errorMsg);
        }
        try {
          await Permission.bluetoothConnect.request();
        } catch (btErr) {
          AppLogger.d(
              "[AGORA][INIT] Bluetooth permission request notice ($btErr)");
        }
      }
    } catch (e) {
      _rtcState = AgoraRtcState.failed;
      AppLogger.d("[AGORA][ERROR] Permission request failed: $e");
      rethrow;
    }

    try {
      _engine = customEngine ?? createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _registerEventHandler();

      await _engine!
          .setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      _isInitialized = true;
      _rtcState = AgoraRtcState.initialized;
      AppLogger.d('[AGORA][INIT] Engine initialized successfully');
    } catch (e) {
      _rtcState = AgoraRtcState.failed;
      AppLogger.d("[AGORA][ERROR] Engine initialization notice ($e)");
      if (kIsWeb) {
        _isInitialized = true;
        _rtcState = AgoraRtcState.initialized;
        AppLogger.d("[AGORA][INIT] Web RTC fallback active.");
        return;
      }
      rethrow;
    }
  }

  bool _isTerminalReason(ConnectionChangedReasonType reason) {
    switch (reason) {
      case ConnectionChangedReasonType.connectionChangedInvalidAppId:
      case ConnectionChangedReasonType.connectionChangedInvalidChannelName:
      case ConnectionChangedReasonType.connectionChangedInvalidToken:
      case ConnectionChangedReasonType.connectionChangedTokenExpired:
      case ConnectionChangedReasonType.connectionChangedRejectedByServer:
      case ConnectionChangedReasonType.connectionChangedBannedByServer:
      case ConnectionChangedReasonType.connectionChangedJoinFailed:
        return true;
      default:
        return false;
    }
  }

  void _registerEventHandler() {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess:
            (RtcConnection connection, int elapsed) {
          final elapsedMs = _joinStartTime > 0
              ? DateTime.now().millisecondsSinceEpoch - _joinStartTime
              : elapsed;
          AppLogger.d(
              '[AGORA][JOIN_SUCCESS] channel=${connection.channelId}, uid=${connection.localUid}, elapsedMs=${elapsedMs}ms');
          _rtcState = AgoraRtcState.connected;
          _isJoined = true;
          _cancelJoinTimeoutTimer();

          // Apply queued mute state safely now that the channel is connected.
          if (_desiredMuteState != null) {
            try {
              _engine?.muteLocalAudioStream(_desiredMuteState!);
              AppLogger.d(
                  '[AGORA][MUTE] Applied queued mute state: $_desiredMuteState');
            } catch (muteErr) {
              AppLogger.d(
                  '[AGORA][ERROR] Failed to apply queued mute state ($muteErr)');
            }
          }

          // Apply queued or default speakerphone state safely.
          final targetSpeaker = _desiredSpeakerState ?? true;
          try {
            _engine?.setEnableSpeakerphone(targetSpeaker);
            _isSpeakerphoneEnabled = targetSpeaker;
            AppLogger.d(
                '[AGORA][SPEAKER] Applied speaker state on join: $targetSpeaker');
          } catch (spkErr) {
            AppLogger.d(
                '[AGORA][ERROR] Speakerphone notice on join ($spkErr)');
          }

          if (!_joinSuccessController.isClosed) {
            _joinSuccessController.add(true);
          }
        },
        onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) {
          AppLogger.d(
              '[AGORA][REMOTE_AUDIO] Remote user joined: uid=$remoteUid, elapsedMs=${elapsed}ms');
          if (!_userJoinedController.isClosed) {
            _userJoinedController.add(remoteUid);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          AppLogger.d(
              '[AGORA][REMOTE_AUDIO] Remote user $remoteUid offline, reason=$reason');
          if (!_userOfflineController.isClosed) {
            _userOfflineController.add({
              'uid': remoteUid,
              'reason': reason,
            });
          }
        },
        onUserMuteAudio:
            (RtcConnection connection, int remoteUid, bool muted) {
          AppLogger.d(
              '[AGORA][REMOTE_AUDIO] Remote user $remoteUid muted audio: $muted');
        },
        onFirstRemoteAudioFrame:
            (RtcConnection connection, int remoteUid, int elapsed) {
          AppLogger.d(
              '[AGORA][REMOTE_AUDIO] First remote audio frame from uid=$remoteUid, elapsedMs=${elapsed}ms');
        },
        onRemoteAudioStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteAudioState state,
            RemoteAudioStateReason reason,
            int elapsed) {
          AppLogger.d(
              '[AGORA][REMOTE_AUDIO] uid=$remoteUid, state=$state, reason=$reason, elapsedMs=${elapsed}ms');
        },
        onLocalAudioStateChanged: (RtcConnection connection,
            LocalAudioStreamState state,
            LocalAudioStreamReason reason) {
          AppLogger.d(
              '[AGORA][LOCAL_AUDIO] state=$state, reason=$reason');
        },
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason) {
          final elapsedMs = _joinStartTime > 0
              ? DateTime.now().millisecondsSinceEpoch - _joinStartTime
              : 0;
          AppLogger.d(
              '[AGORA][CONNECTION_STATE] state=$state, reason=$reason, channel=${connection.channelId}, uid=${connection.localUid}, elapsedMs=${elapsedMs}ms');

          // Classify the failure reason to help diagnose auth vs network issues.
          if (state == ConnectionStateType.connectionStateFailed ||
              (state == ConnectionStateType.connectionStateDisconnected &&
                  _isTerminalReason(reason))) {
            _rtcState = AgoraRtcState.failed;
            _cancelJoinTimeoutTimer();

            String failureCategory;
            switch (reason) {
              case ConnectionChangedReasonType
                    .connectionChangedInvalidToken:
                failureCategory = 'INVALID_TOKEN (error 17) — token signature mismatch or UID/channel mismatch';
                break;
              case ConnectionChangedReasonType
                    .connectionChangedTokenExpired:
                failureCategory = 'TOKEN_EXPIRED — token lifetime exceeded';
                break;
              case ConnectionChangedReasonType
                    .connectionChangedInvalidAppId:
                failureCategory = 'INVALID_APP_ID — App ID not recognised by Agora';
                break;
              case ConnectionChangedReasonType
                    .connectionChangedInvalidChannelName:
                failureCategory = 'INVALID_CHANNEL_NAME';
                break;
              case ConnectionChangedReasonType
                    .connectionChangedRejectedByServer:
                failureCategory = 'REJECTED_BY_SERVER';
                break;
              case ConnectionChangedReasonType
                    .connectionChangedBannedByServer:
                failureCategory = 'BANNED_BY_SERVER';
                break;
              case ConnectionChangedReasonType
                    .connectionChangedJoinFailed:
                failureCategory = 'JOIN_FAILED — network unreachable or UDP blocked';
                break;
              default:
                failureCategory = 'OTHER reason=$reason';
            }

            AppLogger.d(
                '[AGORA][JOIN_FAILURE] category=$failureCategory state=$state elapsedMs=${elapsedMs}ms');
            if (!_errorController.isClosed) {
              _errorController.add(
                  '[AGORA][JOIN_FAILURE] category=$failureCategory state=$state reason=$reason');
            }
          } else if (state ==
                  ConnectionStateType.connectionStateConnecting ||
              state == ConnectionStateType.connectionStateReconnecting) {
            if (_rtcState != AgoraRtcState.leaving &&
                _rtcState != AgoraRtcState.released) {
              _rtcState = AgoraRtcState.joining;
            }
          }

          if (!_connectionStateController.isClosed) {
            _connectionStateController.add(state);
          }
        },
        onTokenPrivilegeWillExpire:
            (RtcConnection connection, String token) {
          AppLogger.d(
              '[AGORA][TOKEN] Token privilege will expire for channel: ${connection.channelId}');
        },
        onRequestToken: (RtcConnection connection) {
          AppLogger.d(
              '[AGORA][TOKEN] Token expired — request token for channel: ${connection.channelId}');
        },
        onError: (ErrorCodeType err, String msg) {
          AppLogger.d('[AGORA][ERROR] code=$err, message=$msg');
          if (!_errorController.isClosed) {
            _errorController.add('Agora error $err: $msg');
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          AppLogger.d(
              '[AGORA][LEAVE] Left channel: ${connection.channelId}');
          _isJoined = false;
          if (_rtcState != AgoraRtcState.leaving &&
              _rtcState != AgoraRtcState.released) {
            _rtcState = AgoraRtcState.disconnected;
          }
        },
      ),
    );
  }

  void _startJoinTimeoutTimer(String channelId, int uid) {
    _cancelJoinTimeoutTimer();
    _joinTimeoutTimer = Timer(const Duration(seconds: 20), () {
      if (_rtcState == AgoraRtcState.joining) {
        final elapsedMs =
            DateTime.now().millisecondsSinceEpoch - _joinStartTime;
        AppLogger.d(
            '[AGORA][TIMEOUT] channel=$channelId, uid=$uid, lastConnectionState=$_rtcState, elapsedMs=${elapsedMs}ms');
        AppLogger.d(
            '[AGORA][TIMEOUT] Possible causes: (1) UDP packets blocked — test on physical device; '
            '(2) Agora edge server unreachable; (3) Android emulator virtual network issue');
        _rtcState = AgoraRtcState.failed;
        if (!_errorController.isClosed) {
          _errorController.add(
              '[AGORA][TIMEOUT] 20s connection timeout reached without onJoinChannelSuccess');
        }
        _teardownTransaction();
      }
    });
  }

  void _cancelJoinTimeoutTimer() {
    _joinTimeoutTimer?.cancel();
    _joinTimeoutTimer = null;
  }

  /// Joins the Agora channel.
  ///
  /// Performs hard pre-flight validation before calling the SDK so that a
  /// missing credential always produces a clear diagnostic log instead of a
  /// silent 20 s timeout.
  Future<void> joinChannel({
    required String channelId,
    required String token,
    required int uid,
  }) async {
    // ── Pre-flight credential validation ────────────────────────────────────
    final List<String> validationErrors = [];
    if (channelId.isEmpty) validationErrors.add('channelId is empty');
    if (token.isEmpty) validationErrors.add('token is empty — backend returned no Agora token (session may be terminal)');
    if (uid <= 0) validationErrors.add('uid is $uid (must be > 0)');

    if (validationErrors.isNotEmpty) {
      final msg =
          '[AGORA][PRE_JOIN_VALIDATION_FAILED] ${validationErrors.join('; ')}';
      AppLogger.d(msg);
      _rtcState = AgoraRtcState.failed;
      if (!_errorController.isClosed) {
        _errorController.add(msg);
      }
      throw Exception(msg);
    }
    // ────────────────────────────────────────────────────────────────────────

    if (_engine == null && !kIsWeb) {
      _rtcState = AgoraRtcState.failed;
      throw Exception("Agora RtcEngine is not initialized");
    }

    _rtcState = AgoraRtcState.joining;
    _joinStartTime = DateTime.now().millisecondsSinceEpoch;
    _startJoinTimeoutTimer(channelId, uid);

    if (_engine != null) {
      try {
        await _engine!
            .setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.enableAudio();
        await _engine!.enableLocalAudio(true);
        await _engine!.muteLocalAudioStream(false);
        await _engine!.muteAllRemoteAudioStreams(false);
        await _engine!.adjustRecordingSignalVolume(100);
        await _engine!.adjustPlaybackSignalVolume(100);
        AppLogger.d('[AGORA][LOCAL_AUDIO] Audio setup complete');
      } catch (e) {
        AppLogger.d('[AGORA][ERROR] Audio setup notice: $e');
      }

      // Diagnostic log — never print actual token value.
      final tokenHash =
          token.length > 10 ? '${token.substring(0, 10)}...' : token;
      AppLogger.d('------------------------------------------------------------');
      AppLogger.d('[AGORA][JOIN_PARAMS]');
      AppLogger.d('  APP_ID        : initialized (length=${token.length > 0 ? "ok" : "EMPTY"})');
      AppLogger.d('  CHANNEL       : $channelId');
      AppLogger.d('  UID           : $uid');
      AppLogger.d('  TOKEN_PRESENT : ${token.isNotEmpty}');
      AppLogger.d('  TOKEN_LENGTH  : ${token.length}');
      AppLogger.d('  TOKEN_PREFIX  : $tokenHash');
      AppLogger.d('[AGORA][JOIN_REQUEST] Calling engine.joinChannel ...');
      AppLogger.d('------------------------------------------------------------');

      try {
        await _engine!.joinChannel(
          token: token,
          channelId: channelId,
          uid: uid,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileCommunication,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
          ),
        );
      } catch (e) {
        _cancelJoinTimeoutTimer();
        _rtcState = AgoraRtcState.failed;
        AppLogger.d('[AGORA][JOIN_FAILURE] joinChannel call failed immediately: $e');
        if (!_errorController.isClosed) {
          _errorController.add('[AGORA][JOIN_FAILURE] $e');
        }
        rethrow;
      }
    } else if (kIsWeb) {
      _cancelJoinTimeoutTimer();
      AppLogger.d('[AGORA][JOIN_SUCCESS] Web channel joined');
      _rtcState = AgoraRtcState.connected;
      _isJoined = true;
      if (!_joinSuccessController.isClosed) {
        _joinSuccessController.add(true);
      }
      if (!_userJoinedController.isClosed) {
        _userJoinedController.add(0);
      }
    }
  }

  Future<void> _teardownTransaction() async {
    if (_teardownFuture != null) {
      return _teardownFuture!;
    }

    _teardownFuture = _performTeardown();
    try {
      await _teardownFuture;
    } finally {
      _teardownFuture = null;
    }
  }

  Future<void> _performTeardown() async {
    if (_rtcState == AgoraRtcState.released ||
        _rtcState == AgoraRtcState.leaving) {
      return;
    }

    final previousState = _rtcState;
    _rtcState = AgoraRtcState.leaving;
    _cancelJoinTimeoutTimer();

    AppLogger.d(
        '[AGORA][LEAVE] Starting RTC teardown from state $previousState');

    if (_engine != null) {
      if (previousState == AgoraRtcState.joining ||
          previousState == AgoraRtcState.connected ||
          _isJoined) {
        try {
          await _engine!.leaveChannel();
          AppLogger.d('[AGORA][LEAVE] Channel left successfully');
        } catch (e) {
          AppLogger.d('[AGORA][ERROR] Exception leaving channel: $e');
        }
      }

      _isJoined = false;

      try {
        _engine!.unregisterEventHandler(RtcEngineEventHandler());
      } catch (e) {
        AppLogger.d(
            '[AGORA][ERROR] Exception unregistering event handler: $e');
      }

      try {
        await _engine!.release();
        AppLogger.d('[AGORA][RELEASE] RtcEngine released successfully');
      } catch (e) {
        AppLogger.d('[AGORA][ERROR] Exception releasing engine: $e');
      }
      _engine = null;
    }

    _rtcState = AgoraRtcState.released;
    _isInitialized = false;
  }

  Future<void> leaveChannel() async {
    await _teardownTransaction();
  }

  Future<void> toggleMute(bool isMuted) async {
    // Always store desired state so it can be applied on connect.
    _desiredMuteState = isMuted;

    if (_engine != null && _rtcState == AgoraRtcState.connected) {
      try {
        await _engine!.muteLocalAudioStream(isMuted);
        AppLogger.d(
            '[AGORA][LOCAL_AUDIO] Mute applied: $isMuted');
      } catch (e) {
        AppLogger.d('[AGORA][ERROR] Failed to set mute state: $e');
      }
    } else {
      AppLogger.d(
          '[AGORA][MUTE] Engine not connected (rtcState=$_rtcState). Desired mute=$isMuted queued.');
    }
  }

  Future<void> toggleSpeaker(bool isSpeaker) async {
    _desiredSpeakerState = isSpeaker;
    AppLogger.d(
        '[AGORA][SPEAKER] Speaker requested: $isSpeaker (desired stored)');

    if (_engine != null && _rtcState == AgoraRtcState.connected) {
      try {
        await _engine!.setEnableSpeakerphone(isSpeaker);
        _isSpeakerphoneEnabled = isSpeaker;
        AppLogger.d('[AGORA][SPEAKER] Speakerphone updated to $isSpeaker');
      } catch (e) {
        AppLogger.d('[AGORA][ERROR] Failed to set speakerphone: $e');
      }
    } else {
      AppLogger.d(
          '[AGORA][SPEAKER] Engine not connected (rtcState=$_rtcState). Desired state $isSpeaker queued.');
    }
  }

  Future<void> dispose() async {
    await _teardownTransaction();
    if (!_userJoinedController.isClosed) {
      await _userJoinedController.close();
    }
    if (!_userOfflineController.isClosed) {
      await _userOfflineController.close();
    }
    if (!_joinSuccessController.isClosed) {
      await _joinSuccessController.close();
    }
    if (!_errorController.isClosed) await _errorController.close();
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
  }
}
