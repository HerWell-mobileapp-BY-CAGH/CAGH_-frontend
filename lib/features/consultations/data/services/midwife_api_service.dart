import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_durations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class MidwifeApiService {
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

  Future<http.Response> _postWithAuth(Uri url, {Object? body, bool allowPublicRetry = false}) async {
    var response = await http.post(url, headers: await _getHeaders(), body: body).timeout(AppDurations.apiRequestTimeout);
    if (response.statusCode == 401) {
      AppLogger.d('[AUTH] ACCESS_EXPIRED endpoint=${url.path}');
      final refreshed = await AuthService.forceTokenRefresh();
      if (refreshed) {
        response = await http.post(url, headers: await _getHeaders(), body: body).timeout(AppDurations.apiRequestTimeout);
      } else if (allowPublicRetry) {
        response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body).timeout(AppDurations.apiRequestTimeout);
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

  Future<List<dynamic>> getMidwives({String? search}) async {
    var urlStr = '${ApiConfig.baseUrl}${ApiConfig.midwivesProfiles}';
    if (search != null && search.isNotEmpty) {
      urlStr += '?search=${Uri.encodeQueryComponent(search)}';
    }
    final url = Uri.parse(urlStr);
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('results')) {
        return List<dynamic>.from(decoded['results'] as List);
      } else if (decoded is List) {
        return List<dynamic>.from(decoded);
      }
      return [];
    } else {
      throw Exception('Failed to load midwives. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getMidwifeProfile(String midwifeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwivesProfiles}$midwifeId/');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load midwife profile. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String midwifeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwivesProfiles}$midwifeId/favorite/');
    
    final response = await _postWithAuth(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle favorite. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeMe}');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404 || response.statusCode == 500 || response.statusCode == 400) {
      AppLogger.d('MidwifeApiService.getMyProfile: Server returned status ${response.statusCode}, falling back to null');
      return null;
    } else {
      throw Exception('Failed to load my profile. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createMyProfile(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwivesProfiles}');
    
    final response = await _postWithAuth(
      url,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create profile. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeMe}');
    
    final response = await _patchWithAuth(
      url,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeDashboard}');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard. Status: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getBlockedDates() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeBlockedDates}');
    
    final response = await _getWithAuth(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception('Failed to load blocked dates. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addBlockedDate(String date, String reason) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeBlockedDates}');
    
    final response = await _postWithAuth(
      url,
      body: jsonEncode({'date': date, 'reason': reason}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add blocked date. Status: ${response.statusCode}');
    }
  }

  Future<void> deleteBlockedDate(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeBlockedDates}$id/');
    
    final response = await _deleteWithAuth(url);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete blocked date. Status: ${response.statusCode}');
    }
  }
}
