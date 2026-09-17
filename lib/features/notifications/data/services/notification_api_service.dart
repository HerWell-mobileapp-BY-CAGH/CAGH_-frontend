import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class NotificationApiService {
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

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/');
      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map && decoded.containsKey('results')
            ? decoded['results']
            : decoded;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        AppLogger.e('NotificationApiService', 'Failed to fetch notifications: ${response.statusCode}');
        return [];
      }
    } catch (e, stack) {
      AppLogger.e('NotificationApiService', 'Error fetching notifications', stack);
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count/');
      final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/unread/');
      
      var response = await http.get(
        primaryUrl,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        response = await http.get(
          fallbackUrl,
          headers: await _getHeaders(),
        ).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return int.tryParse((data['unread_count'] ?? data['count'] ?? '').toString()) ?? 0;
      }
    } catch (e) {
      AppLogger.d('NotificationApiService getUnreadCount notice: $e');
    }
    return 0;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/mark-read/');
      final response = await http.post(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e, stack) {
      AppLogger.e('NotificationApiService', 'Error marking notification as read', stack);
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read/');
      final response = await http.post(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e, stack) {
      AppLogger.e('NotificationApiService', 'Error marking all notifications as read', stack);
      return false;
    }
  }
}
