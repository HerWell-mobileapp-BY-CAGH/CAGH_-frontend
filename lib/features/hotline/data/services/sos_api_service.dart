import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/hotline/domain/models/hotline.dart';

class SosApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<SosResponse> getHotlines() async {
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
      throw Exception('Failed to load hotlines. Status: ${response.statusCode}');
    }
  }

  Future<SosResponse> triggerSosAlert({required double latitude, required double longitude}) async {
    final urlStr = '${ApiConfig.baseUrl}${ApiConfig.sosAlert}';
    final url = Uri.parse(urlStr);

    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return SosResponse.fromJson(decoded);
    } else {
      throw Exception('Failed to trigger SOS alert. Status: ${response.statusCode}');
    }
  }
}
