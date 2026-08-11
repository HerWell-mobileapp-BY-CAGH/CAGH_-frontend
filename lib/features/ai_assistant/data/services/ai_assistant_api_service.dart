import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';

class AiAssistantApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> askQuestion(String question) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.askAi}');
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'question': question}),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to ask AI question. Status: ${response.statusCode}');
    }
  }
}
