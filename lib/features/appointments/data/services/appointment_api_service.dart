import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';

class AppointmentApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getTimeSlots(String midwifeId, String date) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.timeSlots}?midwife_id=$midwifeId&date=$date');
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          throw Exception('API returned a List. Body: ${response.body}');
        }
        return decoded as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Decode Error: $e. Body: ${response.body}');
      }
    } else {
      throw Exception('Failed to load time slots. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> requestAppointment(Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}');
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      // TODO: Connect to backend notification endpoint (Phase 14)
      return jsonDecode(response.body);
    } else if (response.statusCode == 409) {
      throw Exception('CONFLICT: Slot is no longer available.');
    } else {
      throw Exception('Failed to request appointment. Status: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getUserAppointments() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}');
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception('Failed to fetch user appointments.');
    }
  }

  Future<List<dynamic>> getMidwifeAppointments() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}');
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception('Failed to fetch midwife appointments.');
    }
  }

  Future<Map<String, dynamic>> acceptAppointment(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/confirm/');
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to accept appointment.');
    }
  }

  Future<Map<String, dynamic>> declineAppointment(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/decline/');
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to decline appointment.');
    }
  }

  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/cancel/');
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to cancel appointment.');
    }
  }
  
  Future<Map<String, dynamic>> getAppointmentDetails(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/');
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch appointment details.');
    }
  }

  Future<List<dynamic>> getAvailabilities() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.availabilities}');
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception('Failed to fetch availabilities. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> setAvailability(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.availabilities}');
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to set availability. Status: ${response.statusCode}');
    }
  }
}
