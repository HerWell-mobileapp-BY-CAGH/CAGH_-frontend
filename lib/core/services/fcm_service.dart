import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_durations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class FcmService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Android 13+ requires the POST_NOTIFICATIONS runtime grant for the
      // incoming-call notification (and ringtone) to be shown. Without it the
      // OS silently suppresses the call notification, so calls appear to never ring.
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await Permission.notification.request();
        }
      } catch (e) {
        AppLogger.d('[FCM SERVICE] Notification permission request notice: $e');
      }

      _isInitialized = true;

      // Handle token refreshes automatically
      messaging.onTokenRefresh.listen((newToken) {
        registerDeviceToken(overrideToken: newToken);
      });

      // Register current token if user is logged in
      registerDeviceToken();
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Initialization notice: $e');
    }
  }

  static Future<void> registerDeviceToken({String? overrideToken}) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawToken = await AuthService.getAccessToken() ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? '';
      var authToken = rawToken.trim();
      if (authToken.startsWith('Bearer ')) authToken = authToken.substring(7).trim();
      authToken = authToken.replaceAll('"', '').replaceAll("'", '').trim();

      if (authToken.isEmpty) {
        AppLogger.d('[FCM SERVICE] User not logged in, skipping device token registration');
        return;
      }

      final userData = await AuthService.getUserData();
      final userId = (userData['id'] ?? userData['user_id'] ?? 'anonymous').toString();
      final prefKey = 'last_registered_fcm_token_$userId';

      final fcmToken = overrideToken ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        AppLogger.d('[FCM SERVICE] FCM Token is null or empty');
        return;
      }

      final lastToken = prefs.getString(prefKey);
      if (overrideToken == null && lastToken == fcmToken) {
        AppLogger.d('[FCM SERVICE] FCM Token unchanged for user $userId, skipping backend POST');
        return;
      }

      AppLogger.d('====================================================');
      AppLogger.d('[FCM SERVICE] Registering Device Token to Backend for User $userId');
      AppLogger.d('  FCM Token : $fcmToken');
      AppLogger.d('  Platform  : ${defaultTargetPlatform == TargetPlatform.iOS ? "IOS" : "ANDROID"}');
      AppLogger.d('====================================================');

      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/register-device/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
        }),
      ).timeout(AppDurations.apiRequestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString(prefKey, fcmToken);
        AppLogger.d('[FCM SERVICE] Device token registered successfully for user $userId!');
      } else {
        AppLogger.d('[FCM SERVICE] Failed to register device token. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Error registering device token: $e');
    }
  }
}
