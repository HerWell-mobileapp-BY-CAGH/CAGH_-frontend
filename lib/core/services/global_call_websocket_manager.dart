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

  // Liveness tracking for the heartbeat. Previously pings were sent but
  // never checked for a reply, so a half-open connection (device sleep,
  // NAT entry expiry, etc.) would look "connected" forever while silently
  // dropping every frame. We now require a pong within a bounded window
  // or we force a reconnect.
  DateTime? _lastPongAt;
  static const Duration _pongTimeout = Duration(seconds: 60);

  // NOTE: a previous `_isExplicitClose` flag was removed. It was dead code:
  // every code path that set it also incremented `_connectionGeneration` in
  // the same breath, so the onDone handler's generation check always
  // short-circuited before that flag was ever consulted. The generation
  // counter alone already correctly prevents reconnect-scheduling for any
  // connection that's been superseded or intentionally torn down.

  GlobalWsState get state => _state;

  bool send(Map<String, dynamic> data) {
    if (_state == GlobalWsState.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
        AppLogger.d('[GLOBAL_WS SENT] Frame transmitted: $data');
        return true;
      } catch (e) {
        AppLogger.d('[GLOBAL_WS] Send failed, marking disconnected: $e');
        // Previously this only flipped local state and returned false,
        // leaving nothing to actually drive a reconnect if the channel's
        // own onDone/onError never fires for this failure mode. Now we
        // proactively tear down and schedule a reconnect attempt.
        _state = GlobalWsState.disconnected;
        final gen = _connectionGeneration;
        _heartbeatTimer?.cancel();
        try {
          _channel?.sink.close();
        } catch (_) {}
        _scheduleReconnect(gen);
      }
    }
    return false;
  }

  Future<void> connect({bool force = false}) async {
    AppLogger.d('[WS RUNTIME V2] GlobalCallWebSocketManager.connect() ENTERED');
    if (!force && (_state == GlobalWsState.connecting || _state == GlobalWsState.connected)) {
      AppLogger.d('[GLOBAL_WS] Already connected or connecting, skipping connect call');
      return;
    }

    var token = await _getSanitizedToken();
    final initialValid = AuthService.isAccessTokenValid(token);

    bool refreshAttempted = false;
    bool refreshSucceeded = false;
    bool tokenChanged = false;

    if (!initialValid) {
      refreshAttempted = true;
      AppLogger.d('[WS AUTH V2] valid: false');
      AppLogger.d('[WS AUTH V2] refresh attempted: true');

      final oldToken = token;
      refreshSucceeded = await AuthService.forceTokenRefresh();

      if (refreshSucceeded) {
        token = await _getSanitizedToken();
        tokenChanged = (oldToken != token);
        AppLogger.d('[WS AUTH V2] refresh succeeded: true');
        AppLogger.d('[WS AUTH V2] token changed: $tokenChanged');
      } else {
        AppLogger.d('[WS AUTH V2] refresh succeeded: false');
        AppLogger.d('[WS AUTH V2] Refusing to open WebSocket with expired/invalid token. Connection aborted.');
        _state = GlobalWsState.disconnected;
        _reconnectTimer?.cancel();
        return;
      }
    }

    final hasToken = token.isNotEmpty;
    final tokenLength = token.length;
    final expSeconds = AuthService.getAccessTokenExpirationSeconds(token);
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final secondsUntilExpiry = expSeconds != null ? (expSeconds - nowSeconds) : -999999;
    final isFinalValid = AuthService.isAccessTokenValid(token);

    AppLogger.d('[WS AUTH V2] token exists: $hasToken');
    AppLogger.d('[WS AUTH V2] token length: $tokenLength');
    AppLogger.d('[WS AUTH V2] token exp: $expSeconds');
    AppLogger.d('[WS AUTH V2] current time: $nowSeconds');
    AppLogger.d('[WS AUTH V2] seconds remaining: $secondsUntilExpiry');
    AppLogger.d('[WS AUTH V2] valid: $isFinalValid');
    AppLogger.d('[WS AUTH V2] refresh attempted: $refreshAttempted');
    AppLogger.d('[WS AUTH V2] refresh succeeded: $refreshSucceeded');
    AppLogger.d('[WS AUTH V2] token changed: $tokenChanged');

    AppLogger.d('[WS] opening connection');
    AppLogger.d('[WS] token exp: $expSeconds');
    AppLogger.d('[WS] current time: $nowSeconds');
    AppLogger.d('[WS] seconds remaining: $secondsUntilExpiry');

    if (!hasToken || !isFinalValid) {
      AppLogger.d('[WS AUTH V2] Final token validation failed. Aborting WebSocket connection.');
      _state = GlobalWsState.disconnected;
      return;
    }

    if (GlobalCallService.currentUserId == null || GlobalCallService.currentUserId!.isEmpty) {
      await GlobalCallService.syncCurrentUserId();
    }

    _connectionGeneration++;
    final currentGen = _connectionGeneration;
    _state = GlobalWsState.connecting;
    _reconnectTimer?.cancel();

    try {
      final encodedToken = Uri.encodeComponent(token);
      final wsUrlString = '${ApiConfig.wsUrl}/user-calls/?token=$encodedToken';
      final wsUrl = Uri.parse(wsUrlString);
      AppLogger.d('[WS RUNTIME V2] ABOUT TO OPEN /ws/user-calls/');
      AppLogger.d('[WS] connecting (Gen $currentGen) to /ws/user-calls/');

      _channel?.sink.close();

      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;
      _state = GlobalWsState.connected;
      _reconnectAttempts = 0;
      _lastPongAt = DateTime.now();
      AppLogger.d('[WS] connected');

      _startHeartbeat(currentGen);
      _listenToStream(currentGen);
    } catch (e) {
      if (currentGen != _connectionGeneration) return;
      _state = GlobalWsState.disconnected;
      AppLogger.d('[WS] disconnected error (Gen $currentGen): $e');
      _scheduleReconnect(currentGen);
    }
  }

  void _startHeartbeat(int gen) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (gen != _connectionGeneration) return;
      if (_state == GlobalWsState.connected && _channel != null) {
        final since = _lastPongAt == null
            ? Duration.zero
            : DateTime.now().difference(_lastPongAt!);
        if (since > _pongTimeout) {
          AppLogger.d('[GLOBAL_WS] No pong received in ${since.inSeconds}s (Gen $gen); forcing reconnect');
          _heartbeatTimer?.cancel();
          _state = GlobalWsState.disconnected;
          try {
            _channel?.sink.close();
          } catch (_) {}
          _scheduleReconnect(gen);
          return;
        }
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
      (message) async {
        if (gen != _connectionGeneration) {
          AppLogger.d('[GLOBAL_WS] Ignoring message from stale connection (Gen $gen vs current $_connectionGeneration)');
          return;
        }
        try {
          final data = jsonDecode(message);
          final eventType = (data['type'] ?? data['action'] ?? data['event'] ?? '').toString();
          final typeLowerEarly = eventType.toLowerCase();
          if (typeLowerEarly == 'pong') {
            _lastPongAt = DateTime.now();
            return;
          }
          if (typeLowerEarly == 'ping') return;

          AppLogger.d('[GLOBAL_WS RECEIVED] Frame (Gen $gen): $message');

          final typeLower = typeLowerEarly;
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

          final consultationId = (data['consultation_id'] ?? data['appointment_id'] ?? '').toString();
          final callId = (data['call_id'] ?? consultationId).toString();
          final senderId = GlobalCallService.extractId(data['sender_id'] ?? data['caller_id'] ?? data['user_id'] ?? data['sender']);
          final recipientId = GlobalCallService.extractId(data['recipient_id'] ?? data['receiver_id'] ?? data['recipient'] ?? data['receiver']);
          final authUserId = GlobalCallService.currentUserId ?? '';

          AppLogger.d('[WS_SIGNAL_IN] action=$eventType consultation_id=$consultationId call_id=$callId sender_id=$senderId recipient_id=$recipientId auth_user_id=$authUserId');

          if (typeLower == 'webrtc_offer') {
            AppLogger.d('[WEBRTC_TRACE_20_OFFER_RECEIVED_CLIENT] consultation_id=$consultationId call_id=$callId sender_id=$senderId recipient_id=$recipientId auth_user_id=$authUserId');
          } else if (typeLower == 'webrtc_ice_candidate') {
            AppLogger.d('[WEBRTC_TRACE_32_REMOTE_ICE_RECEIVED] consultation_id=$consultationId call_id=$callId sender_id=$senderId recipient_id=$recipientId auth_user_id=$authUserId');
          }

          final isWebRtcSignal = typeLower == 'webrtc_offer' ||
              typeLower == 'webrtc_answer' ||
              typeLower == 'webrtc_ice_candidate';

          if (isWebRtcSignal) {
            // WebRTC SDP / ICE frame — handled by VoiceCallScreen via sendCallEvent above
          } else if (typeLower.contains('incoming') ||
              typeLower == 'call_offer' ||
              typeLower.contains('initiated') ||
              typeLower.contains('session_created') ||
              typeLower.contains('voice_session')) {
            final receiverId = GlobalCallService.extractId(data['receiver_id'] ?? data['receiver'] ?? data['recipient_id'] ?? data['recipient']);
            var currentUserId = GlobalCallService.currentUserId ?? '';
            if (currentUserId.isEmpty) {
              currentUserId = await GlobalCallService.syncCurrentUserId() ?? '';
            }
            final consultationId = (data['consultation_id'] ?? data['appointment_id'] ?? '').toString();
            final callId = (data['call_id'] ?? consultationId).toString();
            AppLogger.d('[CALL FLOW V2] call_offer received call_id=$callId consultation_id=$consultationId receiver_id=$receiverId current_user_id=$currentUserId');
            AppLogger.d('[CALL_TRACE] CALL_OFFER_RECEIVED call_id=$callId consultation_id=$consultationId receiver_id=$receiverId current_user_id=$currentUserId');

            // Fail CLOSED, not open: if we can't confirm who this offer is
            // for (either currentUserId hasn't loaded yet, or the frame
            // carries no receiver info), don't present it. The previous
            // check only suppressed when both ids were known AND differed,
            // which meant an empty currentUserId (e.g. WS reconnecting
            // faster than auth state hydrates) let every incoming call
            // through to every signed-in device regardless of recipient.
            if (currentUserId.isEmpty) {
              AppLogger.d('[GLOBAL_WS] Suppressing incoming offer: local user id not yet known (call_id=$callId)');
              return;
            }
            if (receiverId.isNotEmpty && receiverId != currentUserId) {
              AppLogger.d('[GLOBAL_WS] Suppressing incoming offer for different user ($receiverId vs current $currentUserId)');
              return;
            }
            final event = IncomingCallEvent.fromMap(data, defaultConsultationId: consultationId);
            PresentationCoordinator.present(event);
          } else if (typeLower.contains('accepted')) {
            final consultationId = (data['consultation_id'] ?? data['appointment_id'] ?? '').toString();
            final callId = (data['call_id'] ?? consultationId).toString();
            AppLogger.d('[WEBRTC_TRACE_01_CALL_ACCEPTED_WS_RECEIVED] call_id=$callId action=call_accepted');
            AppLogger.d('[CALL_TRACE] CALL_ACCEPTED source=WEBSOCKET consultation_id=$consultationId');
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

        // 4001/4003 are server-signaled terminal codes (e.g. auth
        // rejected / session superseded) where retrying is pointless or
        // counterproductive. Every other close — including ones this
        // manager itself initiated via connect()'s replacement-close or
        // disconnectForLogout() — is already prevented from reaching this
        // point for the *previous* generation by the gen check above; if
        // we're here, this is the current generation's connection
        // genuinely going away, so scheduling a reconnect is correct.
        if (code != 4001 && code != 4003) {
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

    AppLogger.d('[WS RECONNECT V2] scheduled in ${delaySec}s (attempt $_reconnectAttempts)');
    AppLogger.d('[GLOBAL_WS] Reconnect scheduled in ${delaySec}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      AppLogger.d('[WS RECONNECT V2] executing');
      connect(force: true);
    });
  }

  void disconnectForLogout() {
    _connectionGeneration++;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _state = GlobalWsState.disconnected;
    GlobalCallService.currentUserId = null;
    AppLogger.d('[GLOBAL_WS] Global WebSocket disconnected for logout, currentUserId cleared');
  }

  static Future<String> _getSanitizedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? '';
    var token = rawToken.trim();
    if (token.startsWith('Bearer ')) token = token.substring(7).trim();
    token = token.replaceAll('"', '').replaceAll("'", '').trim();
    if (token.endsWith('#')) token = token.substring(0, token.length - 1).trim();
    return token;
  }
}