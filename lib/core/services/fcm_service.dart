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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static bool _isInitialized = false;
  static FlutterLocalNotificationsPlugin? _localNotificationsPluginInstance;
  static FlutterLocalNotificationsPlugin get _localNotificationsPlugin =>
      _localNotificationsPluginInstance ??= FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  static bool _localNotificationsReady = false;

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

      await _ensureLocalNotificationsReady();

      // Handle token refreshes automatically
      messaging.onTokenRefresh.listen((newToken) {
        registerDeviceToken(overrideToken: newToken, force: true);
      });

      // Register current token if user is logged in
      registerDeviceToken(force: true);
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Initialization notice: $e');
    }
  }

  static void showForegroundNotification(RemoteMessage message) {
    if (kIsWeb) return;

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Initializes the local-notifications plugin (once per isolate) and creates
  /// the notification channels. Idempotent, and safe to call from the FCM
  /// background isolate so background data messages can still surface a
  /// heads-up call notification.
  static Future<void> _ensureLocalNotificationsReady() async {
    if (_localNotificationsReady || kIsWeb) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(_channel);
      }
      _localNotificationsReady = true;
      AppLogger.d('[FCM SERVICE] Local notifications ready (ready=$_localNotificationsReady)');
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Local notifications init notice: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    AppLogger.d('[FCM SERVICE] Notification tapped: ${response.actionId} id=${response.id}');
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(response.payload!));
      AppLogger.d('[FCM SERVICE] Notification tapped with payload: $data');
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Notification tap payload parse notice: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    _onNotificationTap(response);
  }



  static Future<void> registerDeviceToken({
    String? overrideToken,
    bool force = false,
    http.Client? httpClient,
  }) async {
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

      String? fcmToken = overrideToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          AppLogger.d('[FCM SERVICE] FirebaseMessaging getToken notice: $e');
        }
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        AppLogger.d('[FCM SERVICE] FCM Token is null or empty');
        return;
      }

      final lastToken = prefs.getString(prefKey);
      if (!force && overrideToken == null && lastToken == fcmToken) {
        AppLogger.d('[FCM SERVICE] FCM Token unchanged for user $userId, skipping backend POST');
        return;
      }

      String platformName = 'ANDROID';
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          platformName = 'IOS';
        }
      } catch (_) {}

      final tokenLen = fcmToken.length;
      AppLogger.d('[FCM] DISPATCHING registration user_id=$userId token_length=$tokenLen platform=$platformName force=$force');

      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/register-device/');
      final client = httpClient ?? http.Client();
      var response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': platformName,
        }),
      ).timeout(AppDurations.apiRequestTimeout);

      if (response.statusCode == 401) {
        AppLogger.d('[AUTH] ACCESS_EXPIRED endpoint=/notifications/register-device/');
        final refreshed = await AuthService.forceTokenRefresh();
        if (refreshed) {
          final freshToken = (await AuthService.getAccessToken() ?? '').trim();
          response = await client.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $freshToken',
            },
            body: jsonEncode({
              'token': fcmToken,
              'platform': platformName,
            }),
          ).timeout(AppDurations.apiRequestTimeout);
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString(prefKey, fcmToken);
        AppLogger.d('[FCM] SUCCESS device_token_registered user_id=$userId token_length=$tokenLen');
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        AppLogger.d('[FCM] TOKEN_INVALID status=${response.statusCode}');
      } else {
        final safeBody = response.body
            .replaceAll(RegExp(r'eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+'), '[REDACTED_JWT]')
            .replaceAll(RegExp(r'(?:[a-zA-Z0-9_-]{100,})'), '[REDACTED_TOKEN]');
        AppLogger.d('[FCM] DELIVERY_ERROR status=${response.statusCode} classification=HttpBackendError details=$safeBody');
      }
    } catch (e, s) {
      final safeErr = e.toString()
          .replaceAll(RegExp(r'eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+'), '[REDACTED_JWT]')
          .replaceAll(RegExp(r'(?:[a-zA-Z0-9_-]{100,})'), '[REDACTED_TOKEN]');
      AppLogger.d('[FCM] DELIVERY_ERROR classification=${e.runtimeType} details=$safeErr trace=$s');
    }
  }
}