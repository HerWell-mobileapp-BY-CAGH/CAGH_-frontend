import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cagh_frontend/main.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';

class GlobalCallService {
  static WebSocketChannel? _userCallChannel;
  static final Map<String, WebSocketChannel> _appointmentChannels = {};
  static Timer? _heartbeatTimer;
  static bool _isRingingShown = false;
  static bool isCallActive = false;
  static String? currentUserId;

  static Future<void> initUserCallListener() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? prefs.getString('access') ?? '';
      var token = rawToken.trim();
      if (token.startsWith('Bearer ')) token = token.substring(7).trim();
      token = token.replaceAll('"', '').replaceAll("'", '');

      if (token.isEmpty) {
        debugPrint('GlobalCallService: Token is empty, skipping listener');
        return;
      }

      final userData = await AuthService.getUserData();
      currentUserId = (userData['id'] ?? userData['user_id'] ?? userData['pk'] ?? '').toString();

      final wsUrlString = '${ApiConfig.wsUrl}/user-calls/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      
      _heartbeatTimer?.cancel();
      _userCallChannel?.sink.close();
      _userCallChannel = WebSocketChannel.connect(wsUrl);
      debugPrint('GlobalCallService: Listening on user-calls WebSocket');

      // Keepalive heartbeat ping every 25 seconds for Render/Nginx proxies
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
            debugPrint('GlobalCallService RECEIVED: $message');
            final data = jsonDecode(message);
            final eventType = (data['type'] ?? data['action'] ?? '').toString();
            final senderId = (data['sender_id'] ?? data['sender']?['id'] ?? '').toString();

            if (eventType == 'pong') return;

            // Ignore calls initiated by oneself
            if (currentUserId != null && currentUserId!.isNotEmpty && senderId == currentUserId) {
              return;
            }

            if (eventType == 'incoming_call_offer' || eventType == 'call_offer') {
              if (!_isRingingShown && !isCallActive) {
                _showIncomingCallModal(data, data['consultation_id']?.toString() ?? '');
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
          debugPrint('User call WebSocket closed (code: $code)');
          if (code == 4001 || code == 4003) {
            debugPrint('Stopping reconnect loop due to unauthorized token/session (code: $code)');
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('access_token') ?? prefs.getString('access') ?? '';
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
              debugPrint('AppointmentCallService RECEIVED ($id): $message');
              final data = jsonDecode(message);
              final eventType = (data['type'] ?? data['action'] ?? '').toString();
              final senderId = (data['sender_id'] ?? data['sender']?['id'] ?? '').toString();

              if (currentUserId != null && currentUserId!.isNotEmpty && senderId == currentUserId) {
                return;
              }

              if (eventType == 'incoming_call_offer' || eventType == 'call_offer') {
                if (!_isRingingShown && !isCallActive) {
                  _showIncomingCallModal(data, id);
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
      debugPrint('Failed to initialize appointment call service: $e');
    }
  }

  static Future<void> init(String appointmentId) async {
    await initMultiple([appointmentId]);
  }

  static void declineCall(String consultationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('access_token') ?? prefs.getString('access') ?? '';
      if (token.isEmpty || consultationId.isEmpty || consultationId == 'null') return;

      final wsUrlString = '${ApiConfig.wsUrl}/consultation/$consultationId/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      final channel = WebSocketChannel.connect(wsUrl);
      channel.sink.add(jsonEncode({
        'action': 'end_call',
        'type': 'end_call',
      }));
      Future.delayed(const Duration(milliseconds: 500), () {
        channel.sink.close();
      });
    } catch (e) {
      debugPrint('Failed to send decline end_call: $e');
    }
  }

  static void _showIncomingCallModal(Map<String, dynamic> data, String defaultAppointmentId) {
    final context = globalNavigatorKey.currentContext;
    if (context == null || _isRingingShown || isCallActive) {
      return;
    }

    _isRingingShown = true;
    RingtoneService.playIncomingRingtone();
    final callerName = data['sender_name'] ?? 'Care Provider';
    final consultationId = data['consultation_id'] ?? defaultAppointmentId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF315E26),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text('Incoming Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              callerName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Incoming Voice Consultation...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton.icon(
            onPressed: () {
              RingtoneService.stopRingtone();
              _isRingingShown = false;
              declineCall(consultationId.toString());
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.call_end, color: Colors.redAccent),
            label: const Text('Decline', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              RingtoneService.stopRingtone();
              _isRingingShown = false;
              isCallActive = true;
              Navigator.pop(dialogContext);
              globalNavigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => VoiceConsultationScreen(
                    consultationId: consultationId.toString(),
                    midwifeName: callerName,
                    phoneNumber: 'Active Call',
                    isCaller: false,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.call),
            label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
