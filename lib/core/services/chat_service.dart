import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id;
  final String sender; // 'You' or 'Midwife'
  final String text;
  final String time;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'text': text,
        'time': time,
        'isMe': isMe,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] ?? '',
        sender: json['sender'] ?? 'User',
        text: json['text'] ?? '',
        time: json['time'] ?? '',
        isMe: json['isMe'] ?? false,
      );
}

class ChatService {
  static final Map<String, ValueNotifier<List<ChatMessage>>> _conversations = {};
  static final ValueNotifier<bool> isMidwifeTyping = ValueNotifier<bool>(false);

  /// Get message notifier for a given midwife
  static ValueNotifier<List<ChatMessage>> getMessagesNotifier(String midwifeName) {
    if (!_conversations.containsKey(midwifeName)) {
      _conversations[midwifeName] = ValueNotifier<List<ChatMessage>>([]);
      _loadHistory(midwifeName);
    }
    return _conversations[midwifeName]!;
  }

  /// Load chat history from SharedPreferences
  static Future<void> _loadHistory(String midwifeName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_$midwifeName');
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        final loaded = list.map((e) => ChatMessage.fromJson(e)).toList();
        _conversations[midwifeName]!.value = loaded;
      } catch (_) {}
    } else {
      // Default initial welcome message for midwife
      _conversations[midwifeName]!.value = [
        ChatMessage(
          id: '1',
          sender: midwifeName,
          text: 'Hello! I am $midwifeName, your assigned certified nurse midwife. How are you feeling today?',
          time: '9:00 AM',
          isMe: false,
        ),
      ];
    }
  }

  /// Save history
  static Future<void> _saveHistory(String midwifeName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _conversations[midwifeName]?.value ?? [];
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('chat_$midwifeName', raw);
  }

  /// Send user message to midwife
  static void sendMessage({
    required String midwifeName,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final userMsg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      sender: 'You',
      text: trimmed,
      time: timeStr,
      isMe: true,
    );

    final current = List<ChatMessage>.from(getMessagesNotifier(midwifeName).value);
    current.add(userMsg);
    _conversations[midwifeName]!.value = current;
    _saveHistory(midwifeName);

    // Simulate natural, contextual professional response from human midwife
    isMidwifeTyping.value = true;

    Timer(const Duration(milliseconds: 1800), () {
      isMidwifeTyping.value = false;

      final replyText = _generateMidwifeReply(trimmed, midwifeName, current);
      final midwifeMsg = ChatMessage(
        id: (now.millisecondsSinceEpoch + 1).toString(),
        sender: midwifeName,
        text: replyText,
        time: timeStr,
        isMe: false,
      );

      final updated = List<ChatMessage>.from(getMessagesNotifier(midwifeName).value);
      updated.add(midwifeMsg);
      _conversations[midwifeName]!.value = updated;
      _saveHistory(midwifeName);
    });
  }

  /// Generate intelligent, contextual human-midwife consultation response
  static String _generateMidwifeReply(String userMessage, String midwifeName, List<ChatMessage> history) {
    final q = userMessage.toLowerCase();

    // Check if greeting
    if (q == 'hi' || q == 'hello' || q == 'hey' || q == 'good morning' || q == 'good afternoon') {
      if (history.where((m) => !m.isMe).length <= 1) {
        return 'Hello! I am $midwifeName. How can I support your health today?';
      } else {
        return 'Hello again! What health questions or concerns can I help you with right now?';
      }
    }

    // Menstrual health
    if (q.contains('period') || q.contains('cramp') || q.contains('bleeding') || q.contains('menstruat')) {
      return 'Thank you for updating me about your cycle. Period pain and irregularities are common. Are you experiencing severe cramping or heavy bleeding today? Please rest, drink warm fluids, and let me know if you need pain relief guidance.';
    }

    // Pregnancy symptoms
    if (q.contains('nausea') || q.contains('vomit') || q.contains('morning sickness') || q.contains('pregnant')) {
      return 'I understand. Morning nausea can be very uncomfortable. Try eating small, frequent meals and sipping ginger tea. If you notice any fluid loss or severe dizziness, please update me immediately.';
    }

    // Pain / discomfort
    if (q.contains('pain') || q.contains('headache') || q.contains('back') || q.contains('hurt')) {
      return 'I am sorry to hear you are experiencing discomfort. On a scale of 1 to 10, how intense is the pain, and where is it located? I will note this in your consultation file.';
    }

    // Appointment / visit queries
    if (q.contains('appointment') || q.contains('visit') || q.contains('book') || q.contains('schedule')) {
      return 'I can assist you with scheduling a full video or in-person consultation session. You can also view available time slots directly in the Consult tab.';
    }

    // Default professional midwife consultation reply
    return 'Thank you for sharing that with me. I have documented this in your consultation notes. Are there any other symptoms or questions you would like me to review with you?';
  }
}
