import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';

class ConsultationApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> createConsultation(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'appointment': appointmentId}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create consultation. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> startConsultation(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/start/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start consultation. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> startVideoSession(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/video-session/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'action': 'START'}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start video session. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> startVoiceSession(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'action': 'START'}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start voice session. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addClinicalNote(String consultationId, String note) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/add_note/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'note': note}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add clinical note. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> completeConsultation(String consultationId, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/complete/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete consultation. Status: ${response.statusCode}');
    }
  }
}
