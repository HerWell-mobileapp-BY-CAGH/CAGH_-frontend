import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class WebrtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  WebSocketChannel? _channel;

  // Streams to notify UI
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

  final _debugController = StreamController<String>.broadcast();
  Stream<String> get debugStream => _debugController.stream;

  Future<void> connect(String wsUrlString, bool isCaller) async {
    await _initLocalStream();
    await _createPeerConnection();

    // Connect WebSocket
    final wsUrl = Uri.parse(wsUrlString);
    _channel = WebSocketChannel.connect(wsUrl);
    _debugController.add("WS Connected to $wsUrlString");

    _channel!.stream.listen((message) async {
      _debugController.add("WS RECV: $message");
      final data = jsonDecode(message);
      final eventType = data['type'] ?? data['action'];

      if (eventType == 'incoming_call_offer' && !isCaller) {
        final offer = RTCSessionDescription(data['sdp_offer'], 'offer');
        _incomingCallController.add(offer);
      } else if (eventType == 'call_answered' || eventType == 'call_answer') {
        final answer = RTCSessionDescription(data['sdp_answer'], 'answer');
        await handleRemoteAnswer(answer);
        _callAnsweredController.add(null);
      } else if (eventType == 'ice_candidate') {
        final candidateData = data['candidate'];
        if (candidateData != null) {
          final candidate = RTCIceCandidate(
            candidateData['candidate'],
            candidateData['sdpMid'],
            candidateData['sdpMLineIndex'],
          );
          await handleRemoteCandidate(candidate);
        }
      } else if (eventType == 'media_state_changed') {
        // Handle remote mute state change if needed
      } else if (eventType == 'call_ended') {
        dispose();
      }
    }, onError: (e) {
      _debugController.add("WS ERROR: $e");
    }, onDone: () {
      _debugController.add("WS CLOSED");
    });

    if (isCaller) {
      await _createOffer();
    }
  }

  Future<void> _initLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStreamController.add(_localStream);
    } catch (e) {
      debugPrint("Error getting user media: $e");
    }
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        final msg = jsonEncode({
          'action': 'ice_candidate',
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        });
        _channel?.sink.add(msg);
        _debugController.add("WS SENT: ice_candidate");
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint("Connection state changed: $state");
      _connectionStateController.add(state);
    };

    _peerConnection?.onAddStream = (MediaStream stream) {
      debugPrint("Remote stream added");
      _remoteStream = stream;
      _remoteStreamController.add(_remoteStream);
    };

    if (_localStream != null) {
      _peerConnection?.addStream(_localStream!);
    }
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null) {
      _debugController.add("Error: PeerConnection is null");
      return;
    }
    
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      final msg = jsonEncode({
        'action': 'call_offer',
        'call_type': 'VOICE',
        'sdp_offer': offer.sdp,
      });
      _channel?.sink.add(msg);
      _debugController.add("WS SENT: call_offer");
    } catch (e) {
      _debugController.add("Offer Error: $e");
      debugPrint("Error creating offer: $e");
    }
  }

  Future<void> handleRemoteOffer(RTCSessionDescription offer) async {
    await _peerConnection?.setRemoteDescription(offer);
  }

  Future<void> acceptCall(RTCSessionDescription offer) async {
    if (_peerConnection == null) return;
    
    try {
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      
      _channel?.sink.add(jsonEncode({
        'action': 'call_answer',
        'call_type': 'VOICE',
        'sdp_answer': answer.sdp,
      }));
      
      _callAnsweredController.add(null);
    } catch (e) {
      debugPrint("Error accepting call: $e");
    }
  }

  void declineCall() {
    _channel?.sink.add(jsonEncode({
      'action': 'end_call',
    }));
    dispose();
  }

  Future<void> handleRemoteAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  Future<void> handleRemoteCandidate(RTCIceCandidate candidate) async {
    await _peerConnection?.addCandidate(candidate);
  }

  void toggleMute(bool isMuted) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
    _channel?.sink.add(jsonEncode({
      'action': 'toggle_media',
      'is_muted': isMuted,
      'video_enabled': false,
    }));
  }

  Future<void> toggleSpeaker(bool useSpeaker) async {
    if (!kIsWeb) {
      Helper.setSpeakerphoneOn(useSpeaker);
    }
  }

  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.dispose();
    _channel?.sink.close();
    
    _connectionStateController.close();
    _remoteStreamController.close();
    _localStreamController.close();
    _incomingCallController.close();
    _callAnsweredController.close();
    _debugController.close();
  }
}
