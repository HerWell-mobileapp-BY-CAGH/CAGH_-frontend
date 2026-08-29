import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cagh_frontend/main.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';

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
  static bool _isRingingShown = false;
  static bool isCallActive = false;
  static String? currentUserId;
  static bool _isListening = false;
  static bool _isExplicitClose = false;

  static bool get isRingingShown => _isRingingShown;
  static set isRingingShown(bool val) => _isRingingShown = val;

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
            debugPrint('GlobalCallService RECEIVED: $message');
            final data = jsonDecode(message);
            final eventType = (data['type'] ?? data['action'] ?? '').toString();
            final senderId = (data['sender_id'] ?? data['sender']?['id'] ?? '').toString();

            if (eventType == 'pong') return;

            // Ignore calls initiated by oneself
            if (currentUserId != null && currentUserId!.isNotEmpty && senderId == currentUserId) {
              debugPrint('GlobalCallService: Ignoring self call offer');
              return;
            }

            if (eventType == 'incoming_call_offer' || eventType == 'call_offer' || eventType == 'offer') {
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
              debugPrint('AppointmentCallService RECEIVED ($id): $message');
              final data = jsonDecode(message);
              final eventType = (data['type'] ?? data['action'] ?? '').toString();
              final senderId = (data['sender_id'] ?? data['sender']?['id'] ?? '').toString();

              if (currentUserId != null && currentUserId!.isNotEmpty && senderId == currentUserId) {
                return;
              }

              if (eventType == 'incoming_call_offer' || eventType == 'call_offer' || eventType == 'offer') {
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
      final token = await _getSanitizedToken();
      if (token.isEmpty || consultationId.isEmpty || consultationId == 'null') return;

      final wsUrlString = '${ApiConfig.wsUrl}/consultation/$consultationId/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      final channel = WebSocketChannel.connect(wsUrl);
      
      // Allow WebSocket connection to open before sending frame
      await Future.delayed(const Duration(milliseconds: 250));
      channel.sink.add(jsonEncode({
        'action': 'end_call',
        'type': 'end_call',
      }));
      await Future.delayed(const Duration(milliseconds: 400));
      channel.sink.close();
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
    final rawName = (data['sender_name'] ?? data['sender_full_name'] ?? 'Care Provider').toString();
    final callerName = NameFormatter.format(rawName);
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 12, color: Colors.white70),
                SizedBox(width: 4),
                Text(
                  'End-to-End Encrypted Voice Call',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
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
