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
      final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/');
      final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/inbox/');
      
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
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map && decoded.containsKey('results')
            ? (decoded['results'] as List<dynamic>)
            : (decoded is List ? decoded : []);
        return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
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
      final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/unread_count/');
      final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/inbox/unread_count/');
      final altUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count/');
      
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

      if (response.statusCode == 404) {
        response = await http.get(
          altUrl,
          headers: await _getHeaders(),
        ).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is int) return data;
        if (data is Map) {
          final countVal = data['unread_count'] ?? data['count'] ?? data['unread'];
          return int.tryParse(countVal?.toString() ?? '') ?? 0;
        }
      }
    } catch (e) {
      AppLogger.d('NotificationApiService getUnreadCount notice: $e');
    }
    return 0;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/mark_as_read/');
      final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/inbox/$notificationId/mark_as_read/');
      final patchUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/');

      final headers = await _getHeaders();
      var response = await http.post(
        primaryUrl,
        headers: headers,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        response = await http.post(
          fallbackUrl,
          headers: headers,
          body: jsonEncode({}),
        ).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      // Fallback: REST PATCH /notifications/{id}/ with is_read = true
      final patchResponse = await http.patch(
        patchUrl,
        headers: headers,
        body: jsonEncode({'is_read': true}),
      ).timeout(const Duration(seconds: 15));

      return patchResponse.statusCode >= 200 && patchResponse.statusCode < 300;
    } catch (e, stack) {
      AppLogger.e('NotificationApiService', 'Error marking notification as read', stack);
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final primaryUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/mark_all_as_read/');
      final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/inbox/mark_all_as_read/');
      final altUrl = Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read/');

      final headers = await _getHeaders();
      var response = await http.post(
        primaryUrl,
        headers: headers,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        response = await http.post(
          fallbackUrl,
          headers: headers,
          body: jsonEncode({}),
        ).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 404) {
        response = await http.post(
          altUrl,
          headers: headers,
          body: jsonEncode({}),
        ).timeout(const Duration(seconds: 15));
      }

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, stack) {
      AppLogger.e('NotificationApiService', 'Error marking all notifications as read', stack);
      return false;
    }
  }
}
