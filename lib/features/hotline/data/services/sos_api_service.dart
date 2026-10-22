import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/hotline/domain/models/hotline.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class SosApiService {
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

  Future<SosResponse> getHotlines() async {
    try {
      final urlStr = '${ApiConfig.baseUrl}${ApiConfig.sosHotlines}';
      final url = Uri.parse(urlStr);

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return SosResponse.fromJson(decoded);
      } else {
        AppLogger.e('SosApiService', 'Failed to load hotlines. Status: ${response.statusCode}');
        return SosResponse(
          defaultCallUrl: 'tel:0996717744',
          primaryHotlineNumber: '0996717744',
          savedContactsCount: 0,
          hotlines: [],
        );
      }
    } catch (e, stack) {
      AppLogger.e('SosApiService', 'Error loading hotlines', stack);
      return SosResponse(
        defaultCallUrl: 'tel:0996717744',
        primaryHotlineNumber: '0996717744',
        savedContactsCount: 0,
        hotlines: [],
      );
    }
  }

  Future<bool> triggerSosAlert({required double latitude, required double longitude}) async {
    try {
      final urlStr = '${ApiConfig.baseUrl}${ApiConfig.sosAlert}';
      final url = Uri.parse(urlStr);

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'latitude': latitude.toStringAsFixed(6),
          'longitude': longitude.toStringAsFixed(6),
          'status': 'TRIGGERED',
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, stack) {
      AppLogger.e('SosApiService', 'Error triggering SOS alert', stack);
      return false;
    }
  }
}
