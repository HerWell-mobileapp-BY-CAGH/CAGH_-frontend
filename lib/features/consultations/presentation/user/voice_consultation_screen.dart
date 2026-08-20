import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/webrtc_service.dart';
import '../../data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';

class VoiceConsultationScreen extends StatefulWidget {
  final String consultationId;
  final String midwifeName;
  final String phoneNumber;
  final bool isCaller;

  const VoiceConsultationScreen({
    super.key,
    required this.consultationId,
    required this.midwifeName,
    required this.phoneNumber,
    this.isCaller = true,
  });

  @override
  State<VoiceConsultationScreen> createState() => _VoiceConsultationScreenState();
}

class _VoiceConsultationScreenState extends State<VoiceConsultationScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false; // Usually voice calls start with earpiece, not speaker
  bool _isConnected = false;
  
  final WebrtcService _webrtcService = WebrtcService();
  final ConsultationApiService _apiService = ConsultationApiService();
  late StreamSubscription<RTCPeerConnectionState> _connectionStateSub;
  late StreamSubscription<RTCSessionDescription> _incomingCallSub;
  late StreamSubscription<void> _callAnsweredSub;
  late StreamSubscription<void> _callEndedSub;
  late StreamSubscription<String> _debugSub;
  RTCSessionDescription? _incomingOffer;
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? prefs.getString('access') ?? '';
      var token = rawToken.trim();
      if (token.startsWith('Bearer ')) token = token.substring(7).trim();
      token = token.replaceAll('"', '').replaceAll("'", '').trim();

      final response = await _apiService.startConsultation(widget.consultationId);
      final baseWsUrl = response['ws_url'] ?? response['consultation']?['voice_session']?['ws_signaling_url'] ?? '${ApiConfig.wsUrl}/consultation/${widget.consultationId}/';
      final sessionKey = response['session_key'] ?? response['consultation']?['voice_session']?['session_key'] ?? response['consultation']?['voice_session']?['rtc_token'];

      if (baseWsUrl != null) {
        final wsUrl = '$baseWsUrl${baseWsUrl.contains('?') ? '&' : '?'}token=$token${sessionKey != null ? '&session_key=$sessionKey' : ''}';
        _connectionStateSub = _webrtcService.connectionStateStream.listen((state) {
          if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _webrtcService.toggleSpeaker(_isSpeaker);
            if (mounted && !_isConnected) {
              setState(() {
                _isConnected = true;
                _isRinging = false;
                _startTimer();
              });
            }
          } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected || 
              state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
              state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
            if (mounted) Navigator.pop(context);
          }
        });

        _callAnsweredSub = _webrtcService.callAnsweredStream.listen((_) {
          _webrtcService.toggleSpeaker(_isSpeaker);
          if (mounted && !_isConnected) {
            setState(() {
              _isConnected = true;
              _isRinging = false;
              _startTimer();
            });
          }
        });

        _callEndedSub = _webrtcService.callEndedStream.listen((_) {
          RingtoneService.stopRingtone();
          GlobalCallService.isCallActive = false;
          _timer?.cancel();
          _webrtcService.dispose();
          if (mounted) Navigator.pop(context);
        });

      _incomingCallSub = _webrtcService.incomingCallStream.listen((offer) async {
        if (mounted) {
          setState(() {
            _isRinging = true;
            _incomingOffer = offer;
          });
          await _webrtcService.acceptCall(offer);
          if (mounted && !_isConnected) {
            setState(() {
              _isConnected = true;
              _isRinging = false;
              _startTimer();
            });
          }
        }
      });

        if (widget.isCaller) {
          RingtoneService.playOutgoingRingback();
        }
        await _webrtcService.connect(wsUrl, widget.isCaller);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 10)),
        );
        // Do not pop, let the user read the error
      }
    }
  }

  void _startTimer() {
    RingtoneService.stopRingtone();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConnected) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    RingtoneService.stopRingtone();
    GlobalCallService.isCallActive = false;
    _timer?.cancel();
    _connectionStateSub.cancel();
    _incomingCallSub.cancel();
    _callAnsweredSub.cancel();
    _callEndedSub.cancel();
    _webrtcService.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF315E26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Voice Consultation',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Hidden RTCVideoView to attach WebRTC Audio Stream to DOM
          SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0.01,
              child: RTCVideoView(_webrtcService.remoteRenderer),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Profile Picture
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: const AssetImage('assets/images/home_illustration.png'),
                      // Fallback icon if image doesn't exist
                      child: const Icon(Icons.person, size: 60, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    NameFormatter.format(widget.midwifeName),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 13, color: Color(0xFF315E26)),
                        SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF315E26),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isRinging)
                    const Text(
                      'Ringing...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54,
                      ),
                    )
                  else
                    Text(
                      _isConnected ? _formatTime(_secondsElapsed) : 'Connecting...',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF315E26),
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isRinging)
            Padding(
              padding: const EdgeInsets.only(bottom: 60, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: Colors.red,
                    isEndCall: true,
                    onTap: () {
                      RingtoneService.stopRingtone();
                      _webrtcService.declineCall();
                      GlobalCallService.isCallActive = false;
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.call,
                    label: 'Accept',
                    color: Colors.green,
                    onTap: () {
                      RingtoneService.stopRingtone();
                      if (_incomingOffer != null) {
                        _webrtcService.acceptCall(_incomingOffer!);
                        setState(() {
                          _isRinging = false;
                          _isConnected = true;
                          _startTimer();
                        });
                      }
                    },
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                    label: 'Mute',
                    isActive: _isMuted,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                      _webrtcService.toggleMute(_isMuted);
                    },
                  ),
                  _buildControlButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    isActive: _isSpeaker,
                    onTap: () {
                      setState(() {
                        _isSpeaker = !_isSpeaker;
                      });
                      _webrtcService.toggleSpeaker(_isSpeaker);
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End Call',
                    color: Colors.red,
                    isEndCall: true,
                    onTap: () async {
                      RingtoneService.stopRingtone();
                      await _webrtcService.declineCall();
                      GlobalCallService.isCallActive = false;
                      _timer?.cancel();
                      await _apiService.endVoiceSession(widget.consultationId);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEndCall = false,
    bool isActive = false,
    Color? color,
  }) {
    final btnColor = color ?? (isEndCall ? Colors.red : (isActive ? const Color(0xFF315E26) : const Color(0xFFF0F0F0)));
    final iconColor = isEndCall ? Colors.white : (isActive ? Colors.white : Colors.black87);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: btnColor,
              shape: BoxShape.circle,
              boxShadow: isActive ? [
                BoxShadow(
                  color: const Color(0xFF315E26).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isEndCall ? Colors.red : Colors.grey.shade700,
            fontWeight: isEndCall ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}