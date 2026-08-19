import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  final Function(Map<String, dynamic>)? onMessageReceived;
  final Function(Map<String, dynamic>)? onTypingIndicator;
  final Function(Map<String, dynamic>)? onReadReceipt;
  final Function(Map<String, dynamic>)? onError;

  ChatWebSocketService({
    this.onMessageReceived,
    this.onTypingIndicator,
    this.onReadReceipt,
    this.onError,
  });

  Future<void> connect(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;

    final wsUrl = Uri.parse('${ApiConfig.wsUrl}/chat/$roomId/?token=$token');
    
    _channel = IOWebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      final eventType = data['type'];

      switch (eventType) {
        case 'chat_message':
          if (onMessageReceived != null) {
            onMessageReceived!(data['data']);
          }
          break;
        case 'typing_indicator':
          if (onTypingIndicator != null) {
            onTypingIndicator!(data);
          }
          break;
        case 'read_receipt':
          if (onReadReceipt != null) {
            onReadReceipt!(data);
          }
          break;
        case 'error':
          if (onError != null) {
            onError!(data);
          }
          break;
      }
    });
  }

  void sendMessage(String content, {String messageType = 'TEXT', String? attachmentId}) {
    final payload = {
      'action': 'send_message',
      'content': content,
      'message_type': messageType,
    };
    if (attachmentId != null) {
      payload['attachment_id'] = attachmentId;
    }
    _channel?.sink.add(jsonEncode(payload));
  }

  void sendTyping(bool isTyping) {
    _channel?.sink.add(jsonEncode({
      'action': 'typing',
      'is_typing': isTyping,
    }));
  }

  void markRead() {
    _channel?.sink.add(jsonEncode({
      'action': 'read_receipt',
    }));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
