import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

enum GlobalWsState { disconnected, connecting, connected, reconnecting }

class GlobalCallWebSocketManager {
  static final GlobalCallWebSocketManager instance = GlobalCallWebSocketManager._internal();
  factory GlobalCallWebSocketManager() => instance;
  GlobalCallWebSocketManager._internal();

  GlobalWsState _state = GlobalWsState.disconnected;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  int _connectionGeneration = 0;
  bool _isExplicitClose = false;

  GlobalWsState get state => _state;

  bool send(Map<String, dynamic> data) {
    if (_state == GlobalWsState.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
        AppLogger.d('[GLOBAL_WS SENT] Frame transmitted: $data');
        return true;
      } catch (e) {
        _state = GlobalWsState.disconnected;
        AppLogger.d('[GLOBAL_WS] Send failed, marking disconnected: $e');
      }
    }
    return false;
  }

  Future<void> connect({bool force = false}) async {
    if (!force && (_state == GlobalWsState.connecting || _state == GlobalWsState.connected)) {
      AppLogger.d('[GLOBAL_WS] Already connected or connecting, skipping connect call');
      return;
    }

    final token = await _getSanitizedToken();
    if (token.isEmpty) {
      AppLogger.d('[GLOBAL_WS] Token is empty, skipping connection');
      return;
    }

    _connectionGeneration++;
    final currentGen = _connectionGeneration;
    _state = GlobalWsState.connecting;
    _reconnectTimer?.cancel();

    try {
      final wsUrlString = '${ApiConfig.wsUrl}/user-calls/?token=$token';
      final wsUrl = Uri.parse(wsUrlString);
      AppLogger.d('[GLOBAL_WS] Connecting (Gen $currentGen) to /ws/user-calls/');

      _isExplicitClose = true;
      _channel?.sink.close();
      _isExplicitClose = false;

      _channel = WebSocketChannel.connect(wsUrl);
      _state = GlobalWsState.connected;
      _reconnectAttempts = 0;

      _startHeartbeat(currentGen);
      _listenToStream(currentGen);
    } catch (e) {
      if (currentGen != _connectionGeneration) return;
      _state = GlobalWsState.disconnected;
      AppLogger.d('[GLOBAL_WS] Connection error (Gen $currentGen): $e');
      _scheduleReconnect(currentGen);
    }
  }

  void _startHeartbeat(int gen) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (gen != _connectionGeneration) return;
      if (_state == GlobalWsState.connected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping', 'action': 'ping'}));
        } catch (e) {
          AppLogger.d('[GLOBAL_WS] Ping failed (Gen $gen): $e');
        }
      }
    });
  }

  void _listenToStream(int gen) {
    final activeChannel = _channel;
    if (activeChannel == null) return;
    activeChannel.stream.listen(
      (message) {
        if (gen != _connectionGeneration) {
          AppLogger.d('[GLOBAL_WS] Ignoring message from stale connection (Gen $gen vs current $_connectionGeneration)');
          return;
        }
        try {
          AppLogger.d('[GLOBAL_WS RECEIVED] Frame (Gen $gen): $message');
          final data = jsonDecode(message);
          final eventType = (data['type'] ?? data['action'] ?? data['event'] ?? '').toString();
          if (eventType == 'pong' || eventType.toLowerCase() == 'ping') return;

          final typeLower = eventType.toLowerCase();
          final isTerminalSignal = typeLower.contains('ended') ||
              typeLower.contains('cancelled') ||
              typeLower.contains('declined');

          // For terminal signals (ended/cancelled/declined) we do NOT emit via
          // sendCallEvent here — teardownCall() will emit the single canonical
          // 'call_ended' event internally.  Emitting twice caused
          // VoiceCallScreen._callEventSub to fire twice producing duplicate
          // teardown attempts and duplicate log entries.
          if (!isTerminalSignal) {
            GlobalCallService.sendCallEvent(data);
          }

          if (typeLower.contains('incoming') ||
              typeLower.contains('offer') ||
              typeLower.contains('initiated') ||
              typeLower.contains('session_created') ||
              typeLower.contains('voice_session')) {
            final receiverId = GlobalCallService.extractId(data['receiver_id'] ?? data['receiver'] ?? data['recipient_id'] ?? data['recipient']);
            final currentUserId = GlobalCallService.currentUserId ?? '';
            if (currentUserId.isNotEmpty && receiverId.isNotEmpty && receiverId != currentUserId) {
              AppLogger.d('[GLOBAL_WS] Suppressing incoming offer for different user ($receiverId vs current $currentUserId)');
              return;
            }
            final event = IncomingCallEvent.fromMap(data, defaultConsultationId: data['consultation_id']?.toString() ?? '');
            PresentationCoordinator.present(event);
          } else if (isTerminalSignal) {
            final consultationId = (data['consultation_id'] ?? data['appointment_id'] ?? '').toString();
            final callId = (data['call_id'] ?? consultationId).toString();
            GlobalCallService.teardownCall(
              callId: callId,
              consultationId: consultationId,
              reason: typeLower.contains('declined')
                  ? CallTerminalReason.decline
                  : typeLower.contains('cancelled')
                      ? CallTerminalReason.cancel
                      : CallTerminalReason.hangup,
              source: 'websocket_call_ended',
            );
          } else {
            // For non-terminal signal types (e.g. call_accepted, ping/pong)
            // the frame has already been forwarded via sendCallEvent above.
          }
        } catch (e) {
          AppLogger.d('[GLOBAL_WS] Message parse error (Gen $gen): $e');
        }
      },
      onError: (e) {
        if (gen != _connectionGeneration) return;
        AppLogger.d('[GLOBAL_WS] Stream error (Gen $gen): $e');
      },
      onDone: () {
        if (gen != _connectionGeneration) {
          AppLogger.d('[GLOBAL_WS] Ignoring onDone from stale connection (Gen $gen vs current $_connectionGeneration)');
          return;
        }
        final code = activeChannel.closeCode;
        final reason = activeChannel.closeReason;
        _state = GlobalWsState.disconnected;
        _heartbeatTimer?.cancel();
        AppLogger.d('[GLOBAL_WS] Disconnected (Gen $gen, code: $code, reason: $reason)');

        if (!_isExplicitClose && code != 4001 && code != 4003) {
          _scheduleReconnect(gen);
        }
      },
    );
  }

  void _scheduleReconnect(int gen) {
    if (gen != _connectionGeneration) return;
    _reconnectAttempts++;
    final delaySec = _reconnectAttempts == 1
        ? 1
        : _reconnectAttempts == 2
            ? 2
            : _reconnectAttempts == 3
                ? 4
                : _reconnectAttempts == 4
                    ? 8
                    : 15;

    AppLogger.d('[GLOBAL_WS] Reconnect scheduled in ${delaySec}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      connect(force: true);
    });
  }

  void disconnectForLogout() {
    _connectionGeneration++;
    _isExplicitClose = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _state = GlobalWsState.disconnected;
    _isExplicitClose = false;
    AppLogger.d('[GLOBAL_WS] Global WebSocket disconnected for logout');
  }

  static Future<String> _getSanitizedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? '';
    var token = rawToken.trim();
    if (token.startsWith('Bearer ')) token = token.substring(7).trim();
    return token.replaceAll('"', '').replaceAll("'", '').trim();
  }
}
