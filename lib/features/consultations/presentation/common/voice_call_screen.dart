import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/webrtc_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';

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

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  
  // Timer state
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isConnected = false;

  final WebrtcService _webrtcService = WebrtcService();
  final ConsultationApiService _apiService = ConsultationApiService();
  late StreamSubscription<RTCPeerConnectionState> _connectionStateSub;
  late StreamSubscription<RTCSessionDescription> _incomingCallSub;
  late StreamSubscription<void> _callAnsweredSub;
  late StreamSubscription<void> _callEndedSub;
  RTCSessionDescription? _incomingOffer;
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    GlobalCallService.isCallActive = true;
    _initializeCall();
  }

  void _initializeCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await _apiService.startConsultation(widget.consultationId);
      final baseWsUrl = response['ws_url'] ?? response['consultation']?['voice_session']?['ws_signaling_url'];
      final sessionKey = response['session_key'] ?? response['consultation']?['voice_session']?['session_key'] ?? response['consultation']?['voice_session']?['rtc_token'];
      
      if (baseWsUrl == null) throw Exception("Failed to get signaling URL");

      // Construct final WebSocket URL with token and session_key
      final wsUrl = '$baseWsUrl${baseWsUrl.contains('?') ? '&' : '?'}token=$token${sessionKey != null ? '&session_key=$sessionKey' : ''}';

      _connectionStateSub = _webrtcService.connectionStateStream.listen((state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
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
          if (mounted) _endCall();
        }
      });

      _callAnsweredSub = _webrtcService.callAnsweredStream.listen((_) {
        if (mounted && !_isConnected) {
          setState(() {
            _isConnected = true;
            _isRinging = false;
            _startTimer();
          });
        }
      });

      _callEndedSub = _webrtcService.callEndedStream.listen((_) {
        _endCall();
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
    } catch (e) {
      RingtoneService.stopRingtone();
      debugPrint("Failed to initialize call: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 10)),
        );
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

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _webrtcService.toggleMute(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _webrtcService.toggleSpeaker(_isSpeakerOn);
  }

  void _endCall() {
    RingtoneService.stopRingtone();
    _timer?.cancel();
    _webrtcService.dispose();
    if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final participantName = widget.appointment.userFullName ?? 'Patient';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: Stack(
          children: [
            // Hidden video element to play incoming WebRTC audio on web & mobile
            SizedBox(
              width: 1,
              height: 1,
              child: RTCVideoView(_webrtcService.remoteRenderer),
            ),
            Column(
              children: [
            // Header
            Container(
              color: const Color(0xFF315E26),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.amber),
                    onPressed: () {
                      // Depending on logic, this might background the call instead of ending it
                      Navigator.of(context).pop();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Voice Consultation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF315E26),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the back button
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Picture
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF315E26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF315E26).withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://i.pravatar.cc/300?u=$participantName', // Placeholder
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.person, size: 64, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name
                  Text(
                    participantName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E291B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Phone Number or Status
                  Text(
                    '+251-995-756-55', // Placeholder, use appointment.userPhone if available
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF315E26),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Status / Timer
                  if (_isRinging)
                    const Text(
                      'Ringing...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF315E26),
                      ),
                    )
                  else
                    Text(
                      _isConnected ? _formatDuration(_secondsElapsed) : 'Connecting...',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF315E26),
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
            
            // Bottom Controls
            if (_isRinging)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'Decline',
                          color: Colors.red,
                          onTap: () {
                            _webrtcService.declineCall();
                            _endCall();
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.call,
                          label: 'Accept',
                          color: Colors.green,
                          onTap: () {
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
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: 'Mute',
                          isActive: _isMuted,
                          onTap: _toggleMute,
                        ),
                        _buildControlButton(
                          icon: Icons.volume_up,
                          label: 'Speaker',
                          isActive: _isSpeakerOn,
                          onTap: _toggleSpeaker,
                        ),
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'End Call',
                          color: Colors.red,
                          onTap: _endCall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    VoidCallback? onPressed,
    bool isActive = false,
    Color? color,
  }) {
    final action = onTap ?? onPressed;
    final btnColor = color ?? (isActive ? Colors.grey.shade300 : Colors.grey.shade200);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: action,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: btnColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color != null ? Colors.white : (isActive ? Colors.black87 : Colors.black54),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end,
              color: const Color(0xFF315E26),
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'End Call',
          style: TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}