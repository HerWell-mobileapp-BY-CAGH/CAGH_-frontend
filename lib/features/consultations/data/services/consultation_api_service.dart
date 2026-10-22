import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_durations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class ConsultationApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final rawToken = await AuthService.getAccessToken() ??
        prefs.getString('auth_token') ??
        prefs.getString('access_token') ??
        prefs.getString('access') ??
        '';
    var token = rawToken.trim();
    if (token.startsWith('Bearer ')) token = token.substring(7).trim();
    token = token.replaceAll('"', '').replaceAll("'", '').trim();

    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getConsultationsForAppointment(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}?appointment=$appointmentId');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        return (decoded['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Failed to fetch consultations. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getConsultationByAppointment(String appointmentId) async {
    try {
      final existingList = await getConsultationsForAppointment(appointmentId);
      if (existingList.isNotEmpty) {
        return existingList.first;
      }
    } catch (e) {
      AppLogger.d('ConsultationApiService: Query by appointment failed, trying direct detail lookup: $e');
    }

    final detailUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$appointmentId/');
    try {
      final response = await http.get(
        detailUrl,
        headers: await _getHeaders(),
      ).timeout(AppDurations.apiRequestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('id')) {
          return data;
        }
      }
    } catch (e) {
      AppLogger.d('ConsultationApiService: Direct detail lookup failed: $e');
    }

    return await createConsultation(appointmentId);
  }

  Future<Map<String, dynamic>> createConsultation(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'appointment': appointmentId}),
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create consultation. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> startConsultation(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/start/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start consultation. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> startVideoSession(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/video-session/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'action': 'START'}),
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start video session. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCallAccess(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/call-midwife/');
    final response = await http.get(url, headers: await _getHeaders()).timeout(AppDurations.apiRequestTimeout);
    if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 403) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get call access. Status: ${response.statusCode}');
    }
  }


  Future<Map<String, dynamic>> addClinicalNote(String consultationId, String note) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/add_note/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'note': note}),
    ).timeout(AppDurations.apiRequestTimeout);

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
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete consultation. Status: ${response.statusCode}');
    }
  }
}
