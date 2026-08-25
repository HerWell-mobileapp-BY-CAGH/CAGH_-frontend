import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

class WebrtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  WebSocketChannel? _channel;
  Timer? _offerHeartbeatTimer;
  bool _isDisposed = false;
  bool _isCallAccepted = false;

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
  RTCVideoRenderer get localRenderer => _localRenderer;

  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get connectionStateStream => _connectionStateController.stream;

  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;

  final _incomingCallController = StreamController<RTCSessionDescription>.broadcast();
  Stream<RTCSessionDescription> get incomingCallStream => _incomingCallController.stream;

  final _callAnsweredController = StreamController<void>.broadcast();
  Stream<void> get callAnsweredStream => _callAnsweredController.stream;

  final _callEndedController = StreamController<void>.broadcast();
  Stream<void> get callEndedStream => _callEndedController.stream;

  final _debugController = StreamController<String>.broadcast();
  Stream<String> get debugStream => _debugController.stream;

  Future<void> connect(String wsUrlString, bool isCaller) async {
    _isDisposed = false;
    _isCallAccepted = false;

    if (!kIsWeb) {
      try {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.microphone,
          Permission.camera,
          Permission.bluetoothConnect,
          Permission.phone,
        ].request();
        
        debugPrint('Permissions requested. Microphone: ${statuses[Permission.microphone]}, Camera: ${statuses[Permission.camera]}');
      } catch (e) {
        debugPrint('Permission request error (safe to ignore if some are unavailable): $e');
      }
    }

    await _initRenderers();
    await _initLocalStream();
    await _createPeerConnection();

    _connectWebSocket(wsUrlString, isCaller);

    if (isCaller) {
      await _createOffer();
      _offerHeartbeatTimer?.cancel();
      _offerHeartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (_isCallAccepted || _isDisposed) {
          timer.cancel();
        } else {
          await _createOffer();
        }
      });
    }
  }

  Future<void> _initRenderers() async {
    try {
      await _remoteRenderer.initialize();
      await _localRenderer.initialize();
    } catch (e) {
      debugPrint('Error initializing video renderers: $e');
    }
  }

  void _connectWebSocket(String wsUrlString, bool isCaller) {
    if (_isDisposed) return;
    try {
      final wsUrl = Uri.parse(wsUrlString);
      _channel = WebSocketChannel.connect(wsUrl);
      _debugController.add('WS Connected');
      debugPrint('WebrtcService: WebSocket connected to $wsUrlString (isCaller: $isCaller)');

      _channel!.stream.listen(
        (message) async {
          try {
            debugPrint('WebrtcService RECEIVED WS MSG: $message');
            final data = jsonDecode(message);
            final eventType = (data['type'] ?? data['action'] ?? '').toString();

            if ((eventType == 'peer_joined' || eventType == 'user_joined') && isCaller && !_isCallAccepted) {
              await _createOffer();
            } else if ((eventType == 'incoming_call_offer' || eventType == 'call_offer' || eventType == 'offer') && !isCaller && !_isCallAccepted) {
              final rawSdp = (data['sdp_offer'] ?? data['sdp'] ?? data['offer'] ?? '').toString();
              if (rawSdp.isNotEmpty) {
                final offer = RTCSessionDescription(rawSdp, 'offer');
                _incomingCallController.add(offer);
              }
            } else if (eventType == 'call_answered' || eventType == 'call_answer' || eventType == 'incoming_call_answer' || eventType == 'answer') {
              _isCallAccepted = true;
              _offerHeartbeatTimer?.cancel();
              final rawSdp = (data['sdp_answer'] ?? data['sdp'] ?? data['answer'] ?? '').toString();
              if (rawSdp.isNotEmpty) {
                final answer = RTCSessionDescription(rawSdp, 'answer');
                await handleRemoteAnswer(answer);
                _connectionStateController.add(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
                _callAnsweredController.add(null);
              }
            } else if (eventType == 'ice_candidate' || eventType == 'candidate') {
              final candidateData = data['candidate'];
              if (candidateData != null && candidateData is Map) {
                final candidate = RTCIceCandidate(
                  candidateData['candidate']?.toString() ?? '',
                  candidateData['sdpMid']?.toString() ?? '',
                  candidateData['sdpMLineIndex'] is int ? candidateData['sdpMLineIndex'] : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0,
                );
                await handleRemoteCandidate(candidate);
              }
            } else if (eventType == 'call_ended' || eventType == 'end_call' || eventType == 'broadcast_call_ended' || eventType == 'decline_call') {
              _callEndedController.add(null);
              dispose();
            }
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onError: (e) {
          _debugController.add('WS ERROR: $e');
          debugPrint('WebrtcService WS Error: $e');
          if (!_isDisposed) _callEndedController.add(null);
        },
        onDone: () {
          _debugController.add('WS CLOSED');
          debugPrint('WebrtcService WS Closed');
          if (!_isDisposed) _callEndedController.add(null);
        },
      );
    } catch (e) {
      _debugController.add('WS Connection Error: $e');
      debugPrint('WebrtcService WS Connection Exception: $e');
    }
  }

  Future<void> _initLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      _localStreamController.add(_localStream);
    } catch (e) {
      debugPrint('Error getting user media: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
        {'url': 'stun:stun1.l.google.com:19302'},
        {'url': 'stun:stun2.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        final msg = jsonEncode({
          'action': 'ice_candidate',
          'type': 'ice_candidate',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        });
        _channel?.sink.add(msg);
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('WebRTC Connection state changed: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _isCallAccepted = true;
        _offerHeartbeatTimer?.cancel();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        if (!_isDisposed) _callEndedController.add(null);
      }
      _connectionStateController.add(state);
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      debugPrint('Remote track added: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteRenderer.srcObject = _remoteStream;
        _remoteRenderer.muted = false;
        _remoteStreamController.add(_remoteStream);
      }
    };

    _peerConnection?.onAddStream = (MediaStream stream) {
      debugPrint('Remote stream added: ${stream.id}');
      _remoteStream = stream;
      _remoteRenderer.srcObject = _remoteStream;
      _remoteRenderer.muted = false;
      _remoteStreamController.add(_remoteStream);
    };

    if (_localStream != null) {
      _peerConnection?.addStream(_localStream!);
    }
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null || _isDisposed || _isCallAccepted) return;

    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      final msg = jsonEncode({
        'action': 'call_offer',
        'type': 'call_offer',
        'call_type': 'VOICE',
        'sdp_offer': offer.sdp,
        'sdp': offer.sdp,
        'offer': offer.sdp,
      });
      _channel?.sink.add(msg);
      _debugController.add('WS SENT: call_offer');
      debugPrint('WebrtcService SENT call_offer');
    } catch (e) {
      debugPrint('Error creating offer: $e');
    }
  }

  Future<void> acceptCall(RTCSessionDescription offer) async {
    if (_peerConnection == null) return;

    try {
      _isCallAccepted = true;
      _offerHeartbeatTimer?.cancel();
      await _peerConnection!.setRemoteDescription(offer);
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _channel?.sink.add(jsonEncode({
        'action': 'call_answer',
        'type': 'call_answer',
        'call_type': 'VOICE',
        'sdp_answer': answer.sdp,
        'sdp': answer.sdp,
        'answer': answer.sdp,
      }));

      _connectionStateController.add(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
      _callAnsweredController.add(null);
    } catch (e) {
      debugPrint('Error accepting call: $e');
    }
  }

  Future<void> declineCall() async {
    try {
      _channel?.sink.add(jsonEncode({
        'action': 'end_call',
        'type': 'end_call',
      }));
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (_) {}
    dispose();
  }

  Future<void> handleRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection != null) {
      await _peerConnection!.setRemoteDescription(answer);
    }
  }

  Future<void> handleRemoteCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null) {
      await _peerConnection!.addCandidate(candidate);
    }
  }

  void toggleMute(bool isMuted) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
    _channel?.sink.add(jsonEncode({
      'action': 'toggle_media',
      'type': 'toggle_media',
      'is_muted': isMuted,
      'video_enabled': false,
    }));
  }

  Future<void> toggleSpeaker(bool useSpeaker) async {
    try {
      _remoteRenderer.muted = false;
      if (kIsWeb) {
        if (_remoteStream != null) {
          for (var track in _remoteStream!.getAudioTracks()) {
            track.enabled = true;
          }
        }
      } else {
        await Helper.setSpeakerphoneOn(useSpeaker);
      }
      debugPrint('WebrtcService: Speaker route set to useSpeaker=$useSpeaker (earpiece when false)');
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _offerHeartbeatTimer?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteRenderer.srcObject = null;
    _remoteRenderer.dispose();
    _localRenderer.srcObject = null;
    _localRenderer.dispose();
    _peerConnection?.dispose();
    _channel?.sink.close();

    _connectionStateController.close();
    _remoteStreamController.close();
    _localStreamController.close();
    _incomingCallController.close();
    _callAnsweredController.close();
    _callEndedController.close();
    _debugController.close();
  }
}
