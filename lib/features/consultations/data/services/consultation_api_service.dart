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

  Future<Map<String, dynamic>> startVoiceSession(String consultationId) async {
    // Try explicit endpoint first, fallback to start consultation action
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/start/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/start/');
    
    try {
      final response = await http.post(
        primaryUrl,
        headers: await _getHeaders(),
      ).timeout(AppDurations.apiRequestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      AppLogger.d('ConsultationApiService: Primary start voice session failed, trying fallback: $e');
    }

    final response = await http.post(
      fallbackUrl,
      headers: await _getHeaders(),
      body: jsonEncode({'action': 'START'}),
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start voice session. Status: ${response.statusCode}');
    }
  }

  Future<bool> verifyVoiceSessionActive(String consultationId) async {
    if (consultationId.isEmpty || consultationId == 'null') return false;
    try {
      final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/token/');
      final response = await http.post(
        primaryUrl,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final status = (body['status'] ?? body['voice_session']?['status'] ?? '').toString().toLowerCase();
        if (status == 'ended' || status == 'declined' || status == 'cancelled' || status == 'missed') {
          return false;
        }
        return true;
      }
    } catch (e) {
      AppLogger.d('ConsultationApiService: verifyVoiceSessionActive check notice: $e');
    }
    return true;
  }

  Future<Map<String, dynamic>> getVoiceToken(String consultationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/token/');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    ).timeout(AppDurations.apiRequestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Agora token. Status: ${response.statusCode}');
    }
  }

  Future<int> acceptVoiceSessionDetailed(String consultationId) async {
    final headers = await _getHeaders();
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/accept/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/');
    
    AppLogger.d('[CALL][$consultationId][API_ACCEPT_REQUEST] POST $primaryUrl');
    try {
      final response = await http.post(
        primaryUrl,
        headers: headers,
      ).timeout(AppDurations.apiRequestTimeout);
      AppLogger.d('[CALL][$consultationId][API_ACCEPT_RESPONSE] status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409 || response.statusCode == 401) {
        return response.statusCode;
      }
    } catch (e) {
      AppLogger.d('[CALL][$consultationId][API_ACCEPT_ERROR] Primary endpoint failed: $e');
    }

    AppLogger.d('[CALL][$consultationId][API_ACCEPT_FALLBACK] POST $fallbackUrl');
    try {
      final response = await http.post(
        fallbackUrl,
        headers: headers,
        body: jsonEncode({'action': 'ACCEPT'}),
      ).timeout(AppDurations.apiRequestTimeout);
      AppLogger.d('[CALL][$consultationId][API_ACCEPT_FALLBACK_RESPONSE] status=${response.statusCode}, body=${response.body}');
      return response.statusCode;
    } catch (e) {
      AppLogger.d('[CALL][$consultationId][API_ACCEPT_ERROR] Fallback endpoint failed: $e');
      return 500;
    }
  }

  Future<bool> acceptVoiceSession(String consultationId) async {
    final status = await acceptVoiceSessionDetailed(consultationId);
    return status == 200 || status == 201;
  }

  Future<bool> declineVoiceSession(String consultationId) async {
    final headers = await _getHeaders();
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/decline/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/');
    
    AppLogger.d('[CALL][$consultationId][API_DECLINE_REQUEST] POST $primaryUrl');
    try {
      final response = await http.post(
        primaryUrl,
        headers: headers,
      ).timeout(AppDurations.apiRequestTimeout);
      AppLogger.d('[CALL][$consultationId][API_DECLINE_RESPONSE] status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 409) return true;
    } catch (e) {
      AppLogger.d('[CALL][$consultationId][API_DECLINE_ERROR] Primary endpoint failed: $e');
    }

    AppLogger.d('[CALL][$consultationId][API_DECLINE_FALLBACK] POST $fallbackUrl');
    try {
      final response = await http.post(
        fallbackUrl,
        headers: headers,
        body: jsonEncode({'action': 'DECLINE'}),
      ).timeout(AppDurations.apiRequestTimeout);
      AppLogger.d('[CALL][$consultationId][API_DECLINE_FALLBACK_RESPONSE] status=${response.statusCode}, body=${response.body}');
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 409;
    } catch (e) {
      AppLogger.d('[CALL][$consultationId][API_DECLINE_ERROR] Voice session request failed: $e');
      return false;
    }
  }

  Future<bool> missedVoiceSession(String consultationId) async {
    final headers = await _getHeaders();
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/cancel/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/');

    try {
      final response = await http.post(
        primaryUrl,
        headers: headers,
      ).timeout(AppDurations.apiRequestTimeout);
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 409) return true;
    } catch (e) {
      AppLogger.d('ConsultationApiService: Primary voice session request failed, trying fallback: $e');
    }

    try {
      final response = await http.post(
        fallbackUrl,
        headers: headers,
        body: jsonEncode({'action': 'MISSED'}),
      ).timeout(AppDurations.apiRequestTimeout);
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 409;
    } catch (e) {
      AppLogger.d('ConsultationApiService: Voice session request ultimately failed: $e');
      return false;
    }
  }

  Future<bool> endVoiceSession(String consultationId) async {
    final headers = await _getHeaders();
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/end/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consultations}$consultationId/voice-session/');

    AppLogger.d('[CALL][$consultationId][API_END_REQUEST] POST $primaryUrl');
    try {
      final response = await http.post(
        primaryUrl,
        headers: headers,
      ).timeout(AppDurations.apiRequestTimeout);
      AppLogger.d('[CALL][$consultationId][API_END_RESPONSE] status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 409) return true;
    } catch (e) {
      AppLogger.d('[CALL][$consultationId][API_END_ERROR] Primary endpoint failed: $e');
    }

    AppLogger.d('[CALL][$consultationId][API_END_FALLBACK] POST $fallbackUrl');
    try {
      final response = await http.post(
        fallbackUrl,
        headers: headers,
        body: jsonEncode({'action': 'END'}),
      ).timeout(AppDurations.apiRequestTimeout);
      AppLogger.d('[CALL][$consultationId][API_END_FALLBACK_RESPONSE] status=${response.statusCode}, body=${response.body}');

      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204 || response.statusCode == 409;
    } catch (e) {
      AppLogger.d('[CALL][$consultationId][API_END_ERROR] Voice session request failed: $e');
      return false;
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
