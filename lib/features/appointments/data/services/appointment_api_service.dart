import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_durations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class AppointmentApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _getWithAuth(Uri url, {bool allowPublicRetry = true}) async {
    var response = await http.get(url, headers: await _getHeaders()).timeout(AppDurations.apiRequestTimeout);
    if (response.statusCode == 401) {
      AppLogger.d('[AUTH] ACCESS_EXPIRED endpoint=${url.path}');
      final refreshed = await AuthService.forceTokenRefresh();
      if (refreshed) {
        response = await http.get(url, headers: await _getHeaders()).timeout(AppDurations.apiRequestTimeout);
      } else if (allowPublicRetry) {
        response = await http.get(url, headers: {'Content-Type': 'application/json'}).timeout(AppDurations.apiRequestTimeout);
      }
    }
    return response;
  }

  Future<http.Response> _postWithAuth(Uri url, {Object? body}) async {
    var response = await http.post(url, headers: await _getHeaders(), body: body).timeout(AppDurations.apiRequestTimeout);
    if (response.statusCode == 401) {
      AppLogger.d('[AUTH] ACCESS_EXPIRED endpoint=${url.path}');
      final refreshed = await AuthService.forceTokenRefresh();
      if (refreshed) {
        response = await http.post(url, headers: await _getHeaders(), body: body).timeout(AppDurations.apiRequestTimeout);
      }
    }
    return response;
  }

  Future<http.Response> _patchWithAuth(Uri url, {Object? body}) async {
    var response = await http.patch(url, headers: await _getHeaders(), body: body).timeout(AppDurations.apiRequestTimeout);
    if (response.statusCode == 401) {
      AppLogger.d('[AUTH] ACCESS_EXPIRED endpoint=${url.path}');
      final refreshed = await AuthService.forceTokenRefresh();
      if (refreshed) {
        response = await http.patch(url, headers: await _getHeaders(), body: body).timeout(AppDurations.apiRequestTimeout);
      }
    }
    return response;
  }

  Future<http.Response> _deleteWithAuth(Uri url) async {
    var response = await http.delete(url, headers: await _getHeaders()).timeout(AppDurations.apiRequestTimeout);
    if (response.statusCode == 401) {
      AppLogger.d('[AUTH] ACCESS_EXPIRED endpoint=${url.path}');
      final refreshed = await AuthService.forceTokenRefresh();
      if (refreshed) {
        response = await http.delete(url, headers: await _getHeaders()).timeout(AppDurations.apiRequestTimeout);
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> getTimeSlots(String midwifeId, String date) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.timeSlots}?midwife_id=$midwifeId&date=$date');
    
    final response = await _getWithAuth(url);

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
    
    final response = await _postWithAuth(
      url,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 409) {
      throw Exception('CONFLICT: Slot is no longer available.');
    } else {
      throw Exception('Failed to request appointment. Status: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> listData = [];
      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        listData = decoded['results'] as List<dynamic>? ?? [];
      } else if (decoded is List) {
        listData = decoded;
      }
      return listData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      throw Exception('Failed to fetch user appointments. Status: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getMidwifeAppointments() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> listData = [];
      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        listData = decoded['results'] as List<dynamic>? ?? [];
      } else if (decoded is List) {
        listData = decoded;
      }
      return listData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      throw Exception('Failed to fetch midwife appointments. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> acceptAppointment(String appointmentId) async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/confirm/');
    final acceptUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/accept/');
    final patchUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/');
    
    http.Response response = await _postWithAuth(primaryUrl);

    if (response.statusCode == 404) {
      response = await _postWithAuth(acceptUrl);
    }
    if (response.statusCode == 404 || response.statusCode == 405) {
      response = await _patchWithAuth(patchUrl, body: jsonEncode({'status': 'CONFIRMED'}));
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.body.isEmpty) return {'status': 'CONFIRMED'};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'CONFIRMED'};
      } catch (_) {
        return {'status': 'CONFIRMED'};
      }
    } else {
      String msg = 'Failed to accept appointment.';
      try {
        final body = jsonDecode(response.body);
        msg = body['detail'] ?? body['message'] ?? body['error'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> declineAppointment(String appointmentId) async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/decline/');
    final rejectUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/reject/');
    final patchUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/');
    
    http.Response response = await _postWithAuth(primaryUrl);

    if (response.statusCode == 404) {
      response = await _postWithAuth(rejectUrl);
    }
    if (response.statusCode == 404 || response.statusCode == 405) {
      response = await _patchWithAuth(patchUrl, body: jsonEncode({'status': 'DECLINED'}));
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.body.isEmpty) return {'status': 'DECLINED'};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'DECLINED'};
      } catch (_) {
        return {'status': 'DECLINED'};
      }
    } else {
      String msg = 'Failed to decline appointment.';
      try {
        final body = jsonDecode(response.body);
        msg = body['detail'] ?? body['message'] ?? body['error'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/cancel/');
    final patchUrl = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/');
    
    http.Response response = await _postWithAuth(primaryUrl);

    if (response.statusCode == 404 || response.statusCode == 405) {
      response = await _patchWithAuth(patchUrl, body: jsonEncode({'status': 'CANCELLED'}));
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.body.isEmpty) return {'status': 'CANCELLED'};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'status': 'CANCELLED'};
      } catch (_) {
        return {'status': 'CANCELLED'};
      }
    } else {
      String msg = 'Failed to cancel appointment.';
      try {
        final body = jsonDecode(response.body);
        msg = body['detail'] ?? body['message'] ?? body['error'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> rescheduleAppointment({
    required String appointmentId,
    required String scheduledDate,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/reschedule/');
    
    final response = await _postWithAuth(
      url,
      body: jsonEncode({
        'scheduled_date': scheduledDate,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String msg = 'Failed to reschedule appointment.';
      try {
        final body = jsonDecode(response.body);
        msg = body['message'] ?? body['detail'] ?? body['error'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  
  Future<Map<String, dynamic>> getAppointmentDetails(String appointmentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}$appointmentId/');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch appointment details.');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailabilities() async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availability/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availabilities/');
    
    http.Response response;
    try {
      response = await _getWithAuth(primaryUrl);
      if (response.statusCode == 404) {
        response = await _getWithAuth(fallbackUrl);
      }
    } catch (_) {
      response = await _getWithAuth(fallbackUrl);
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> listData = [];
      if (decoded is Map && decoded.containsKey('results')) {
        listData = decoded['results'] as List<dynamic>? ?? [];
      } else if (decoded is List) {
        listData = decoded;
      }
      return listData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      throw Exception('Failed to fetch availabilities. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> setAvailability(Map<String, dynamic> data) async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availability/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/working-hours/');
    
    http.Response response;
    try {
      response = await _postWithAuth(primaryUrl, body: jsonEncode(data));
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await _postWithAuth(fallbackUrl, body: jsonEncode(data));
      }
    } catch (_) {
      response = await _postWithAuth(fallbackUrl, body: jsonEncode(data));
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } else {
      String msg = 'Failed to set availability.';
      try {
        final body = jsonDecode(response.body);
        msg = body['detail'] ?? body['message'] ?? body['error'] ?? 'Status: ${response.statusCode}';
      } catch (_) {
        msg = 'Status: ${response.statusCode}, Body: ${response.body}';
      }
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> updateAvailability(String availabilityId, Map<String, dynamic> data) async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availability/$availabilityId/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availabilities/$availabilityId/');
    
    http.Response response;
    try {
      response = await _patchWithAuth(primaryUrl, body: jsonEncode(data));
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await _patchWithAuth(fallbackUrl, body: jsonEncode(data));
      }
    } catch (_) {
      response = await _patchWithAuth(fallbackUrl, body: jsonEncode(data));
    }

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } else {
      throw Exception('Failed to update availability. Status: ${response.statusCode}');
    }
  }

  Future<void> deleteAvailability(String availabilityId) async {
    final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availability/$availabilityId/');
    final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/appointments/availabilities/$availabilityId/');
    
    http.Response response;
    try {
      response = await _deleteWithAuth(primaryUrl);
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await _deleteWithAuth(fallbackUrl);
      }
    } catch (_) {
      response = await _deleteWithAuth(fallbackUrl);
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete availability. Status: ${response.statusCode}');
    }
  }
}
