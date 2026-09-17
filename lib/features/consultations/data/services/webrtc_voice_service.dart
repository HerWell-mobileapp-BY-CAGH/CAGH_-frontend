import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

enum WebRTCState {
  disconnected,
  initializing,
  initialized,
  connecting,
  connected,
  failed,
  closed,
}

typedef SignalSenderCallback = void Function(Map<String, dynamic> payload);

class WebRTCVoiceService {
  static final WebRTCVoiceService _instance = WebRTCVoiceService._internal();
  factory WebRTCVoiceService() => _instance;
  WebRTCVoiceService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  MediaStreamTrack? _localAudioTrack;
  MediaStreamTrack? _localVideoTrack;
  RTCRtpSender? _videoSender;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool _isRenderersInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoEnabled = false;
  bool _isCaller = false;
  bool _remoteDescriptionSet = false;
  String? _remoteUserId;

  // --- Perfect-negotiation state ---
  // A stable local identity used to deterministically decide who is the
  // "polite" peer when both sides produce an offer at the same time.
  // The polite peer rolls back its own offer and accepts the incoming one;
  // the impolite peer ignores the incoming offer and keeps its own.
  String? _localUserId;
  bool get _isPolite {
    final local = _localUserId ?? '';
    final remote = _remoteUserId ?? '';
    // Deterministic, symmetric on both ends as long as both sides know
    // each other's IDs. Lower ID => polite.
    return local.compareTo(remote) < 0;
  }

  bool _makingOffer = false; // true while createOffer/setLocalDescription is in flight
  bool _ignoreOffer = false; // set when an impolite peer drops a colliding offer
  bool _renegotiating = false; // guards toggleCamera / manual renegotiation re-entrancy

  WebRTCState _state = WebRTCState.disconnected;

  // Queued remote ICE candidates that arrive before remote description is set
  final List<RTCIceCandidate> _queuedRemoteIceCandidates = [];

  // Local ICE candidates buffered for batched (coalesced) signaling.
  // The backend delivers each WS frame with multi-second latency, so sending
  // one frame per candidate would stretch candidate exchange past the ICE
  // patience window. We batch them and flush in a single frame.
  final List<Map<String, dynamic>> _pendingLocalIceCandidates = [];
  Timer? _iceFlushTimer;
  bool _iceFlushInFlight = false;
  String _activeConsultationId = '';
  String _activeCallId = '';
  Completer<void>? _gatheringCompleter;
  Completer<void>? _pcInitCompleter;
  bool _awaitingSdpEmbed = false;

  // Callback to broadcast WebRTC signaling over Django Channels WebSocket
  SignalSenderCallback? _signalSender;

  // Streams for UI updates
  StreamController<RTCPeerConnectionState> _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  StreamController<bool> _remoteVideoStateController =
      StreamController<bool>.broadcast();
  StreamController<bool> _userJoinedController =
      StreamController<bool>.broadcast();
  StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<RTCPeerConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;
  Stream<bool> get onRemoteVideoStateChanged =>
      _remoteVideoStateController.stream;
  Stream<bool> get onUserJoined => _userJoinedController.stream;
  Stream<String> get onError => _errorController.stream;

  WebRTCState get state => _state;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isConnected => _state == WebRTCState.connected;
  bool get hasPeerConnection => _peerConnection != null;
  bool get remoteDescriptionSet => _remoteDescriptionSet;
  String? get remoteUserId => _remoteUserId;

  void setRemoteUserId(String? id) {
    if (id != null && id.isNotEmpty && id != 'null') {
      _remoteUserId = id;
    }
  }

  /// Must be called (or passed into [createPeerConnectionAndStartSession])
  /// so glare resolution has a stable, symmetric tiebreaker on both ends.
  void setLocalUserId(String? id) {
    if (id != null && id.isNotEmpty && id != 'null') {
      _localUserId = id;
    }
  }

  void setSignalSender(SignalSenderCallback sender) {
    _signalSender = sender;
  }

  void _ensureControllersOpen() {
    if (_connectionStateController.isClosed) {
      _connectionStateController =
          StreamController<RTCPeerConnectionState>.broadcast();
    }
    if (_remoteVideoStateController.isClosed) {
      _remoteVideoStateController = StreamController<bool>.broadcast();
    }
    if (_userJoinedController.isClosed) {
      _userJoinedController = StreamController<bool>.broadcast();
    }
    if (_errorController.isClosed) {
      _errorController = StreamController<String>.broadcast();
    }
  }

  Future<void> initializeRenderers() async {
    if (_isRenderersInitialized) return;
    _ensureControllersOpen();
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _isRenderersInitialized = true;
      AppLogger.d('[WEBRTC][INIT] Video renderers initialized successfully.');
    } catch (e) {
      AppLogger.d('[WEBRTC][ERROR] Failed to initialize renderers: $e');
      rethrow;
    }
  }

  /// Resets all per-call mutable state. Because this class is a singleton,
  /// values like mute/speaker/video flags, the remote user id, and the
  /// video sender reference from a *previous* call would otherwise leak
  /// into the next call (e.g. "next call silently starts muted").
  void _resetSessionState({String? remoteUserId}) {
    _isMuted = false;
    _isSpeakerOn = true;
    _isVideoEnabled = false;
    _isCaller = false;
    _remoteDescriptionSet = false;
    _makingOffer = false;
    _ignoreOffer = false;
    _renegotiating = false;
    _videoSender = null;
    _localVideoTrack = null;
    _localAudioTrack = null;
    _remoteUserId = null;
    _queuedRemoteIceCandidates.clear();
    _pendingLocalIceCandidates.clear();
    _iceFlushTimer?.cancel();
    _iceFlushTimer = null;
    _iceFlushInFlight = false;
    _gatheringCompleter = null;
    _awaitingSdpEmbed = false;
    if (remoteUserId != null && remoteUserId.isNotEmpty && remoteUserId != 'null') {
      _remoteUserId = remoteUserId;
    }
  }

  /// Flushes buffered local ICE candidates in a single batched signal frame.
  /// The backend relays each WS frame with multi-second latency, so batching
  /// all candidates into one frame is critical for ICE to complete quickly.
  void _flushLocalIceCandidates() {
    _iceFlushTimer?.cancel();
    _iceFlushTimer = null;
    if (_awaitingSdpEmbed) return;
    if (_pendingLocalIceCandidates.isEmpty || _iceFlushInFlight) return;
    if (_peerConnection == null || _signalSender == null) {
      _pendingLocalIceCandidates.clear();
      return;
    }
    _iceFlushInFlight = true;
    final batch = List<Map<String, dynamic>>.from(_pendingLocalIceCandidates);
    _pendingLocalIceCandidates.clear();
    AppLogger.d(
        '[WEBRTC][ICE] Flushing ${batch.length} local ICE candidates in one batched signal.');
    _signalSender!({
      'type': 'webrtc_ice_candidate',
      'action': 'webrtc_ice_candidate',
      'consultation_id': _activeConsultationId,
      'call_id': _activeCallId,
      'recipient_id': _remoteUserId,
      'receiver_id': _remoteUserId,
      'recipient': _remoteUserId,
      'receiver': _remoteUserId,
      'data': {'candidates': batch},
    });
    // If gathering completes while candidates are still arriving (rare), allow
    // a second (partial) batch rather than silently dropping the tail.
    _iceFlushInFlight = false;
  }

  /// Waits for ICE gathering to complete (or a timeout) so that all local
  /// candidates can be embedded directly into the offer/answer SDP.
  /// This avoids the multi-second per-frame signaling latency of the backend
  /// by requiring only ONE signaling frame per direction.
  Future<void> _waitForGatheringCompleteOrTimeout({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (_gatheringCompleter != null && !_gatheringCompleter!.isCompleted) {
      _gatheringCompleter!.complete();
    }
    _gatheringCompleter = Completer<void>();
    try {
      await _gatheringCompleter!.future.timeout(timeout);
      AppLogger.d('[WEBRTC][ICE] ICE gathering completed; embedding candidates in SDP.');
    } catch (_) {
      AppLogger.d(
          '[WEBRTC][ICE] Timed out waiting for ICE gathering; sending SDP with ${_pendingLocalIceCandidates.length} gathered candidates.');
    } finally {
      _gatheringCompleter = null;
    }
  }

  /// Returns the best SDP to signal after ICE gathering has had a chance to run.
  ///
  /// The backend delivers each WS frame with multi-second latency, so we want
  /// ONE frame per direction carrying the full candidate set. Reading the
  /// LIVE `localDescription` AFTER gathering yields a SDP that natively
  /// contains every gathered `a=candidate:` line in a valid format — for BOTH
  /// offers and answers. libwebrtc updates the local description's SDP as
  /// candidates are gathered, so no regeneration is required.
  ///
  /// NOTE: REGENERATING via createOffer/createAnswer only works for offers
  /// (createOffer is callable from `have-local-offer`, but createAnswer throws
  /// `WEBRTC_CREATE_ANSWER_ERROR` once signaling is `stable`, i.e. after the
  /// first answer was already set as local description), so it is only used as
  /// an emergency fallback. Manual string injection of `a=candidate:` lines
  /// into a pre-gathering SDP is deliberately NOT used (it produced malformed
  /// SDPs in production: `WEBRTC_SET_REMOTE_DESCRIPTION_ERROR:
  /// SessionDescription is NULL`).
  Future<String> _sdpWithNativeCandidates({
    required String fallbackSdp,
    required bool answer,
  }) async {
    final live = await _peerConnection?.getLocalDescription();
    final liveSdp = live?.sdp;
    if (liveSdp != null && liveSdp.isNotEmpty && liveSdp.contains('a=candidate:')) {
      final count = RegExp('a=candidate:').allMatches(liveSdp).length;
      AppLogger.d(
          '[WEBRTC][ICE] SDP read natively after gathering with $count candidate line(s).');
      return liveSdp;
    }
    AppLogger.d('[WEBRTC][ICE] Live local description had no candidates; trying regeneration...');
    try {
      final desc = answer
          ? await _peerConnection?.createAnswer()
          : await _peerConnection?.createOffer();
      final sdp = desc?.sdp;
      if (sdp != null && sdp.isNotEmpty && sdp.contains('a=candidate:')) {
        final count = RegExp('a=candidate:').allMatches(sdp).length;
        AppLogger.d(
            '[WEBRTC][ICE] SDP regenerated natively with $count candidate line(s).');
        return sdp;
      }
      AppLogger.d('[WEBRTC][ICE] Regenerated SDP had no candidates; using fallback SDP.');
    } catch (e) {
      AppLogger.d('[WEBRTC][ICE] SDP regeneration failed, using fallback SDP: $e');
    }
    return fallbackSdp;
  }

  Future<void> createPeerConnectionAndStartSession({
    required String consultationId,
    required String callId,
    required bool isCaller,
    String? remoteUserId,
    String? localUserId,
    List<Map<String, dynamic>>? iceServersConfig,
  }) async {
    _ensureControllersOpen();
    if (_pcInitCompleter != null && !_pcInitCompleter!.isCompleted) {
      _pcInitCompleter!.complete();
    }
    _pcInitCompleter = Completer<void>();
    if (localUserId != null) setLocalUserId(localUserId);
    _resetSessionState(remoteUserId: remoteUserId);
    _isCaller = isCaller;
    _activeConsultationId = consultationId;
    _activeCallId = callId;
    _state = WebRTCState.initializing;

    AppLogger.d(
        '[WEBRTC][START] Starting WebRTC session. consultationId=$consultationId, callId=$callId, isCaller=$isCaller, recipient=$_remoteUserId, local=$_localUserId');

    try {
      // 1. Request microphone permissions
      AppLogger.d('[WEBRTC AUDIO V5] initializing microphone');
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          final err = 'Microphone permission is required for voice calls.';
          AppLogger.d('[WEBRTC AUDIO V5] microphone permission failed: $status');
          AppLogger.d('[WEBRTC][ERROR] $err');
          _state = WebRTCState.failed;
          _errorController.add(err);
          throw Exception(err);
        }
      }
      AppLogger.d('[WEBRTC AUDIO V5] microphone initialized');

      // Initialize renderers
      await initializeRenderers();

      // 2. STUN / TURN Configuration
      final List<Map<String, dynamic>> defaultIceServers = [
        {'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']},
      ];

      final List<Map<String, dynamic>> turnFallbackIceServers = [
        {
          'urls': [
            'turn:global.relay.metered.ca:80',
            'turn:global.relay.metered.ca:80?transport=tcp',
            'turn:global.relay.metered.ca:443',
            'turns:global.relay.metered.ca:443?transport=tcp',
          ],
          'username': '3cf2f9b46283552b03c57a5e',
          'credential': '0VS2ZJ6Y/utZNKkE',
        },
      ];

      final List<Map<String, dynamic>> effectiveIceServers =
          List<Map<String, dynamic>>.from(iceServersConfig ?? defaultIceServers);
      var hasTurn = false;
      for (final server in effectiveIceServers) {
        final urls = server['urls'];
        if (urls is String && (urls.startsWith('turn:') || urls.startsWith('turns:'))) {
          hasTurn = true;
          break;
        }
        if (urls is List && urls.any((u) {
          final s = u.toString();
          return s.startsWith('turn:') || s.startsWith('turns:');
        })) {
          hasTurn = true;
          break;
        }
      }
      if (!hasTurn) {
        effectiveIceServers.addAll(turnFallbackIceServers);
        hasTurn = true;
        AppLogger.d('[WEBRTC][ICE] No TURN server supplied by backend; appended fallback relay.');
      }
      AppLogger.d('[WEBRTC][ICE] Using ${effectiveIceServers.length} ICE server entries (turn=$hasTurn).');

      final Map<String, dynamic> configuration = {
        'iceServers': effectiveIceServers,
        'sdpSemantics': 'unified-plan',
      };

      final Map<String, dynamic> constraints = {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      };

      _peerConnection = await createPeerConnection(configuration, constraints);
      _state = WebRTCState.connecting;
      _state = WebRTCState.initialized;
      AppLogger.d('[CALL CONNECT V6] PeerConnection created');
      AppLogger.d('[WEBRTC STATE V5] peer connection created=true');
      AppLogger.d('[WEBRTC][PC] PeerConnection created successfully.');

      // 3. Register PeerConnection Event Listeners
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) {
          return;
        }
        AppLogger.d('[CALL CONNECT V6] ICE candidate generated');
        AppLogger.d('[WEBRTC CONNECTION V5] local candidate: ${candidate.candidate}');
        AppLogger.d(
            '[WEBRTC][ICE] Local ICE candidate generated: ${candidate.candidate!.substring(0, candidate.candidate!.length > 30 ? 30 : candidate.candidate!.length)}... (recipient=$_remoteUserId)');
        _pendingLocalIceCandidates.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
        _iceFlushTimer?.cancel();
        _iceFlushTimer = Timer(const Duration(milliseconds: 350), _flushLocalIceCandidates);
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        AppLogger.d('[CALL CONNECT V6] connection state=$state');
        AppLogger.d('[WEBRTC CONNECTION V5] connectionState=$state');
        AppLogger.d('[WEBRTC FLOW V3] event=onConnectionState call_id=$callId state=$state');
        AppLogger.d('[WEBRTC_CONNECTION_STATE] Connection state changed: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _state = WebRTCState.connected;
          AppLogger.d('[CALL CONNECT V6] CONNECTED');
          _userJoinedController.add(true);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          AppLogger.d('[WEBRTC FAILURE V3] connection_state=$state triggering failure handler');
          _state = WebRTCState.failed;
        }
        _connectionStateController.add(state);
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) async {
        AppLogger.d('[CALL CONNECT V6] ICE state=$state');
        AppLogger.d('[WEBRTC CONNECTION V5] iceConnectionState=$state');
        AppLogger.d('[WEBRTC FLOW V3] event=onIceConnectionState call_id=$callId state=$state');
        AppLogger.d('[WEBRTC_ICE_CONNECTION_STATE] ICE connection state changed: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          _state = WebRTCState.connected;
          AppLogger.d('[CALL CONNECT V6] CONNECTED');
          _userJoinedController.add(true);
          _connectionStateController.add(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          // Keep one endpoint responsible for recovery. If both peers create
          // restart offers at once, they can collide and leave the call with
          // a valid UI state but no media path.
          if (!_isCaller) {
            AppLogger.d('[WEBRTC][ICE] Callee observed failed ICE; waiting for caller restart offer.');
            return;
          }
          AppLogger.d('[WEBRTC FAILURE V3] ice_state=$state triggering ICE restart');
          AppLogger.d('[WEBRTC][ICE] Connection failed, attempting ICE restart...');
          _connectionStateController.add(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
          final recovered = await _attemptIceRestart(
            consultationId: consultationId,
            callId: callId,
          );
          if (!recovered) {
            _state = WebRTCState.failed;
          }
        }
      };

      _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
        AppLogger.d('[WEBRTC CONNECTION V5] iceGatheringState=$state');
        AppLogger.d('[WEBRTC FLOW V3] event=onIceGatheringState call_id=$callId state=$state');
        AppLogger.d('[WEBRTC_ICE_GATHERING_STATE] Gathering state changed: $state');
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          _iceFlushTimer?.cancel();
          if (_gatheringCompleter != null && !_gatheringCompleter!.isCompleted) {
            _gatheringCompleter!.complete();
          }
          if (!_awaitingSdpEmbed) {
            _flushLocalIceCandidates();
          }
        }
      };

      _peerConnection!.onSignalingState = (RTCSignalingState state) {
        AppLogger.d('[WEBRTC CONNECTION V5] signalingState=$state');
        AppLogger.d('[WEBRTC FLOW V3] event=onSignalingState call_id=$callId state=$state');
        AppLogger.d('[WEBRTC_SIGNALLING_STATE] Signaling state changed: $state');
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) async {
        AppLogger.d('[WEBRTC AUDIO V5] remote audio track received kind=${event.track.kind} enabled=${event.track.enabled}');
        AppLogger.d(
            '[WEBRTC_REMOTE_AUDIO_TRACK_RECEIVED] Remote track received: kind=${event.track.kind}, streams=${event.streams.length}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          AppLogger.d('[WEBRTC AUDIO V5] remote stream received stream_id=${_remoteStream!.id}');
        } else {
          _remoteStream ??= await createLocalMediaStream('remote_stream_${event.track.kind}');
          _remoteStream!.addTrack(event.track);
          AppLogger.d('[WEBRTC AUDIO V5] remote stream created for track');
        }
        remoteRenderer.srcObject = _remoteStream;
        AppLogger.d('[WEBRTC AUDIO V5] remote audio track enabled=${event.track.enabled}');
        AppLogger.d('[WEBRTC AUDIO V5] remote audio playback initialized');
        AppLogger.d('[WEBRTC_REMOTE_STREAM_ATTACHED] Remote stream attached for track kind=${event.track.kind}');
        if (event.track.kind == 'video') {
          _remoteVideoStateController.add(true);
        }
      };

      _peerConnection!.onRemoveTrack = (MediaStream stream, MediaStreamTrack track) {
        AppLogger.d('[WEBRTC][TRACK] Remote track removed: kind=${track.kind}');
        if (track.kind == 'video') {
          _remoteVideoStateController.add(false);
        }
      };

      // 4. Create Local Media Stream (Audio Only)
      AppLogger.d('[WEBRTC_MEDIA_INIT_STARTED] Initializing local media...');
      _localStream = await createLocalMediaStream('cagh_local_stream');
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false,
      };

      AppLogger.d('[WEBRTC_GET_USER_MEDIA_REQUESTED] Requesting getUserMedia audio...');
      final MediaStream userStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      AppLogger.d('[WEBRTC_GET_USER_MEDIA_SUCCESS] Local media stream acquired. ID=${userStream.id}');

      _localAudioTrack = userStream.getAudioTracks().first;
      _localAudioTrack!.enabled = !_isMuted;
      _localStream!.addTrack(_localAudioTrack!);
      AppLogger.d('[WEBRTC AUDIO V5] local audio track created');
      AppLogger.d('[WEBRTC_LOCAL_AUDIO_TRACK_CREATED] Local audio track created (audio tracks=${userStream.getAudioTracks().length}).');

      await _peerConnection!.addTrack(_localAudioTrack!, _localStream!);
      AppLogger.d('[WEBRTC AUDIO V5] local audio track added');
      AppLogger.d('[WEBRTC AUDIO V5] local audio enabled=${_localAudioTrack!.enabled}');
      AppLogger.d('[WEBRTC_LOCAL_AUDIO_TRACK_ADDED] Local audio track added to PeerConnection.');

      final senders = await _peerConnection!.getSenders();
      final hasAudioSender = senders.any((s) => s.track?.kind == 'audio');
      final hasVideoSender = senders.any((s) => s.track?.kind == 'video');
      AppLogger.d('[WEBRTC_SENDERS] audio=$hasAudioSender video=$hasVideoSender total=${senders.length}');

      // Default audio routing: speaker
      await toggleSpeaker(_isSpeakerOn);
    } catch (e) {
      AppLogger.d('[WEBRTC][ERROR] Failed to start WebRTC session: $e');
      _state = WebRTCState.failed;
      _errorController.add('WebRTC session error: $e');
      rethrow;
    } finally {
      if (_pcInitCompleter != null && !_pcInitCompleter!.isCompleted) {
        _pcInitCompleter!.complete();
      }
    }
  }

  Future<bool> createAndSendOffer({
    required String consultationId,
    required String callId,
    String? remoteUserId,
    bool iceRestart = false,
  }) async {
    if (remoteUserId != null && remoteUserId.isNotEmpty && remoteUserId != 'null') {
      _remoteUserId = remoteUserId;
    }
    AppLogger.d('[WEBRTC_TRACE_05_CREATE_AND_SEND_OFFER_ENTERED] call_id=$callId recipient=$_remoteUserId');
    final pcExists = _peerConnection != null;
    // flutter_webrtc's Android implementation throws when queried before a
    // local description has ever been set; this is the normal state before
    // the initial offer. Treat that as "no local description", not a call
    // failure.
    var localDescExists = false;
    if (_peerConnection != null) {
      try {
        localDescExists = (await _peerConnection!.getLocalDescription()) != null;
      } catch (_) {
        localDescExists = false;
      }
    }
    final remoteDescExists = _remoteDescriptionSet;
    AppLogger.d('[WEBRTC STATE V5] peer connection exists=$pcExists');
    AppLogger.d('[WEBRTC STATE V5] local description exists=$localDescExists');
    AppLogger.d('[WEBRTC STATE V5] remote description exists=$remoteDescExists');

    if (!pcExists) {
      AppLogger.d('[CALL CONNECT V6] FAILED step=createAndSendOffer error=PeerConnection is null stack=${StackTrace.current}');
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=createAndSendOffer call_id=$callId error=PeerConnection is null');
      return false;
    }

    final localStreamExists = _localStream != null;
    final audioTrackExists = _localAudioTrack != null;
    final audioTrackEnabled = _localAudioTrack?.enabled ?? false;
    AppLogger.d('[WEBRTC_TRACE_07_LOCAL_MEDIA_STATE] call_id=$callId local_stream_exists=$localStreamExists audio_track_exists=$audioTrackExists audio_track_enabled=$audioTrackEnabled');

    try {
      _makingOffer = true;
      AppLogger.d('[WEBRTC_TRACE_08_CREATE_OFFER_START] call_id=$callId');
      AppLogger.d('[WEBRTC_OFFER_CREATION_STARTED] Creating SDP offer for call_id=$callId...');

      final Map<String, dynamic> offerConstraints = iceRestart
          ? {'iceRestart': true}
          : {};

      final RTCSessionDescription description =
          await _peerConnection!.createOffer(offerConstraints);
      final sdpPresent = description.sdp != null && description.sdp!.isNotEmpty;
      AppLogger.d('[WEBRTC_TRACE_09_CREATE_OFFER_SUCCESS] call_id=$callId sdp_present=$sdpPresent');
      AppLogger.d('[WEBRTC_OFFER_CREATED] Local SDP offer created successfully.');

      try {
        await _peerConnection!.setLocalDescription(description);
        AppLogger.d('[CALL CONNECT V6] setLocalDescription SUCCESS');
        AppLogger.d('[WEBRTC_TRACE_10_LOCAL_DESCRIPTION_SET] call_id=$callId');
        AppLogger.d('[WEBRTC_LOCAL_DESCRIPTION_SET] Local description (Offer) set successfully.');
      } catch (e, stack) {
        AppLogger.d('[CALL CONNECT V6] FAILED step=setLocalDescription_offer error=$e stack=$stack');
        AppLogger.d('[WEBRTC_TRACE_ERROR] stage=setLocalDescription_offer call_id=$callId error=$e');
        AppLogger.d('[WEBRTC_LOCAL_DESCRIPTION_FAILED] Failed to set local description (Offer): $e');
        rethrow;
      }

      // Wait briefly for ICE gathering so all local candidates can ride in the
      // offer SDP itself (non-trickle). The backend delivers each WS frame with
      // multi-second latency, so a single SDP frame beats N candidate frames.
      _awaitingSdpEmbed = true;
      await _waitForGatheringCompleteOrTimeout();
      _awaitingSdpEmbed = false;
      final finalSdp = await _sdpWithNativeCandidates(
        fallbackSdp: description.sdp ?? '',
        answer: false,
      );
      AppLogger.d('[WEBRTC][ICE] Offer SDP ready; sending single offer frame (${_pendingLocalIceCandidates.length} candidate(s) buffered as backup).');

      if (_signalSender != null) {
        AppLogger.d('[WEBRTC_OFFER_SEND_STARTED] Sending webrtc_offer via signal sender (recipient=$_remoteUserId)...');
        _signalSender!({
          'type': 'webrtc_offer',
          'action': 'webrtc_offer',
          'consultation_id': consultationId,
          'call_id': callId,
          'recipient_id': _remoteUserId,
          'receiver_id': _remoteUserId,
          'recipient': _remoteUserId,
          'receiver': _remoteUserId,
          'sdp': finalSdp,
          'offer_type': description.type,
          'data': {
            'sdp': finalSdp,
            'type': description.type,
          },
        });
        AppLogger.d('[WEBRTC_OFFER_SEND_SUCCESS] webrtc_offer dispatched via signal sender.');
        // Reliability: when candidate embedding in the SDP failed (live
        // localDescription without candidates), ALWAYS flush the gathered
        // candidates as a batched trickle frame so the peer still receives
        // them. Duplicates of embedded candidates are harmless.
        try {
          _flushLocalIceCandidates();
        } catch (_) {}
        return true;
      } else {
        AppLogger.d('[CALL CONNECT V6] FAILED step=signalSender_offer error=Signal sender callback is null stack=${StackTrace.current}');
        AppLogger.d('[WEBRTC_TRACE_ERROR] stage=signalSender_check call_id=$callId error=Signal sender callback is null');
        AppLogger.d('[WEBRTC_SIGNAL_SEND_FAILED] Signal sender callback is null, offer not sent.');
        return false;
      }
    } catch (e, stack) {
      AppLogger.d('[CALL CONNECT V6] FAILED step=createAndSendOffer error=$e stack=$stack');
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=createAndSendOffer call_id=$callId error=$e');
      AppLogger.d('[WEBRTC_OFFER_CREATION_FAILED] Error creating SDP offer: $e');
      _errorController.add('Failed to create offer: $e');
      return false;
    } finally {
      _makingOffer = false;
    }
  }

  Future<void> handleRemoteOffer({
    required String sdp,
    required String consultationId,
    required String callId,
    String? remoteUserId,
  }) async {
    if (remoteUserId != null && remoteUserId.isNotEmpty && remoteUserId != 'null') {
      _remoteUserId = remoteUserId;
    }
    AppLogger.d('[CALL CONNECT V6] offer received');
    AppLogger.d('[WEBRTC ANSWER V5] offer received call_id=$callId consultation_id=$consultationId');

    if (_peerConnection == null && _pcInitCompleter != null && !_pcInitCompleter!.isCompleted) {
      AppLogger.d('[WEBRTC STATE V5] peer connection in flight, awaiting initialization...');
      try {
        await _pcInitCompleter!.future.timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    final pcExists = _peerConnection != null;
    RTCSessionDescription? localDesc;
    try {
      localDesc = await _peerConnection?.getLocalDescription();
    } catch (_) {
      // No local description is expected when accepting the first offer.
    }
    final localDescExists = localDesc != null;
    final remoteDescExists = _remoteDescriptionSet;
    AppLogger.d('[WEBRTC STATE V5] peer connection exists=$pcExists');
    AppLogger.d('[WEBRTC STATE V5] local description exists=$localDescExists');
    AppLogger.d('[WEBRTC STATE V5] remote description exists=$remoteDescExists');

    if (_peerConnection == null) {
      AppLogger.d('[CALL CONNECT V6] FAILED step=handleRemoteOffer error=PeerConnection is null stack=${StackTrace.current}');
      AppLogger.d('[WEBRTC ANSWER V5] setRemoteDescription FAILED error=PeerConnection is null stack=${StackTrace.current}');
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=handleRemoteOffer call_id=$callId error=PeerConnection is null');
      return;
    }

    final description = RTCSessionDescription(sdp, 'offer');

    final signalingState = _peerConnection!.signalingState;
    final stateKnown = signalingState != null;
    final offerCollision = _makingOffer ||
        (stateKnown && signalingState != RTCSignalingState.RTCSignalingStateStable);

    _ignoreOffer = !_isPolite && offerCollision;
    if (_ignoreOffer) {
      AppLogger.d('[WEBRTC OFFER V3] ignored due to impolite glare collision');
      return;
    }

    try {
      if (offerCollision) {
        AppLogger.d('[WEBRTC_GLARE] Polite peer rolling back local offer. call_id=$callId');
        await _peerConnection!.setLocalDescription(
          RTCSessionDescription('', 'rollback'),
        );
      }

      AppLogger.d('[WEBRTC ANSWER V5] before setRemoteDescription');
      try {
        await _peerConnection!.setRemoteDescription(description);
        _remoteDescriptionSet = true;
        AppLogger.d('[CALL CONNECT V6] setRemoteDescription SUCCESS');
        AppLogger.d('[WEBRTC ANSWER V5] setRemoteDescription SUCCESS');
      } catch (e, stack) {
        AppLogger.d('[CALL CONNECT V6] FAILED step=setRemoteDescription_offer error=$e stack=$stack');
        AppLogger.d('[WEBRTC ANSWER V5] setRemoteDescription FAILED error=$e stack=$stack');
        rethrow;
      }

      await _drainQueuedIceCandidates();

      AppLogger.d('[WEBRTC ANSWER V5] before createAnswer');
      final RTCSessionDescription answer = await _peerConnection!.createAnswer();
      AppLogger.d('[CALL CONNECT V6] createAnswer SUCCESS');
      AppLogger.d('[WEBRTC ANSWER V5] createAnswer SUCCESS');

      AppLogger.d('[WEBRTC ANSWER V5] before setLocalDescription');
      await _peerConnection!.setLocalDescription(answer);
      AppLogger.d('[CALL CONNECT V6] setLocalDescription SUCCESS');
      AppLogger.d('[WEBRTC ANSWER V5] setLocalDescription SUCCESS');

      // Match the offer path: wait briefly for native ICE gathering and send
      // an answer SDP that already contains candidates. Relying only on a
      // later trickle frame is unreliable when relays batch or delay frames.
      _awaitingSdpEmbed = true;
      await _waitForGatheringCompleteOrTimeout();
      _awaitingSdpEmbed = false;
      final finalAnswerSdp = await _sdpWithNativeCandidates(
        fallbackSdp: answer.sdp ?? '',
        answer: true,
      );

      if (_signalSender != null) {
        AppLogger.d('[WEBRTC ANSWER V5] sending webrtc_answer');
        _signalSender!({
          'type': 'webrtc_answer',
          'action': 'webrtc_answer',
          'consultation_id': consultationId,
          'call_id': callId,
          'recipient_id': _remoteUserId,
          'receiver_id': _remoteUserId,
          'recipient': _remoteUserId,
          'receiver': _remoteUserId,
          'sdp': finalAnswerSdp,
          'answer_type': answer.type,
          'data': {
            'sdp': finalAnswerSdp,
            'type': answer.type,
          },
        });
        AppLogger.d('[CALL CONNECT V6] webrtc_answer SENT');
        AppLogger.d('[WEBRTC ANSWER V5] webrtc_answer SENT');
        try {
          _flushLocalIceCandidates();
        } catch (_) {}
      } else {
        AppLogger.d('[CALL CONNECT V6] FAILED step=send_webrtc_answer error=Signal sender callback is null stack=${StackTrace.current}');
        AppLogger.d('[WEBRTC ANSWER V5] webrtc_answer FAILED error=Signal sender callback is null');
      }
    } catch (e, stack) {
      AppLogger.d('[CALL CONNECT V6] FAILED step=handleRemoteOffer error=$e stack=$stack');
      AppLogger.d('[WEBRTC ANSWER V5] webrtc_answer FAILED error=$e');
      AppLogger.d('[WEBRTC_REMOTE_DESCRIPTION_FAILED] Error handling remote offer: $e');
      _errorController.add('Failed to handle offer: $e');
    }
  }

  Future<void> handleRemoteAnswer({required String sdp, String? remoteUserId}) async {
    if (remoteUserId != null && remoteUserId.isNotEmpty && remoteUserId != 'null') {
      _remoteUserId = remoteUserId;
    }
    if (_peerConnection == null) return;

    if (_peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      AppLogger.d(
          '[WEBRTC_ANSWER_IGNORED] Received answer while not in have-local-offer state (state=${_peerConnection!.signalingState}); ignoring stale answer.');
      return;
    }

    try {
      AppLogger.d('[WEBRTC_ANSWER_RECEIVED] Handling remote SDP answer...');
      final description = RTCSessionDescription(sdp, 'answer');
      try {
        await _peerConnection!.setRemoteDescription(description);
        _remoteDescriptionSet = true;
        AppLogger.d('[WEBRTC_TRACE_22_REMOTE_DESCRIPTION_SET] Remote answer set');
        AppLogger.d('[WEBRTC_REMOTE_DESCRIPTION_SET] Remote answer SDP set successfully.');
      } catch (e) {
        AppLogger.d('[WEBRTC_TRACE_ERROR] stage=setRemoteDescription_answer error=$e');
        AppLogger.d('[WEBRTC_REMOTE_DESCRIPTION_FAILED] Failed to set remote answer SDP: $e');
        rethrow;
      }

      await _drainQueuedIceCandidates();
    } catch (e) {
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=handleRemoteAnswer error=$e');
      AppLogger.d('[WEBRTC_REMOTE_DESCRIPTION_FAILED] Error handling remote answer: $e');
      _errorController.add('Failed to handle answer: $e');
    }
  }

  Future<void> handleRemoteIceCandidate(Map<String, dynamic> candidateData) async {
    if (_peerConnection == null) {
      AppLogger.d('[WEBRTC_ICE_RECEIVED] Ignored remote candidate: PeerConnection is null');
      return;
    }
    try {
      final dataMap = (candidateData['data'] is Map) ? Map<String, dynamic>.from(candidateData['data']) : <String, dynamic>{};

      // Support batched candidates (coalesced signaling). When the sender
      // coalesced its local candidates we receive them as a list under
      // `data.candidates`; otherwise fall back to the legacy single-candidate
      // shapes (top-level or under `data`).
      final dynamic batched = dataMap['candidates'];
      if (batched is List && batched.isNotEmpty) {
        AppLogger.d('[WEBRTC_ICE_RECEIVED] Received batched remote candidates (${batched.length}).');
        for (final dynamic entry in batched) {
          if (entry is! Map) continue;
          final entryMap = Map<String, dynamic>.from(entry);
          final cStr = (entryMap['candidate'] ?? '').toString();
          final cMid = (entryMap['sdpMid'] ?? entryMap['sdp_mid'])?.toString();
          final cIdx =
              int.tryParse((entryMap['sdpMLineIndex'] ?? entryMap['sdp_mline_index'] ?? entryMap['label'] ?? 0).toString()) ?? 0;
          await _addSingleRemoteIceCandidate(cStr, cMid, cIdx);
        }
        return;
      }

      dynamic candObj = candidateData['candidate'] ?? dataMap['candidate'];
      String? candidateStr;
      String? sdpMid;
      int sdpMLineIndex = 0;

      if (candObj is Map) {
        candidateStr = (candObj['candidate'] ?? '').toString();
        sdpMid = (candObj['sdpMid'] ?? candObj['sdp_mid'])?.toString();
        sdpMLineIndex = int.tryParse((candObj['sdpMLineIndex'] ?? candObj['sdp_mline_index'] ?? candObj['label'] ?? 0).toString()) ?? 0;
      } else if (candObj != null) {
        candidateStr = candObj.toString();
        sdpMid = (candidateData['sdpMid'] ?? candidateData['sdp_mid'] ?? dataMap['sdpMid'] ?? dataMap['sdp_mid'])?.toString();
        sdpMLineIndex = int.tryParse((candidateData['sdpMLineIndex'] ?? candidateData['sdp_mline_index'] ?? candidateData['label'] ?? dataMap['sdpMLineIndex'] ?? dataMap['sdp_mline_index'] ?? 0).toString()) ?? 0;
      }

      if (candidateStr == null || candidateStr.isEmpty) {
        AppLogger.d('[WEBRTC_ICE_RECEIVED] Ignored empty remote ICE candidate string.');
        return;
      }

      await _addSingleRemoteIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
    } catch (e) {
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=handleRemoteIceCandidate error=$e');
      AppLogger.d('[WEBRTC][ERROR] Error adding remote ICE candidate: $e');
    }
  }

  Future<void> _addSingleRemoteIceCandidate(String candidateStr, String? sdpMid, int sdpMLineIndex) async {
    if (_peerConnection == null) return;
    final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
    if (_remoteDescriptionSet) {
      try {
        await _peerConnection!.addCandidate(candidate);
        AppLogger.d('[WEBRTC_TRACE_33_REMOTE_ICE_ADDED] Added remote ICE candidate immediately.');
      } catch (e) {
        // Per the perfect-negotiation pattern, a failed addCandidate is
        // expected (and safe to swallow) if we just ignored a colliding
        // offer as the impolite peer — the candidate may target an
        // m-line/description we deliberately dropped.
        if (!_ignoreOffer) rethrow;
        AppLogger.d('[WEBRTC_ICE_IGNORED] Dropped candidate after ignoring colliding offer: $e');
      }
    } else {
      _queuedRemoteIceCandidates.add(candidate);
      AppLogger.d(
          '[WEBRTC_ICE_QUEUED] Remote description not set yet. Queued ICE candidate (total queued: ${_queuedRemoteIceCandidates.length}).');
    }
  }

  Future<void> _drainQueuedIceCandidates() async {
    if (_peerConnection == null || _queuedRemoteIceCandidates.isEmpty) return;
    AppLogger.d('[WEBRTC_ICE_QUEUE_FLUSH_STARTED] Draining ${_queuedRemoteIceCandidates.length} queued ICE candidates...');
    for (final candidate in List<RTCIceCandidate>.from(_queuedRemoteIceCandidates)) {
      try {
        await _peerConnection!.addCandidate(candidate);
        AppLogger.d('[WEBRTC_ICE_ADDED] Added queued candidate.');
      } catch (e) {
        AppLogger.d('[WEBRTC][ERROR] Failed to add queued candidate: $e');
      }
    }
    _queuedRemoteIceCandidates.clear();
    AppLogger.d('[WEBRTC_ICE_QUEUE_FLUSHED] Queued ICE candidates flushed cleanly.');
  }

  /// Attempts to recover a failed ICE connection by restarting ICE and
  /// renegotiating, instead of leaving the call permanently dead after a
  /// transient network blip (e.g. wifi -> cellular handoff on mobile).
  /// Only the current caller-of-record (whoever last held the offering
  /// role) should drive the restart to avoid a second glare scenario;
  /// here we let whichever side is polite drive it if both attempt it.
  Future<bool> _attemptIceRestart({
    required String consultationId,
    required String callId,
  }) async {
    if (_peerConnection == null) return false;
    try {
      await createAndSendOffer(
        consultationId: consultationId,
        callId: callId,
        iceRestart: true,
      );
      AppLogger.d('[WEBRTC][ICE] ICE restart offer sent for call_id=$callId');
      return true;
    } catch (e) {
      AppLogger.d('[WEBRTC][ICE] ICE restart failed: $e');
      return false;
    }
  }

  Future<void> toggleMute(bool isMuted) async {
    _isMuted = isMuted;
    if (_localAudioTrack != null) {
      _localAudioTrack!.enabled = !isMuted;
      AppLogger.d('[WEBRTC_${isMuted ? "MIC_MUTED" : "MIC_UNMUTED"}] Local audio track enabled=${!isMuted}');
    }
  }

  Future<void> toggleSpeaker(bool isSpeaker) async {
    _isSpeakerOn = isSpeaker;
    try {
      await Helper.setSpeakerphoneOn(isSpeaker);
      await Helper.selectAudioOutput(isSpeaker ? 'speaker' : 'earpiece');
      AppLogger.d('[WEBRTC_AUDIO_ROUTE_${isSpeaker ? "SPEAKER" : "EARPIECE"}] Audio route set (isSpeaker=$isSpeaker)');
    } catch (e) {
      AppLogger.d('[WEBRTC][ERROR] Failed to select audio output: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_localVideoTrack == null || !_isVideoEnabled) return;
    try {
      await Helper.switchCamera(_localVideoTrack!);
      AppLogger.d('[WEBRTC_CAMERA_SWITCHED] Camera switched (front ↔ rear)');
    } catch (e) {
      AppLogger.d('[WEBRTC][ERROR] Failed to switch camera: $e');
      _errorController.add('Failed to switch camera: $e');
    }
  }

  Future<void> toggleCamera({
    required bool enableCamera,
    required String consultationId,
    required String callId,
  }) async {
    if (_peerConnection == null) return;

    // Re-entrancy guard: without this, a fast double-tap on the camera
    // button (or a UI double-fire) can start two overlapping
    // renegotiations before the first setLocalDescription resolves,
    // which is its own glare scenario independent of the remote peer.
    if (_renegotiating) {
      AppLogger.d('[WEBRTC_CAMERA] Ignoring toggleCamera call: renegotiation already in progress.');
      return;
    }
    _renegotiating = true;

    AppLogger.d('[WEBRTC_CAMERA_ENABLE_REQUESTED] Toggling camera: enableCamera=$enableCamera');

    try {
      if (enableCamera) {
        if (!kIsWeb) {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            _errorController.add('Camera permission is required.');
            return;
          }
        }

        final Map<String, dynamic> videoConstraints = {
          'audio': false,
          'video': {
            'facingMode': 'user',
            'mandatory': {
              'minWidth': '640',
              'minHeight': '480',
              'minFrameRate': '30',
            },
            'optional': [],
          },
        };

        final MediaStream videoStream =
            await navigator.mediaDevices.getUserMedia(videoConstraints);
        _localVideoTrack = videoStream.getVideoTracks().first;
        _localStream?.addTrack(_localVideoTrack!);
        localRenderer.srcObject = _localStream;

        _videoSender =
            await _peerConnection!.addTrack(_localVideoTrack!, _localStream!);
        _isVideoEnabled = true;

        AppLogger.d('[WEBRTC_LOCAL_VIDEO_TRACK_CREATED] Video track added. Renegotiating SDP offer...');
        AppLogger.d('[WEBRTC_VIDEO_RENEGOTIATION_STARTED] Starting renegotiation for camera ON');
        await createAndSendOffer(consultationId: consultationId, callId: callId);
        AppLogger.d('[WEBRTC_VIDEO_RENEGOTIATION_COMPLETED] Camera ON offer sent');
      } else {
        _isVideoEnabled = false;
        if (_localVideoTrack != null) {
          _localVideoTrack!.enabled = false;
          _localVideoTrack!.stop();
          if (_videoSender != null) {
            try {
              await _peerConnection!.removeTrack(_videoSender!);
            } catch (e) {
              AppLogger.d('[WEBRTC][CAMERA] Notice removing track: $e');
            }
            _videoSender = null;
          }
          _localStream?.removeTrack(_localVideoTrack!);
          _localVideoTrack = null;
        }
        localRenderer.srcObject = null;

        AppLogger.d('[WEBRTC_CAMERA_DISABLED] Video track stopped & removed. Renegotiating SDP offer...');
        await createAndSendOffer(consultationId: consultationId, callId: callId);
      }
    } catch (e) {
      AppLogger.d('[WEBRTC][ERROR] Failed to toggle camera: $e');
      _errorController.add('Failed to toggle camera: $e');
    } finally {
      _renegotiating = false;
    }
  }

  Future<void> leaveChannel() async {
    AppLogger.d('[WEBRTC][TEARDOWN] Leaving WebRTC channel and cleaning up resources...');
    _state = WebRTCState.closed;

    _queuedRemoteIceCandidates.clear();
    _remoteDescriptionSet = false;
    _makingOffer = false;
    _ignoreOffer = false;
    _renegotiating = false;

    if (_localVideoTrack != null) {
      try {
        _localVideoTrack!.stop();
      } catch (e) {
        AppLogger.d('[WEBRTC][TEARDOWN] Video track stop notice: $e');
      }
      _localVideoTrack = null;
    }

    if (_localAudioTrack != null) {
      try {
        _localAudioTrack!.stop();
      } catch (e) {
        AppLogger.d('[WEBRTC][TEARDOWN] Audio track stop notice: $e');
      }
      _localAudioTrack = null;
    }

    if (_localStream != null) {
      try {
        await _localStream!.dispose();
      } catch (e) {
        AppLogger.d('[WEBRTC][TEARDOWN] Local stream dispose notice: $e');
      }
      _localStream = null;
    }

    if (_remoteStream != null) {
      try {
        await _remoteStream!.dispose();
      } catch (e) {
        AppLogger.d('[WEBRTC][TEARDOWN] Remote stream dispose notice: $e');
      }
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      try {
        await _peerConnection!.close();
      } catch (e) {
        AppLogger.d('[WEBRTC][TEARDOWN] PeerConnection close notice: $e');
      }
      _peerConnection = null;
    }

    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (e) {
      AppLogger.d('[WEBRTC][TEARDOWN] Renderer srcObject clear notice: $e');
    }

    // Note: _remoteUserId and _localUserId are intentionally left as-is
    // here rather than cleared, in case UI code reads them immediately
    // after teardown for a "call ended" screen. They are unconditionally
    // reset at the start of the *next* createPeerConnectionAndStartSession
    // via _resetSessionState(), so no leakage risk remains.

    AppLogger.d('[WEBRTC][TEARDOWN] WebRTC teardown complete.');
  }

  Future<void> dispose() async {
    await leaveChannel();
    if (_isRenderersInitialized) {
      try {
        await localRenderer.dispose();
        await remoteRenderer.dispose();
        _isRenderersInitialized = false;
      } catch (e) {
        AppLogger.d('[WEBRTC][TEARDOWN] Renderers dispose notice: $e');
      }
    }
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
    if (!_remoteVideoStateController.isClosed) {
      await _remoteVideoStateController.close();
    }
    if (!_userJoinedController.isClosed) {
      await _userJoinedController.close();
 
    }
    if (!_errorController.isClosed) {
      await _errorController.close();
    }
  }
}
