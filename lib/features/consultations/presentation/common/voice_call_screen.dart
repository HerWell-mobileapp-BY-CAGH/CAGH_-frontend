import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import '../../data/services/agora_voice_service.dart';
import '../../data/services/consultation_api_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

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

  // Standard unanswered-call behaviour: the caller stops ringing after this
  // duration (WhatsApp/Telegram ring for ~30-60s, then the call auto-cancels).
  static const int _ringTimeoutSeconds = 45;
  int _secondsElapsed = 0;
  DateTime? _callStartTime;
  DateTime? _serverStartedAt;
  bool _isConnected = false;
  bool _isRinging = false;
  bool _isEndingCall = false;
  bool _hasInitializedToken = false;
  bool _isInitializingToken = false;

  StreamSubscription? _callEventSub;
  StreamSubscription? _userJoinedSub;
  StreamSubscription? _userOfflineSub;
  StreamSubscription? _joinSuccessSub;
  StreamSubscription? _errorSub;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final AgoraVoiceService _agoraVoiceService = AgoraVoiceService();
  final ConsultationApiService _apiService = ConsultationApiService();

  @override
  void initState() {
    super.initState();
    _isCaller = widget.isCaller;
    _isRinging = true;

    _callEventSub = GlobalCallService.onCallEvent.listen((event) {
      final eventConsultId = (event['consultation_id'] ?? event['call_id'] ?? event['session_id'] ?? event['appointment_id'] ?? '').toString();
      if (eventConsultId.isNotEmpty &&
          eventConsultId != widget.consultationId &&
          eventConsultId != widget.appointment.appointmentId) {
        return;
      }

      final signalType = GlobalCallService.parseSignalType(event);
      AppLogger.d('[CALLER RECEIVED] VoiceCallScreen signalType: $signalType, payload: $event');

      if (signalType == CallSignalType.callAccepted) {
        RingtoneService.stopRingtone();
        if (mounted) {
          setState(() {
            _isRinging = false;
            _isConnected = true;
            _startTimer(startedAt: _serverStartedAt);
          });
          _agoraVoiceService.toggleMute(_isMuted);
          _agoraVoiceService.toggleSpeaker(_isSpeakerOn);
        }
      } else if (signalType == CallSignalType.callEnded ||
          signalType == CallSignalType.callCancelled ||
          signalType == CallSignalType.callDeclined) {
        AppLogger.d('[CALL STATE RESET] Call declined or ended signal received in caller UI');
        _handleCallTerminated(signalType);
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
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    if (_hasInitializedToken || _isInitializingToken || _isEndingCall) {
      AppLogger.d('[VOICE] Token request SKIPPED — already initialized');
      return;
    }
    _isInitializingToken = true;
    AppLogger.d('[VOICE] Token request START');

    try {
      final currentUserId = GlobalCallService.currentUserId ?? await GlobalCallService.getAuthenticatedUserId() ?? 'unknown';
      await GlobalCallService.init(widget.consultationId);

      AppLogger.d('====================================================');
      AppLogger.d('[VOICE CALL SCREEN INIT]');
      AppLogger.d('  Current Authenticated User ID : $currentUserId');
      AppLogger.d('  Consultation ID               : ${widget.consultationId}');
      AppLogger.d('  Is Caller                     : ${widget.isCaller}');
      AppLogger.d('====================================================');

      Map<String, dynamic> response;
      if (widget.isCaller) {
        response = await _apiService.startVoiceSession(widget.consultationId);
      } else {
        try {
          response = await _apiService.getVoiceToken(widget.consultationId);
        } catch (_) {
          response = await _apiService.startVoiceSession(widget.consultationId);
        }
      }

      if (_isEndingCall || !mounted) {
        _isInitializingToken = false;
        AppLogger.d('[VOICE CALL INIT] Aborted because call was cancelled or screen unmounted.');
        return;
      }

      _hasInitializedToken = true;
      _isInitializingToken = false;
      AppLogger.d('[VOICE] Token acquired successfully');

      final voiceSession = response['voice_session'] ?? response['consultation']?['voice_session'] ?? response;
      final appId = (response['agora_app_id'] ?? response['app_id'] ?? voiceSession['agora_app_id'] ?? voiceSession['app_id'] ?? '').toString();
      final channelName = (response['agora_channel_name'] ?? response['channel_name'] ?? voiceSession['agora_channel_name'] ?? voiceSession['channel_name'] ?? 'cagh_voice_${widget.consultationId}').toString();
      final rtcToken = (response['agora_token'] ?? response['rtc_token'] ?? response['token'] ?? voiceSession['agora_token'] ?? voiceSession['rtc_token'] ?? '').toString();
      final uidRaw = response['agora_uid'] ?? response['uid'] ?? voiceSession['agora_uid'] ?? voiceSession['uid'] ?? 0;
      int uid = int.tryParse(uidRaw.toString()) ?? 0;
      if (uid == 0 && currentUserId.isNotEmpty && currentUserId != 'unknown') {
        uid = currentUserId.hashCode.abs() % 2147483647;
      }
      final callerId = (response['caller_id'] ?? voiceSession['caller_id'] ?? '').toString();
      final receiverId = (response['receiver_id'] ?? voiceSession['receiver_id'] ?? '').toString();

      final startedAtStr = (voiceSession['started_at'] ?? response['started_at'] ?? '').toString();
      if (startedAtStr.isNotEmpty) {
        _serverStartedAt = DateTime.tryParse(startedAtStr)?.toUtc();
      }

      AppLogger.d('====================================================');
      AppLogger.d('[VOICE SESSION PARAMETERS]');
      AppLogger.d('  Caller ID        : $callerId');
      AppLogger.d('  Receiver ID      : $receiverId');
      AppLogger.d('  Agora App ID     : $appId');
      AppLogger.d('  Channel Name     : $channelName');
      AppLogger.d('  Agora Local UID  : $uid');
      AppLogger.d('====================================================');

      if (appId.isEmpty) {
        throw Exception("Agora App ID missing from server response");
      }

      bool effectiveIsCaller = widget.isCaller;
      if (callerId.isNotEmpty && currentUserId != 'unknown' && callerId.trim() != currentUserId.trim()) {
        AppLogger.d('[VOICE CALL] Session was initiated by remote user ($callerId). Current user ($currentUserId) joining as callee.');
        effectiveIsCaller = false;
      }

      final callerName = (response['caller_name'] ?? response['voice_session']?['caller_name'] ?? '').toString().trim();
      final recipientName = (response['recipient_name'] ?? response['receiver_name'] ?? response['voice_session']?['recipient_name'] ?? response['voice_session']?['receiver_name'] ?? '').toString().trim();

      String targetParticipantName = '';
      if (effectiveIsCaller) {
        // Patient calling Midwife -> Target display MUST be Midwife (recipient)
        targetParticipantName = recipientName.isNotEmpty
            ? recipientName
            : (widget.appointment.midwifeName ?? 'Midwife');
      } else {
        // Midwife receiving call from Patient -> Target display MUST be Patient (caller)
        targetParticipantName = callerName.isNotEmpty
            ? callerName
            : (widget.appointment.userFullName ?? 'Patient');
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

      await _agoraVoiceService.initialize(appId);

      if (_isEndingCall || !mounted) {
        AppLogger.d('[VOICE CALL INIT] Aborted post-init because call was cancelled.');
        await _agoraVoiceService.dispose();
        return;
      }

      _joinSuccessSub = _agoraVoiceService.onJoinSuccess.listen((_) {
        AppLogger.d("[AGORA RTC] Channel joined successfully: $channelName (localUid: $uid)");
        RingtoneService.stopRingtone();
        if (mounted) {
          setState(() {
            _isRinging = false;
            if (!_isCaller || kIsWeb || _isConnected) {
              _isConnected = true;
              _startTimer(startedAt: _serverStartedAt);
            }
          });
          _agoraVoiceService.toggleMute(_isMuted);
          _agoraVoiceService.toggleSpeaker(_isSpeakerOn);
        }
      });

      _userJoinedSub = _agoraVoiceService.onUserJoined.listen((remoteUid) {
        AppLogger.d("[AGORA RTC] Remote user joined channel: remoteUid=$remoteUid");
        RingtoneService.stopRingtone();
        if (mounted) {
          setState(() {
            _isConnected = true;
            _isRinging = false;
            _startTimer(startedAt: _serverStartedAt);
          });
          _agoraVoiceService.toggleMute(_isMuted);
          _agoraVoiceService.toggleSpeaker(_isSpeakerOn);
        }
      });

      _userOfflineSub = _agoraVoiceService.onUserOffline.listen((event) {
        final remoteUid = event['uid'];
        final reason = event['reason'];
        AppLogger.d("[AGORA RTC] Remote user $remoteUid went offline, reason: $reason");
        if (reason != null && reason.toString().contains('userOfflineDropped')) {
          AppLogger.d("[AGORA RTC] Remote user dropped temporarily. Waiting for reconnect...");
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Remote connection interrupted. Reconnecting...'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          _endCall();
        }
      });

      _errorSub = _agoraVoiceService.onError.listen((err) {
        AppLogger.d("[AGORA RTC ERROR] $err");
      });

      if (_isCaller) {
        RingtoneService.playOutgoingRingback();
        if (mounted) {
          setState(() {
            _isRinging = true;
          });
        }
        // Hard cap so the caller never rings forever if the callee never
        // receives the offer (e.g. push not delivered / device off).
        _ringTimeoutTimer?.cancel();
        _ringTimeoutTimer = Timer(Duration(seconds: _ringTimeoutSeconds), () {
          if (!_isEndingCall && _isRinging && !_isConnected && mounted) {
            AppLogger.d('VoiceCallScreen: Ring timeout reached — auto-cancelling unanswered call');
            _endCall();
          }
        });
      } else {
        RingtoneService.playIncomingRingtone();
        if (mounted) {
          setState(() {
            _isRinging = true;
          });
        }
      }

      await _agoraVoiceService.joinChannel(
        channelId: channelName,
        token: rtcToken,
        uid: uid,
      );

      if (_isEndingCall) {
        AppLogger.d('[VOICE CALL INIT] Interrupted post-joinChannel. Leaving channel immediately.');
        await _agoraVoiceService.leaveChannel();
        await _agoraVoiceService.dispose();
      }
    } catch (e) {
      RingtoneService.stopRingtone();
      AppLogger.d("Failed to initialize call: $e");
      if (mounted && !_isEndingCall) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  void _startTimer({DateTime? startedAt}) {
    RingtoneService.stopRingtone();
    _statusTimer?.cancel();
    _statusTimer = null;
    _timer?.cancel();
    final now = DateTime.now().toUtc();

    if (startedAt != null) {
      final ageInSeconds = now.difference(startedAt).inSeconds.abs();
      // Only trust server timestamp if it's recent (within the last 1 hour)
      if (ageInSeconds < 3600) {
        _callStartTime = startedAt;
      }
    }
    _callStartTime ??= now;

    final initialDiff = now.difference(_callStartTime!).inSeconds;
    _secondsElapsed = (initialDiff >= 0 && initialDiff < 86400) ? initialDiff : 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConnected && mounted) {
        final diff = DateTime.now().toUtc().difference(_callStartTime!).inSeconds;
        setState(() {
          _secondsElapsed = (diff >= 0 && diff < 86400) ? diff : 0;
        });
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _agoraVoiceService.toggleMute(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _agoraVoiceService.toggleSpeaker(_isSpeakerOn);
  }

  Future<void> _handleCallTerminated(CallSignalType signalType) async {
    if (_isEndingCall) return;
    _isEndingCall = true;
    _hasInitializedToken = true;
    _isInitializingToken = false;

    AppLogger.d('[CALL STATE RESET] _handleCallTerminated started: signalType=$signalType');

    RingtoneService.stopRingtone();
    GlobalCallService.isCallActive = false;
    _timer?.cancel();
    _ringTimeoutTimer?.cancel();

    try {
      await _agoraVoiceService.leaveChannel();
    } catch (_) {}

    try {
      await _agoraVoiceService.dispose();
    } catch (_) {}

    try {
      if (!kIsWeb) {
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (_) {}

    AppLogger.d('[CALL] Cleanup complete');

    if (mounted) {
      final message = (signalType == CallSignalType.callDeclined)
          ? 'Call declined'
          : (signalType == CallSignalType.callCancelled)
              ? 'Call cancelled'
              : 'Call ended';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  Future<void> _endCall() async {
    if (_isEndingCall) return;
    _isEndingCall = true;
    _hasInitializedToken = true;
    _isInitializingToken = false;

    RingtoneService.stopRingtone();
    GlobalCallService.isCallActive = false;
    _timer?.cancel();
    _statusTimer?.cancel();
    _statusTimer = null;
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;

    try {
      GlobalCallService.sendCallEvent({
        'type': 'end_call',
        'action': 'end_call',
        'event': 'call_ended',
        'consultation_id': widget.consultationId,
        'appointment_id': widget.appointment.appointmentId,
      });
      AppLogger.d('sendCallEvent end_call sent successfully');
    } catch (e) {
      AppLogger.d('sendCallEvent failed: $e');
    }

    try {
      await _agoraVoiceService.leaveChannel();
      AppLogger.d('leaveChannel succeeded');
    } catch (e) {
      AppLogger.d('leaveChannel failed: $e');
    }

    try {
      await _agoraVoiceService.dispose();
      AppLogger.d('Agora dispose succeeded');
    } catch (e) {
      AppLogger.d('Agora dispose failed: $e');
    }

    try {
      await _apiService.endVoiceSession(widget.consultationId);
      AppLogger.d('endVoiceSession API succeeded');
    } catch (e) {
      AppLogger.d('endVoiceSession API failed: $e');
    }

    try {
      if (!kIsWeb) {
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (e) {
      AppLogger.d('CallKit endAllCalls failed: $e');
    }

    AppLogger.d('[CALL] Cleanup complete');

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _isEndingCall = true;
    RingtoneService.stopRingtone();
    GlobalCallService.isCallActive = false;
    _timer?.cancel();
    _statusTimer?.cancel();
    _statusTimer = null;
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
    _callEventSub?.cancel();
    _userJoinedSub?.cancel();
    _userOfflineSub?.cancel();
    _joinSuccessSub?.cancel();
    _errorSub?.cancel();
    _agoraVoiceService.dispose();
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
    final currentUserId = (GlobalCallService.currentUserId ?? '').trim();
    final patientId = widget.appointment.userId.trim();
    final patientName = (widget.appointment.userFullName ?? '').trim();
    final midwifeName = (widget.appointment.midwifeName ?? '').trim();

    bool isCurrentPatient = false;
    if (currentUserId.isNotEmpty && patientId.isNotEmpty && currentUserId == patientId) {
      isCurrentPatient = true;
    } else if (patientName.isNotEmpty && _participantName != null && _participantName!.trim().toLowerCase() == midwifeName.toLowerCase()) {
      isCurrentPatient = true;
    } else if (midwifeName.isNotEmpty && _participantName != null && _participantName!.trim().toLowerCase() == patientName.toLowerCase()) {
      isCurrentPatient = false;
    } else {
      isCurrentPatient = widget.appointment.appointmentType.toUpperCase().contains('PATIENT') || _isCaller;
    }

    String displayName = '';
    if (isCurrentPatient) {
      // Patient viewing screen -> ALWAYS display Midwife's name to Patient
      if (midwifeName.isNotEmpty && midwifeName != 'Recipient' && midwifeName != 'Caller' && midwifeName != 'Midwife') {
        displayName = midwifeName;
      } else if (_participantName != null &&
          _participantName!.isNotEmpty &&
          _participantName != 'Caller' &&
          _participantName != 'Recipient' &&
          _participantName != 'Patient' &&
          _participantName != 'Midwife') {
        displayName = _participantName!;
      } else {
        displayName = 'Midwife';
      }
    } else {
      // Midwife viewing screen -> ALWAYS display Patient's name to Midwife
      if (patientName.isNotEmpty && patientName != 'Recipient' && patientName != 'Caller' && patientName != 'Patient') {
        displayName = patientName;
      } else if (_participantName != null &&
          _participantName!.isNotEmpty &&
          _participantName != 'Caller' &&
          _participantName != 'Recipient' &&
          _participantName != 'Patient' &&
          _participantName != 'Midwife') {
        displayName = _participantName!;
      } else {
        displayName = 'Patient';
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
          child: Column(
            children: [
              // Header Bar (Matching reference image)
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
                          const SnackBar(
                            content: Text('Multi-party consultation available in group mode.'),
                            duration: Duration(seconds: 2),
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
                          // Outer Ripple Ring
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
                          // Inner Ripple Ring
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
                          // Main Avatar Circle
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

                  // Participant Name
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

                  // Consultation Voice Call Label / Duration Timer
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
                padding: const EdgeInsets.only(bottom: 48, left: 24, right: 24),
                child: _isRinging && !_isCaller
                    ? // FULL-SCREEN INCOMING CALL MODE (Ringing Callee): Symmetrical Accept & Decline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // DECLINE BUTTON (Red)
                          _buildTelegramCallCircleButton(
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            color: const Color(0xFFEF4444),
                            onTap: () async {
                              RingtoneService.stopRingtone();
                              GlobalCallService.isRingingShown = false;
                              try {
                                _apiService.declineVoiceSession(widget.consultationId);
                              } catch (e) {
                                AppLogger.d('VoiceCallScreen: Error declining: $e');
                              }
                              try {
                                GlobalCallService.declineCall(widget.consultationId);
                              } catch (_) {}
                              await _endCall();
                            },
                          ),

                          // ACCEPT BUTTON (Green)
                          _buildTelegramCallCircleButton(
                            icon: Icons.call_rounded,
                            label: 'Accept',
                            color: const Color(0xFF22C55E),
                            onTap: () async {
                              RingtoneService.stopRingtone();
                              GlobalCallService.isRingingShown = false;
                              try {
                                await _apiService.acceptVoiceSession(widget.consultationId);
                              } catch (e) {
                                AppLogger.d('VoiceCallScreen: Error accepting voice session: $e');
                              }
                              try {
                                GlobalCallService.sendCallEvent({
                                  'type': 'accept_call',
                                  'action': 'accept_call',
                                  'event': 'call_accepted',
                                  'consultation_id': widget.consultationId,
                                });
                              } catch (e) {
                                AppLogger.d('VoiceCallScreen: Error sending accept_call event: $e');
                              }
                              if (mounted) {
                                setState(() {
                                  _isRinging = false;
                                  _isConnected = true;
                                  _startTimer(startedAt: _serverStartedAt);
                                });
                                _agoraVoiceService.toggleMute(_isMuted);
                                _agoraVoiceService.toggleSpeaker(_isSpeakerOn);
                              }
                            },
                          ),
                        ],
                      )
                    : // ACTIVE VOICE CALL MODE (Voice-Only Controls: Speaker, Mute, End Call)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 1. Speaker
                          _buildTelegramActionButton(
                            icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            label: 'Speaker',
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

                          // 2. Mute
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

                          // 3. End Call
                          _buildTelegramActionButton(
                            icon: Icons.call_end_rounded,
                            label: _isRinging ? 'Cancel' : 'End Call',
                            bgColor: AppColors.errorRedBright,
                            iconColor: Colors.white,
                            onTap: () async {
                              RingtoneService.stopRingtone();
                              if (_isRinging) {
                                try {
                                  _apiService.declineVoiceSession(widget.consultationId);
                                } catch (e) {
                                  AppLogger.d('VoiceCallScreen: Error declining voice session: $e');
                                }
                              }
                              await _endCall();
                            },
                          ),
                        ],
                      ),
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