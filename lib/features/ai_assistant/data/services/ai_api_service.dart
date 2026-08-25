import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';

class AiApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Sends a message and optional attachment to the AI backend.
  Future<Map<String, dynamic>> askQuestion(String message, {String? attachmentPath}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/ai-assistant/ask/');
    final headers = await _getHeaders();
    
    // The instructions say body should be {"question": "..."}
    final body = jsonEncode({
      'question': message,
      // If we support attachments in the future, add them here
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to ask AI: ${response.statusCode}');
    }
  }

  /// Fetches suggested questions from the backend
  Future<List<String>> getSuggestedQuestions() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/ai-assistant/suggested-questions/');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> questions = data['suggested_questions'] ?? [];
      return questions.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to load suggested questions');
    }
  }

  /// Submits user feedback for an AI response
  Future<void> submitFeedback(String id, String feedback) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/ai-assistant/questions/$id/feedback/');
    final headers = await _getHeaders();
    final body = jsonEncode({'feedback': feedback});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit feedback');
    }
  }
}
