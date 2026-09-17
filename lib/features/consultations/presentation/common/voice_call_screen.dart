import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import '../../data/services/webrtc_voice_service.dart';
import '../../data/services/consultation_api_service.dart';

import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class VoiceCallScreen extends StatefulWidget {
  final Appointment appointment;
  final String consultationId;
  final bool isIncomingCall;
  final bool isCaller;

  const VoiceCallScreen({
    super.key,
    required this.appointment,
    required this.consultationId,
    this.isIncomingCall = false,
    this.isCaller = true,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  late bool _isCaller;
  String? _participantName;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  
  Timer? _timer;
  Timer? _statusTimer;
  Timer? _ringTimeoutTimer;
  Timer? _connectionTimeoutTimer;
  Timer? _offerRetryTimer;

  static const int _ringTimeoutSeconds = 45;
  int _secondsElapsed = 0;
  DateTime? _callStartTime;
  DateTime? _serverStartedAt;
  bool _isConnected = false;
  bool _isRinging = false;
  bool _isEndingCall = false;
  bool _hasInitializedToken = false;
  bool _isInitializingToken = false;
  bool _hasHandledTerminalEvent = false;
  bool _hasReceivedCallAccepted = false;
  bool _hasCalledConnectEndpoint = false;
  bool _hasSentInitialOffer = false;

  void _createInitialCallerOffer({required String activeId, String? remoteUserId}) {
    if (!_isCaller || _hasSentInitialOffer || _isEndingCall) return;
    if (!_webrtcVoiceService.hasPeerConnection || _webrtcVoiceService.remoteDescriptionSet) return;

    _hasSentInitialOffer = true;
    try {
      AppLogger.d('[WEBRTC_OFFER_SINGLETON_TRIGGER] Creating single initial SDP offer for call_id=$activeId');
      _webrtcVoiceService.createAndSendOffer(
        consultationId: widget.consultationId,
        callId: activeId,
        remoteUserId: remoteUserId ?? _targetRemoteUserId,
      ).then((sent) {
        if (sent == true) {
          AppLogger.d('[WEBRTC_OFFER_SINGLETON_TRIGGER] Offer sent with native SDP; skipping fallback retry.');
        } else {
          AppLogger.d('[WEBRTC_OFFER_SINGLETON_TRIGGER] Offer could not be sent; scheduling fallback retry.');
          _startOfferRetryTimer(activeId, remoteUserId ?? _targetRemoteUserId);
        }
      });
    } catch (e) {
      AppLogger.d('[WEBRTC_TRACE_ERROR] stage=createInitialCallerOffer call_id=$activeId error=$e');
    }
  }

  StreamSubscription? _callEventSub;
  StreamSubscription? _connectionStateSub;
  StreamSubscription? _userJoinedSub;
  StreamSubscription? _remoteVideoSub;
  StreamSubscription? _errorSub;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final WebRTCVoiceService _webrtcVoiceService = WebRTCVoiceService();
  final ConsultationApiService _apiService = ConsultationApiService();

  String? _activeSessionKey;
  String? _targetRemoteUserId;

  @override
  void initState() {
    super.initState();
    _isCaller = widget.isCaller;
    _isRinging = true;
    _participantName = widget.isCaller
        ? (widget.appointment.userFullName?.isNotEmpty == true
            ? widget.appointment.userFullName
            : widget.appointment.midwifeName)
        : (widget.appointment.midwifeName?.isNotEmpty == true
            ? widget.appointment.midwifeName
            : widget.appointment.userFullName);

    // Register WebRTC WebSocket signal sender callback
    _webrtcVoiceService.setSignalSender((payload) {
      final action = payload['action'] ?? payload['type'];
      AppLogger.d('[WEBRTC SIGNAL OUT] Sending signal=$action over WebSocket for consultation=${widget.consultationId}');
      GlobalCallService.broadcastWsSignal(
        widget.consultationId,
        action,
        extraPayload: payload,
      );
    });

    _callEventSub = GlobalCallService.onCallEvent.listen((event) {
      final eventConsultId = (event['consultation_id'] ?? event['appointment_id'] ?? '').toString();
      final eventCallId = (event['call_id'] ?? event['session_key'] ?? event['session_id'] ?? '').toString();

      final matchesConsultation = eventConsultId.isEmpty ||
          eventConsultId == widget.consultationId ||
          eventConsultId == widget.appointment.appointmentId;
      final matchesCallId = eventCallId.isEmpty ||
          _activeSessionKey == null ||
          eventCallId == _activeSessionKey ||
          _activeSessionKey!.contains(eventCallId);

      // A signal carrying both identifiers must match both. The prior `&&`
      // condition admitted frames from another call when either id happened
      // to match, allowing stale SDP/ICE to poison this PeerConnection.
      if (!matchesConsultation || !matchesCallId) {
        AppLogger.d('[CALL CONNECT V6] Discarding unmatched signal: eventConsultId=$eventConsultId eventCallId=$eventCallId');
        return;
      }

      if (_activeSessionKey == null && eventCallId.isNotEmpty) {
        _activeSessionKey = eventCallId;
        AppLogger.d('[CALL CONNECT V6] Adopted active call_id from validated signal: $_activeSessionKey');
      }

      if (_hasHandledTerminalEvent || _isEndingCall) return;

      final eventType = (event['type'] ?? event['action'] ?? '').toString();
      final signalType = GlobalCallService.parseSignalType(event);
      AppLogger.d('[CALLER RECEIVED] VoiceCallScreen eventType: $eventType, signalType: $signalType, payload: $event');

      final dataMap = (event['data'] is Map) ? Map<String, dynamic>.from(event['data']) : <String, dynamic>{};

      // WebRTC Signal Processing
      if (eventType == 'webrtc_offer') {
        AppLogger.d('[CALL CONNECT V6] offer received');
        final sdp = (event['sdp'] ?? dataMap['sdp']) as String?;
        final senderId = (event['sender_id'] ?? event['caller_id'] ?? event['user_id'] ?? dataMap['sender_id'] ?? '').toString();
        if (sdp != null && sdp.isNotEmpty) {
          _webrtcVoiceService.handleRemoteOffer(
            sdp: sdp,
            consultationId: widget.consultationId,
            callId: _activeSessionKey ?? widget.consultationId,
            remoteUserId: senderId.isNotEmpty ? senderId : _targetRemoteUserId,
          );
        } else {
          AppLogger.d('[CALL CONNECT V6] FAILED step=offer_received error=Empty SDP offer stack=${StackTrace.current}');
        }
      } else if (eventType == 'webrtc_answer') {
        AppLogger.d('[CALL CONNECT V6] webrtc_answer RECEIVED');
        final sdp = (event['sdp'] ?? dataMap['sdp']) as String?;
        final senderId = (event['sender_id'] ?? event['user_id'] ?? dataMap['sender_id'] ?? '').toString();
        if (sdp != null && sdp.isNotEmpty) {
          _offerRetryTimer?.cancel();
          _webrtcVoiceService.handleRemoteAnswer(
            sdp: sdp,
            remoteUserId: senderId.isNotEmpty ? senderId : _targetRemoteUserId,
          );
        } else {
          AppLogger.d('[CALL CONNECT V6] FAILED step=answer_received error=Empty SDP answer stack=${StackTrace.current}');
        }
      } else if (eventType == 'webrtc_ice_candidate') {
        AppLogger.d('[CALL CONNECT V6] ICE candidate received');
        _webrtcVoiceService.handleRemoteIceCandidate(event);
      } else if (eventType == 'webrtc_ready') {
        final activeId = _activeSessionKey ?? widget.consultationId;
        final senderId = (event['sender_id'] ?? event['user_id'] ?? '').toString();
        AppLogger.d('[WEBRTC_READY_RECEIVED] Receiver ready signal received for call_id=$activeId is_caller=$_isCaller');
        if (_isCaller) {
          _hasReceivedCallAccepted = true;
          _createInitialCallerOffer(activeId: activeId, remoteUserId: senderId.isNotEmpty ? senderId : _targetRemoteUserId);
        }
      } else if (signalType == CallSignalType.callAccepted) {
        final activeId = _activeSessionKey ?? widget.consultationId;
        AppLogger.d('[CALL CONNECT V6] Accept completed');
        AppLogger.d('[WEBRTC_TRACE_03_CALL_ACCEPTED_SCREEN_HANDLER] call_id=$activeId is_caller=$_isCaller');
        AppLogger.d('[CALL-EVENT] WEBRTC_CALL_ACCEPTED_RECEIVED call_id=${widget.consultationId}');
        RingtoneService.stopRingtone();
        if (mounted) {
          setState(() {
            _isRinging = false;
          });
          _webrtcVoiceService.toggleMute(_isMuted);
          _webrtcVoiceService.toggleSpeaker(_isSpeakerOn);
        }
        if (_isCaller) {
          _hasReceivedCallAccepted = true;
          _createInitialCallerOffer(activeId: activeId);
        } else {
          AppLogger.d('[CALL CONNECT V6] waiting for offer');
          AppLogger.d('[VOICE_CALL_SCREEN] Callee received call_accepted — standing by for caller offer.');
        }
      } else if (signalType == CallSignalType.callEnded ||
          signalType == CallSignalType.callCancelled ||
          signalType == CallSignalType.callDeclined) {
        AppLogger.d('[CALL STATE RESET] Call declined or ended signal received in caller UI');
        _endCall(notifyBackendApi: false, endSource: 'remote_signal_ended');
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    GlobalCallService.isCallActive = true;
    AppLogger.d('[CALL FLOW V2] incoming UI shown call_id=${widget.consultationId} isIncomingCall=${widget.isIncomingCall} isCaller=${widget.isCaller}');
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    if (_hasInitializedToken || _isInitializingToken || _isEndingCall) {
      AppLogger.d('[VOICE] WebRTC Session SKIPPED — already initialized');
      return;
    }
    _isInitializingToken = true;
    AppLogger.d('[VOICE] WebRTC Session START');

    try {
      final currentUserId = GlobalCallService.currentUserId ?? await GlobalCallService.getAuthenticatedUserId() ?? 'unknown';
      await GlobalCallService.init(widget.consultationId);

      AppLogger.d('====================================================');
      AppLogger.d('[VOICE CALL SCREEN INIT - WEBRTC]');
      AppLogger.d('  Current Authenticated User ID : $currentUserId');
      AppLogger.d('  Consultation ID               : ${widget.consultationId}');
      AppLogger.d('  Is Caller                     : ${widget.isCaller}');
      AppLogger.d('====================================================');

      Map<String, dynamic> response;
      if (widget.isCaller) {
        response = await _apiService.startVoiceSession(widget.consultationId);
        AppLogger.d('[VOICE] start_call complete — backend WS call_offer already dispatched');
      } else {
        response = await _apiService.getVoiceToken(widget.consultationId);
      }

      if (_isEndingCall || !mounted) {
        _isInitializingToken = false;
        AppLogger.d('[VOICE CALL INIT] Aborted because call was cancelled or screen unmounted.');
        return;
      }

      _hasInitializedToken = true;
      _isInitializingToken = false;
      AppLogger.d('[VOICE] Session metadata acquired successfully');

      final voiceSession = response['voice_session'] ?? response['consultation']?['voice_session'] ?? response;
      final sessionKey = (response['session_key'] ?? response['call_id'] ?? voiceSession['session_key'] ?? voiceSession['call_id'] ?? widget.consultationId).toString();
      _activeSessionKey = sessionKey.isNotEmpty ? sessionKey : widget.consultationId;

      final callerId = GlobalCallService.extractId(
        response['caller_id'] ?? response['caller'] ?? voiceSession['caller_id'] ?? voiceSession['caller'] ?? widget.appointment.userId
      );
      final receiverId = GlobalCallService.extractId(
        response['receiver_id'] ?? response['recipient_id'] ?? response['receiver'] ?? response['recipient'] ??
        voiceSession['receiver_id'] ?? voiceSession['recipient_id'] ?? voiceSession['receiver'] ?? voiceSession['recipient'] ??
        (widget.appointment.midwifeId.isNotEmpty ? widget.appointment.midwifeId : widget.appointment.userId)
      );

      final startedAtStr = (voiceSession['started_at'] ?? response['started_at'] ?? '').toString();
      if (startedAtStr.isNotEmpty) {
        _serverStartedAt = DateTime.tryParse(startedAtStr)?.toUtc();
      }

      AppLogger.d('[VOICE METADATA] consultation_id=${widget.consultationId} session_key=$_activeSessionKey current_user_id=$currentUserId caller_id=$callerId receiver_id=$receiverId is_caller_param=${widget.isCaller}');

      bool effectiveIsCaller = widget.isCaller;
      if (callerId.isNotEmpty && currentUserId != 'unknown' && callerId.trim() != currentUserId.trim()) {
        AppLogger.d('[VOICE CALL] Session initiated by remote user ($callerId). Current user ($currentUserId) joining as callee.');
        effectiveIsCaller = false;
      } else if (callerId.isNotEmpty && currentUserId != 'unknown' && callerId.trim() == currentUserId.trim()) {
        effectiveIsCaller = true;
      }

      String targetRemote;
      if (effectiveIsCaller) {
        targetRemote = receiverId;
        if (targetRemote.isEmpty || targetRemote == currentUserId) {
          if (widget.appointment.midwifeId.isNotEmpty && widget.appointment.midwifeId != currentUserId) {
            targetRemote = widget.appointment.midwifeId;
          } else if (widget.appointment.userId.isNotEmpty && widget.appointment.userId != currentUserId) {
            targetRemote = widget.appointment.userId;
          }
        }
      } else {
        targetRemote = callerId;
        if (targetRemote.isEmpty || targetRemote == currentUserId) {
          if (widget.appointment.userId.isNotEmpty && widget.appointment.userId != currentUserId) {
            targetRemote = widget.appointment.userId;
          }
        }
      }

      _targetRemoteUserId = targetRemote;
      _webrtcVoiceService.setLocalUserId(currentUserId);
      _webrtcVoiceService.setRemoteUserId(_targetRemoteUserId);

      AppLogger.d('[PARTICIPANT_MAPPING] consultation_id=${widget.consultationId} call_id=$_activeSessionKey current_user_id=$currentUserId caller_id=$callerId receiver_id=$receiverId effectiveIsCaller=$effectiveIsCaller target_remote_user_id=$_targetRemoteUserId');

      final callerName = (response['caller_name'] ?? response['voice_session']?['caller_name'] ?? '').toString().trim();
      final recipientName = (response['recipient_name'] ?? response['receiver_name'] ?? response['voice_session']?['recipient_name'] ?? response['voice_session']?['receiver_name'] ?? '').toString().trim();

      String targetParticipantName = '';
      if (effectiveIsCaller) {
        targetParticipantName = recipientName.isNotEmpty
            ? recipientName
            : (widget.appointment.midwifeName ?? 'Midwife');
      } else {
        targetParticipantName = callerName.isNotEmpty
            ? callerName
            : (widget.appointment.userFullName ?? AppLocalizations.of(context)!.patient);
      }

      if (targetParticipantName.isEmpty || targetParticipantName == 'Caller' || targetParticipantName == 'Recipient') {
        targetParticipantName = GlobalCallService.extractPersonName(
          response.containsKey('voice_session') && response['voice_session'] is Map
              ? Map<String, dynamic>.from(response['voice_session'])
              : response,
          isSender: !effectiveIsCaller,
        );
      }

      if (mounted) {
        setState(() {
          _isCaller = effectiveIsCaller;
          if (targetParticipantName.isNotEmpty && targetParticipantName != 'Caller' && targetParticipantName != 'Recipient') {
            _participantName = targetParticipantName;
          }
        });
      }

      AppLogger.d('[CALL-ACTION-FE] surface=VOICE_CALL_SCREEN event=WEBRTC_INIT_START call_id=${widget.consultationId}');

      // Subscribe to WebRTC events
      _connectionStateSub = _webrtcVoiceService.onConnectionStateChanged.listen((pcState) {
        AppLogger.d('[VOICE CALL SCREEN] WebRTC ConnectionState: $pcState');
        AppLogger.d('[WEBRTC FLOW V3] event=connectionStateChanged call_id=${widget.consultationId} state=$pcState');
        if (pcState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _onWebRTCConnected();
        } else if (pcState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            pcState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          AppLogger.d('[WEBRTC FAILURE V3] connection_state=$pcState triggering END');
          if (mounted && !_isEndingCall) {
            _endCall(notifyBackendApi: _isCaller, endSource: 'WEBRTC_CONNECTION_FAILED');
          }
        }
      });

      _userJoinedSub = _webrtcVoiceService.onUserJoined.listen((_) {
        _onWebRTCConnected();
      });

      _errorSub = _webrtcVoiceService.onError.listen((err) {
        AppLogger.d("[WEBRTC ERROR] $err");
        if (mounted && !_isEndingCall) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.callConnectionFailed}: $err'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      if (_isCaller) {
        RingtoneService.playOutgoingRingback();
        if (mounted) {
          setState(() {
            _isRinging = true;
          });
        }
        _ringTimeoutTimer?.cancel();
        AppLogger.d('[CALL TIMEOUT V2] timer started call_id=${widget.consultationId} seconds=$_ringTimeoutSeconds');
        _ringTimeoutTimer = Timer(const Duration(seconds: _ringTimeoutSeconds), () {
          AppLogger.d('[CALL TIMEOUT V2] timer fired call_id=${widget.consultationId}');
          if (!_isEndingCall && _isRinging && !_isConnected && mounted) {
            AppLogger.d('VoiceCallScreen: Ring timeout reached — auto-cancelling unanswered call');
            _endCall();
          }
        });
      } else if (widget.isIncomingCall && !_hasReceivedCallAccepted) {
        if (mounted) {
          setState(() {
            _isRinging = true;
          });
        }
        _ringTimeoutTimer?.cancel();
        AppLogger.d('[CALL TIMEOUT V2] timer started call_id=${widget.consultationId} seconds=$_ringTimeoutSeconds');
        _ringTimeoutTimer = Timer(const Duration(seconds: _ringTimeoutSeconds), () {
          AppLogger.d('[CALL TIMEOUT V2] timer fired call_id=${widget.consultationId}');
          if (!_isEndingCall && _isRinging && !_isConnected && mounted) {
            AppLogger.d('VoiceCallScreen: Ring timeout reached — auto-cancelling unanswered call');
            _endCall();
          }
        });
      } else {
        RingtoneService.stopRingtone();
        if (mounted) {
          setState(() {
            _isRinging = false;
          });
        }
      }

      // Extract server-provided ICE servers if available
      List<Map<String, dynamic>>? iceServers;
      final webrtcConfig = response['webrtc_config'] ?? response['voice_session']?['webrtc_config'];
      if (webrtcConfig is Map && webrtcConfig['ice_servers'] is List) {
        iceServers = (webrtcConfig['ice_servers'] as List).cast<Map<String, dynamic>>();
      } else if (response['ice_servers'] is List) {
        iceServers = (response['ice_servers'] as List).cast<Map<String, dynamic>>();
      }

      // Start WebRTC Session
      await _webrtcVoiceService.createPeerConnectionAndStartSession(
        consultationId: widget.consultationId,
        callId: _activeSessionKey ?? widget.consultationId,
        isCaller: effectiveIsCaller,
        remoteUserId: _targetRemoteUserId,
        localUserId: currentUserId,
        iceServersConfig: iceServers,
      );

      if (effectiveIsCaller && _hasReceivedCallAccepted) {
        final activeId = _activeSessionKey ?? widget.consultationId;
        AppLogger.d('[WEBRTC_OFFER_CREATION_START] Caller PC ready post call_accepted — creating offer now.');
        _createInitialCallerOffer(activeId: activeId);
      }

      if (!effectiveIsCaller && !_isEndingCall) {
        AppLogger.d('[WEBRTC_SIGNAL_OUT] Receiver ready in VoiceCallScreen. Broadcasting webrtc_ready...');
        GlobalCallService.broadcastWsSignal(
          widget.consultationId,
          'webrtc_ready',
          extraPayload: {
            'call_id': _activeSessionKey ?? widget.consultationId,
            'recipient_id': _targetRemoteUserId,
            'receiver_id': _targetRemoteUserId,
            'recipient': _targetRemoteUserId,
            'receiver': _targetRemoteUserId,
          },
        );
      }

      if (_isEndingCall) {
        AppLogger.d('[VOICE CALL INIT] Interrupted post-createPeerConnection. Leaving WebRTC channel immediately.');
        await _webrtcVoiceService.leaveChannel();
      }
    } catch (e) {
      RingtoneService.stopRingtone();
      AppLogger.d("Failed to initialize WebRTC call: $e");
      if (mounted && !_isEndingCall) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.callFailed}: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 8)),
        );
        // A failed init (e.g. a stale consultation returning 410 on the voice
        // token request) must NOT leave the caller stranded on an endless
        // "Connecting" screen with no audio. Terminate the call screen
        // gracefully instead of hanging; no backend session exists to END.
        _endCall(notifyBackendApi: false, endSource: 'init_failed');
      }
    }
  }

  void _startOfferRetryTimer(String activeId, [String? targetRemoteUserId]) {
    _offerRetryTimer?.cancel();
    // Only schedule a single fallback retry after 6s if no remote answer/description has been received.
    _offerRetryTimer = Timer(const Duration(seconds: 6), () {
      if (_isConnected || _isEndingCall || !_webrtcVoiceService.hasPeerConnection) return;
      if (_webrtcVoiceService.remoteDescriptionSet) return;
      
      AppLogger.d('[WEBRTC_OFFER_RETRY] Fallback offer retry (no answer received after 6s) for call_id=$activeId...');
      _webrtcVoiceService.createAndSendOffer(
        consultationId: widget.consultationId,
        callId: activeId,
        remoteUserId: targetRemoteUserId ?? _targetRemoteUserId,
      );
    });
  }

  void _onWebRTCConnected() async {
    if (_isConnected) return;
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
    _offerRetryTimer?.cancel();
    _offerRetryTimer = null;
    RingtoneService.stopRingtone();
    GlobalCallService.isRingingShown = false;
    GlobalCallService.isCallActive = true;
    AppLogger.d('[CALL-LIFECYCLE] WEBRTC CONNECTED call_id=${widget.consultationId}');
    GlobalCallService.stateMachine.transitionTo(
      CallState.connected,
      callId: widget.consultationId,
      consultationId: widget.consultationId,
    );

    // Notify backend WebSocket that WebRTC media connection is established
    GlobalCallService.broadcastWsSignal(widget.consultationId, 'call_connected');

    if (!_hasCalledConnectEndpoint) {
      _hasCalledConnectEndpoint = true;
      try {
        await _apiService.connectVoiceSession(widget.consultationId);
        AppLogger.d('[VOICE CALL SCREEN] REST /voice-session/connect/ called successfully');
      } catch (e) {
        AppLogger.d('[VOICE CALL SCREEN] REST /voice-session/connect/ call notice: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isRinging = false;
        _isConnected = true;
      });
      _startTimer(startedAt: _serverStartedAt);
      _webrtcVoiceService.toggleMute(_isMuted);
      _webrtcVoiceService.toggleSpeaker(_isSpeakerOn);
    }
  }

  void _startTimer({DateTime? startedAt}) {
    if (_timer != null && _timer!.isActive) {
      AppLogger.d('[CALL TIMER V6] duration timer already active; skipping restart');
      return;
    }
    AppLogger.d('[CALL TIMER V6] START');

    RingtoneService.stopRingtone();
    _statusTimer?.cancel();
    _statusTimer = null;
    _timer?.cancel();
    final now = DateTime.now().toUtc();

    if (startedAt != null) {
      final ageInSeconds = now.difference(startedAt).inSeconds.abs();
      if (ageInSeconds < 3600) {
        _callStartTime = startedAt;
      }
    }
    _callStartTime ??= now;

    final initialDiff = now.difference(_callStartTime!).inSeconds;
    _secondsElapsed = (initialDiff >= 0 && initialDiff < 86400) ? initialDiff : 0;
    AppLogger.d('[CALL TIMER V6] elapsed=$_secondsElapsed');

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConnected && mounted) {
        final diff = DateTime.now().toUtc().difference(_callStartTime!).inSeconds;
        final newElapsed = (diff >= 0 && diff < 86400) ? diff : 0;
        setState(() {
          _secondsElapsed = newElapsed;
        });
        AppLogger.d('[CALL TIMER V6] elapsed=$_secondsElapsed');
      }
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      AppLogger.d('[CALL TIMER V6] STOPPED final_elapsed=$_secondsElapsed');
      _timer?.cancel();
      _timer = null;
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _webrtcVoiceService.toggleMute(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _webrtcVoiceService.toggleSpeaker(_isSpeakerOn);
  }

  Future<void> _endCall({bool notifyBackendApi = true, String endSource = 'UNKNOWN'}) async {
    if (_isEndingCall || _hasHandledTerminalEvent) return;
    _hasHandledTerminalEvent = true;
    _isEndingCall = true;
    _hasInitializedToken = true;
    _isInitializingToken = false;

    AppLogger.d('[CALL END V6] triggered');
    AppLogger.d('reason=$endSource');
    AppLogger.d('source=${notifyBackendApi ? "local_user_or_system" : "remote_signal"}');
    AppLogger.d('call_id=${widget.consultationId}');
    AppLogger.d('[CALL END V5] stack=${StackTrace.current}');

    _stopTimer();
    _statusTimer?.cancel();
    _statusTimer = null;
    if (_ringTimeoutTimer != null) {
      _ringTimeoutTimer?.cancel();
      _ringTimeoutTimer = null;
      AppLogger.d('[CALL TIMEOUT V2] timer cancelled call_id=${widget.consultationId}');
    }
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;

    try {
      await _webrtcVoiceService.leaveChannel();
    } catch (e) {
      AppLogger.d('WebRTC teardown notice: $e');
    }

    if (notifyBackendApi) {
      try {
        await _apiService.endVoiceSession(widget.consultationId, endSource: endSource);
      } catch (e) {
        AppLogger.d('endVoiceSession API notice: $e');
      }
    }

    await GlobalCallService.teardownCall(
      callId: widget.consultationId,
      consultationId: widget.consultationId,
      reason: CallTerminalReason.hangup,
      source: notifyBackendApi ? 'ui_user_hangup' : 'ui_remote_ended',
    );

    AppLogger.d('[CALL] WebRTC Teardown complete');

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    AppLogger.d('[CALL SCREEN V3] dispose call_id=${widget.consultationId}');
    AppLogger.d('[CALL SCREEN V3] current_call_state=${GlobalCallService.stateMachine.state}');
    AppLogger.d('[CALL SCREEN V3] isMounted=$mounted');

    _pulseController.dispose();
    _stopTimer();
    _statusTimer?.cancel();
    _statusTimer = null;
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
    _callEventSub?.cancel();
    _connectionStateSub?.cancel();
    _userJoinedSub?.cancel();
    _remoteVideoSub?.cancel();
    _errorSub?.cancel();

    RingtoneService.stopRingtone();
    FcmService.dismissIncomingCallNotification();
    GlobalCallService.isCallActive = false;
    _webrtcVoiceService.dispose();

    super.dispose();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getInitials(String name) {
    final clean = NameFormatter.format(name).trim();
    if (clean.isEmpty) return 'DM';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = '';
    if (_participantName != null &&
        _participantName!.isNotEmpty &&
        _participantName != 'Caller' &&
        _participantName != 'Recipient') {
      displayName = _participantName!;
    } else if (widget.isIncomingCall || !_isCaller) {
      if (widget.appointment.userFullName != null &&
          widget.appointment.userFullName!.isNotEmpty &&
          widget.appointment.userFullName != 'Caller' &&
          widget.appointment.userFullName != 'Recipient') {
        displayName = widget.appointment.userFullName!;
      } else {
        displayName = widget.appointment.midwifeName ?? 'Care Provider';
      }
    } else {
      if (widget.appointment.midwifeName != null &&
          widget.appointment.midwifeName!.isNotEmpty &&
          widget.appointment.midwifeName != 'Midwife' &&
          widget.appointment.midwifeName != 'Recipient') {
        displayName = widget.appointment.midwifeName!;
      } else {
        displayName = widget.appointment.userFullName ?? AppLocalizations.of(context)!.patient;
      }
    }

    final participantName = NameFormatter.format(displayName);
    final initials = _getInitials(participantName);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGreenDarker,
              AppColors.primaryGreen,
              AppColors.primaryGreenDarkest,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Audio Call UI & Controls
              Column(
                children: [
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.unfold_less, color: Colors.white70, size: 28),
                          onPressed: () => _endCall(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined, color: Colors.white70, size: 26),
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.multiPartyAvailable),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Content with Pulsing Waves
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final scale = _isRinging ? _pulseAnimation.value : 1.0;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.scale(
                                  scale: scale * 1.35,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent.withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                Transform.scale(
                                  scale: scale * 1.15,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent.withValues(alpha: 0.18),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppColors.accentGreen, AppColors.accentGreenDark],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent.withValues(alpha: 0.35),
                                        blurRadius: 30,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        Text(
                          participantName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (_isConnected) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.signal_cellular_alt_rounded, color: Colors.white70, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(_secondsElapsed),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            _isRinging
                                ? (_isCaller ? 'Ringing . .' : 'Voice Consultation')
                                : 'Connecting . .',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 13, color: Colors.white70),
                                SizedBox(width: 4),
                                Text(
                                  'Encrypted Consultation',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                  const Spacer(),

                  // ACTION BAR
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48, left: 16, right: 16),
                    child: _isRinging && !_isCaller
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // DECLINE BUTTON
                              _buildTelegramCallCircleButton(
                                icon: Icons.call_end_rounded,
                                label: AppLocalizations.of(context)!.decline,
                                color: const Color(0xFFEF4444),
                                onTap: () async {
                                  AppLogger.d('[CALL-ACTION-FE] surface=FULL_SCREEN_UI action=DECLINE event=BUTTON_TAPPED call_id=${widget.consultationId}');
                                  final nav = Navigator.of(context);
                                  RingtoneService.stopRingtone();
                                  GlobalCallService.isRingingShown = false;
                                  await IncomingCallActionDispatcher.dispatchDecline(
                                    widget.consultationId,
                                    widget.consultationId,
                                  );
                                  if (mounted) {
                                    nav.pop();
                                  }
                                },
                              ),

                              // ACCEPT BUTTON
                              _buildTelegramCallCircleButton(
                                icon: Icons.call_rounded,
                                label: AppLocalizations.of(context)!.accept,
                                color: const Color(0xFF22C55E),
                                onTap: () async {
                                  AppLogger.d('[CALL ACCEPT V2] Accept pressed call_id=${widget.consultationId} consultation_id=${widget.consultationId} current call state=${GlobalCallService.stateMachine.state}');
                                  AppLogger.d('[CALL-ACTION-FE] surface=FULL_SCREEN_UI action=ACCEPT event=BUTTON_TAPPED call_id=${widget.consultationId}');
                                  if (_ringTimeoutTimer != null) {
                                    _ringTimeoutTimer?.cancel();
                                    _ringTimeoutTimer = null;
                                    AppLogger.d('[CALL TIMEOUT V2] timer cancelled call_id=${widget.consultationId}');
                                  }
                                  RingtoneService.stopRingtone();
                                  GlobalCallService.isRingingShown = false;
                                  await IncomingCallActionDispatcher.dispatchAccept(
                                    widget.consultationId,
                                    widget.consultationId,
                                    {
                                      'consultation_id': widget.consultationId,
                                      'call_id': widget.consultationId,
                                    },
                                    source: 'VOICE_SCREEN_ACCEPT_BUTTON',
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _isRinging = false;
                                    });
                                  }
                                },
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 1. Speaker Button
                              _buildTelegramActionButton(
                                icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                                label: AppLocalizations.of(context)!.speaker,
                                isActive: _isSpeakerOn,
                                onTap: () {
                                  _toggleSpeaker();
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_isSpeakerOn ? 'Speakerphone ON' : 'Speakerphone OFF'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),

                              // 2. Mute Button
                              _buildTelegramActionButton(
                                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                label: _isMuted ? 'Muted' : 'Mute',
                                isActive: _isMuted,
                                onTap: () {
                                  _toggleMute();
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_isMuted ? 'Microphone Muted' : 'Microphone Unmuted'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),

                              // 4. End Call Button
                              _buildTelegramActionButton(
                                icon: Icons.call_end_rounded,
                                label: _isRinging ? 'Cancel' : 'End Call',
                                bgColor: AppColors.errorRedBright,
                                iconColor: Colors.white,
                                onTap: () async {
                                  RingtoneService.stopRingtone();
                                  await _endCall();
                                },
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramCallCircleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white30,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTelegramActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? bgColor,
    Color? iconColor,
  }) {
    final background = bgColor ?? (isActive ? Colors.white : Colors.white.withValues(alpha: 0.18));
    final iconClr = iconColor ?? (isActive ? AppColors.primaryGreen : Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (bgColor ?? Colors.black).withValues(alpha: 0.25),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconClr,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
