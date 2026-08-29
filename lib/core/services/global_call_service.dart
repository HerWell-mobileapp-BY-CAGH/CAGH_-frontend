import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cagh_frontend/main.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

enum CallSignalType {
  callOffer,
  callAccepted,
  callDeclined,
  callEnded,
  callCancelled,
  pingPong,
  unknown,
}

class GlobalCallService {
  static WebSocketChannel? _userCallChannel;
  static final Map<String, WebSocketChannel> _appointmentChannels = {};
  static Timer? _heartbeatTimer;
  static bool isRingingShown = false;
  static bool get _isRingingShown => isRingingShown;
  static set _isRingingShown(bool v) => isRingingShown = v;
  static bool isCallActive = false;
  static String? currentUserId;
  static bool _isListening = false;
  static bool _isExplicitClose = false;

  static Future<String?> getAuthenticatedUserId() async {
    final token = await _getSanitizedToken();
    return _getUserIdFromJwt(token);
  }

  static void showIncomingCallModal(Map<String, dynamic> data, String defaultAppointmentId) {
    _showIncomingCallModal(data, defaultAppointmentId);
  }

  static String extractId(dynamic val) {
    if (val == null) return '';
    if (val is Map) return (val['id'] ?? val['user_id'] ?? '').toString();
    return val.toString();
  }

  static String extractPersonName(Map<String, dynamic> data, {bool isSender = false}) {
    final topName = isSender
        ? (data['sender_name'] ?? data['sender_full_name'] ?? data['caller_name'] ?? data['patient_name'] ?? data['user_full_name'])
        : (data['receiver_name'] ?? data['receiver_full_name'] ?? data['recipient_name'] ?? data['midwife_name'] ?? data['midwife_full_name']);
    if (topName != null && topName.toString().trim().isNotEmpty && topName.toString() != 'null') {
      return NameFormatter.format(topName.toString());
    }
    final keysToTry = isSender
        ? ['sender', 'caller', 'patient_detail', 'patient', 'user_detail', 'user']
        : ['receiver', 'recipient', 'midwife_detail', 'midwife_profile', 'midwife'];
    for (final key in keysToTry) {
      if (data[key] != null) {
        final res = NameFormatter.format(data[key].toString());
        if (res.isNotEmpty && res.toLowerCase() != 'recipient') return res;
      }
    }
    return isSender ? 'Caller' : 'Care Provider';
  }

  static CallSignalType parseSignalType(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['action'] ?? '').toString().toLowerCase();
    if (type.contains('offer')) return CallSignalType.callOffer;
    if (type.contains('accept')) return CallSignalType.callAccepted;
    if (type.contains('decline') || type.contains('reject')) return CallSignalType.callDeclined;
    if (type.contains('end') || type.contains('hangup') || type.contains('cancel')) return CallSignalType.callEnded;
    if (type.contains('ping') || type.contains('pong')) return CallSignalType.pingPong;
    return CallSignalType.unknown;
  }

  static final StreamController<Map<String, dynamic>> _callEventController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onCallEvent => _callEventController.stream;

  static void sendCallEvent(Map<String, dynamic> event) {
    _callEventController.add(event);
  }

  static String? _getUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decodedBytes = base64Url.decode(payload);
      final decodedMap = jsonDecode(utf8.decode(decodedBytes));
      if (decodedMap is Map) {
        final id = decodedMap['user_id'] ?? decodedMap['id'] ?? decodedMap['user']?['id'] ?? decodedMap['sub'];
        return id?.toString();
      }
    } catch (e) {
      debugPrint('Error decoding JWT user_id: $e');
    }
    return null;
  }

  static Future<String> _getSanitizedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? prefs.getString('access') ?? '';
    var token = rawToken.trim();
    if (token.startsWith('Bearer ')) token = token.substring(7).trim();
    return token.replaceAll('"', '').replaceAll("'", '').trim();
  }

  static Future<void> initUserCallListener({bool force = false}) async {
    if (!force && _isListening && _userCallChannel != null) {
      debugPrint('GlobalCallService: Already actively listening on user-calls WebSocket');
      return;
    }

    try {
      final token = await _getSanitizedToken();
      if (token.isEmpty) {
        debugPrint('GlobalCallService: Token is empty, skipping listener');
        return;
      }

      currentUserId = _getUserIdFromJwt(token);
      debugPrint('GlobalCallService: currentUserId = $currentUserId');

      final wsUrlString = '${ApiConfig.wsUrl}/user-calls/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      
      _heartbeatTimer?.cancel();
      _isExplicitClose = true;
      _userCallChannel?.sink.close();
      _isExplicitClose = false;

      _userCallChannel = WebSocketChannel.connect(wsUrl);
      _isListening = true;
      debugPrint('GlobalCallService: Listening on user-calls WebSocket');

      _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
        try {
          if (_userCallChannel != null) {
            _userCallChannel!.sink.add(jsonEncode({'type': 'ping', 'action': 'ping'}));
          }
        } catch (_) {}
      });

      _userCallChannel!.stream.listen(
        (message) {
          try {
            debugPrint('[CALLER RECEIVED] GlobalCallService user-calls frame: $message');
            final data = jsonDecode(message);
            final eventType = (data['type'] ?? data['action'] ?? '').toString();
            final senderId = (data['sender_id'] ?? data['sender']?['id'] ?? '').toString();

            if (eventType == 'pong') return;

            // Broadcast all non-pong events to local listeners (_callEventController)
            sendCallEvent(data);

            // Ignore calls initiated by oneself
            if (currentUserId != null && currentUserId!.isNotEmpty && senderId == currentUserId) {
              debugPrint('GlobalCallService: Ignoring self call offer');
              return;
            }

            final typeLower = eventType.toLowerCase();
            if (typeLower.contains('incoming') || typeLower.contains('offer') || typeLower.contains('initiated')) {
              if (!_isRingingShown && !isCallActive) {
                showIncomingCallModal(data, data['consultation_id']?.toString() ?? '');
              }
            } else if (typeLower.contains('ended') || typeLower.contains('cancelled') || typeLower.contains('declined')) {
              if (!isCallActive && !kIsWeb) {
                try {
                  FlutterCallkitIncoming.endAllCalls();
                  RingtoneService.stopRingtone();
                  _isRingingShown = false;
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('User call listener parse error: $e');
          }
        },
        onError: (e) {
          debugPrint('User call WebSocket error: $e');
        },
        onDone: () {
          final code = _userCallChannel?.closeCode;
          _isListening = false;
          debugPrint('User call WebSocket closed (code: $code)');
          if (_isExplicitClose || code == 4001 || code == 4003) {
            debugPrint('Stopping reconnect loop (explicit close or code: $code)');
            _heartbeatTimer?.cancel();
            return;
          }
          _scheduleUserCallReconnect();
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize user call listener: $e');
    }
  }

  static void _scheduleUserCallReconnect() {
    _heartbeatTimer?.cancel();
    Timer(const Duration(seconds: 3), () {
      initUserCallListener();
    });
  }

  static Future<void> initMultiple(List<String> appointmentIds) async {
    await initUserCallListener();
    try {
      final token = await _getSanitizedToken();
      if (token.isEmpty) return;

      for (var id in appointmentIds) {
        if (id.isEmpty || id == 'null') continue;
        if (_appointmentChannels.containsKey(id)) continue;

        final wsUrlString = '${ApiConfig.wsUrl}/consultation/$id/?token=$token';
        final wsUrl = Uri.parse(wsUrlString);
        final channel = WebSocketChannel.connect(wsUrl);
        _appointmentChannels[id] = channel;
        debugPrint('GlobalCallService: Listening on appointment WebSocket: $id');

        channel.stream.listen(
          (message) {
            try {
              debugPrint('[CALLER RECEIVED] AppointmentCallService frame ($id): $message');
              final data = jsonDecode(message);
              final eventType = (data['type'] ?? data['action'] ?? '').toString();
              final senderId = (data['sender_id'] ?? data['sender']?['id'] ?? '').toString();

              // Broadcast to local call subscribers
              sendCallEvent(data);

              if (currentUserId != null && currentUserId!.isNotEmpty && senderId == currentUserId) {
                return;
              }

              final typeLower = eventType.toLowerCase();
              if (typeLower.contains('incoming') || typeLower.contains('offer') || typeLower.contains('initiated')) {
                if (!_isRingingShown && !isCallActive) {
                  showIncomingCallModal(data, id);
                }
              }
            } catch (e) {
              debugPrint('Appointment call listener error: $e');
            }
          },
          onError: (e) {
            _appointmentChannels.remove(id);
          },
          onDone: () {
            _appointmentChannels.remove(id);
          },
        );
      }
    } catch (e) {
      debugPrint('Error in initMultiple: $e');
    }
  }

  static Future<void> init(String appointmentId) async {
    await initMultiple([appointmentId]);
  }

  static void declineCall(String consultationId) async {
    try {
      debugPrint('[DECLINE SENT] Callee tapped decline for consultation: $consultationId');
      
      RingtoneService.stopRingtone();
      _isRingingShown = false;

      sendCallEvent({
        'type': 'call_declined',
        'action': 'call_declined',
        'consultation_id': consultationId,
      });

      final token = await _getSanitizedToken();
      if (token.isEmpty || consultationId.isEmpty || consultationId == 'null') return;

      if (_appointmentChannels.containsKey(consultationId)) {
        _appointmentChannels[consultationId]?.sink.add(jsonEncode({
          'action': 'call_declined',
          'type': 'call_declined',
          'consultation_id': consultationId,
        }));
        debugPrint('[DECLINE SENT] Sent via existing appointment channel for consultation: $consultationId');
        return;
      }

      final wsUrlString = '${ApiConfig.wsUrl}/consultation/$consultationId/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      final channel = WebSocketChannel.connect(wsUrl);
      
      await Future.delayed(const Duration(milliseconds: 250));
      channel.sink.add(jsonEncode({
        'action': 'call_declined',
        'type': 'call_declined',
        'consultation_id': consultationId,
      }));
      debugPrint('[DECLINE SENT] Sent via temporary WebSocket channel for consultation: $consultationId');
      await Future.delayed(const Duration(milliseconds: 300));
      channel.sink.close();
    } catch (e) {
      debugPrint('Failed to send declineCall WS frame: $e');
    }
  }

  static String? _lastCallDeduplicationId;

  static void _showIncomingCallModal(Map<String, dynamic> data, String defaultAppointmentId) {
    final context = globalNavigatorKey.currentContext;
    final consultationId = (data['consultation_id'] ?? data['call_id'] ?? defaultAppointmentId).toString();

    if (_lastCallDeduplicationId == consultationId && (_isRingingShown || isCallActive)) {
      AppLogger.d('[CALL][DEDUP] Duplicate call ignored for consultation $consultationId');
      return;
    }

    if (context == null || _isRingingShown || isCallActive) {
      return;
    }

    _lastCallDeduplicationId = consultationId;
    _isRingingShown = true;
    AppLogger.d('[CALL][UI] Incoming call UI shown for consultation $consultationId');
    RingtoneService.playIncomingRingtone();

    final rawName = (data['sender_name'] ?? data['sender_full_name'] ?? data['caller_name'] ?? 'Care Provider').toString();
    final callerName = NameFormatter.format(rawName);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _IncomingCallOverlayCardWidget(
          callerName: callerName,
          onTapCard: () {
            _isRingingShown = false;
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            final mapExtra = Map<String, dynamic>.from(data);
            final callerId = extractId(mapExtra['caller_id'] ?? mapExtra['sender_id'] ?? mapExtra['caller'] ?? mapExtra['sender'] ?? mapExtra['user_id']);
            final receiverId = extractId(mapExtra['receiver_id'] ?? mapExtra['recipient_id'] ?? mapExtra['receiver'] ?? mapExtra['recipient'] ?? mapExtra['midwife_id']);
            final receiverName = extractPersonName(mapExtra, isSender: false);
            final recipientDisplayName = receiverName.isNotEmpty && receiverName != 'Recipient' ? receiverName : 'Midwife';

            globalNavigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                  consultationId: consultationId,
                  appointment: Appointment(
                    appointmentId: consultationId,
                    userId: callerId,
                    midwifeId: receiverId,
                    date: '',
                    startTime: '',
                    endTime: '',
                    appointmentType: 'VIRTUAL_VOICE',
                    status: AppointmentStatus.confirmed,
                    userFullName: callerName,
                    midwifeName: recipientDisplayName,
                  ),
                  isCaller: false,
                  isIncomingCall: true,
                ),
              ),
            );
          },
          onDecline: () {
            RingtoneService.stopRingtone();
            _isRingingShown = false;
            declineCall(consultationId);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          onAccept: () {
            RingtoneService.stopRingtone();
            _isRingingShown = false;
            isCallActive = true;
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            globalNavigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => VoiceConsultationScreen(
                  consultationId: consultationId,
                  midwifeName: callerName,
                  phoneNumber: 'Active Call',
                  isCaller: false,
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    ).then((_) {
      RingtoneService.stopRingtone();
    });
  }

  static void dispose() {
    _heartbeatTimer?.cancel();
    RingtoneService.stopRingtone();
    _userCallChannel?.sink.close();
    for (var channel in _appointmentChannels.values) {
      channel.sink.close();
    }
    _appointmentChannels.clear();
    _isRingingShown = false;
    isCallActive = false;
  }
}

class _IncomingCallOverlayCardWidget extends StatefulWidget {
  final String callerName;
  final VoidCallback onTapCard;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  const _IncomingCallOverlayCardWidget({
    required this.callerName,
    required this.onTapCard,
    required this.onDecline,
    required this.onAccept,
  });

  @override
  State<_IncomingCallOverlayCardWidget> createState() => _IncomingCallOverlayCardWidgetState();
}

class _IncomingCallOverlayCardWidgetState extends State<_IncomingCallOverlayCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'DM';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(widget.callerName);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28, left: 16, right: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTapCard,
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.black12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Double-Ring Avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Pulsing Ring
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF315E26).withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        // Inner Border Ring
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF315E26).withValues(alpha: 0.3),
                              width: 2.5,
                            ),
                          ),
                        ),
                        // Main Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF315E26),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Caller Name (Strongest Text Element)
                Text(
                  widget.callerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 4),

                // Status Line
                const Text(
                  'Incoming voice call',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Security Badge (Understated Shield Badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 13, color: Color(0xFF315E26)),
                      SizedBox(width: 4),
                      Text(
                        'Encrypted Call',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: widget.onDecline,
                            splashColor: Colors.white24,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEF4444),
                              ),
                              child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Decline',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Accept Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: widget.onAccept,
                            splashColor: Colors.white24,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF315E26),
                              ),
                              child: const Icon(Icons.call, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accept',
                          style: TextStyle(
                            color: Color(0xFF315E26),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
