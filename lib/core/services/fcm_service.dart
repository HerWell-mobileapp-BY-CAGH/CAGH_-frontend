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
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';

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

  static const AndroidNotificationChannel _incomingCallChannel =
      AndroidNotificationChannel(
    'incoming_call_channel', // id
    'Incoming Calls', // title
    description:
        'Heads-up notification shown when an incoming voice call rings.', // description
    importance: Importance.max,
  );

  static const int _incomingCallNotificationId = 7761;
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
        await androidImpl?.createNotificationChannel(_incomingCallChannel);
      }
      _localNotificationsReady = true;
      AppLogger.d('[FCM SERVICE] Local notifications ready (ready=$_localNotificationsReady)');
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Local notifications init notice: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    AppLogger.d('[FCM SERVICE] Notification tapped: ${response.actionId} id=${response.id}');
    _localNotificationsPlugin.cancel(id: _incomingCallNotificationId);
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(response.payload!));

      // Action buttons: Accept / Decline act on the call directly.
      final actionId = response.actionId;
      if (actionId == 'accept') {
        AppLogger.d('[FCM SERVICE] Notification ACCEPT action pressed');
        final consultationId =
            (data['consultation_id'] ?? data['call_id'] ?? '').toString();
        if (consultationId.isNotEmpty && consultationId != 'null') {
          IncomingCallActionDispatcher.dispatchAccept(
            consultationId,
            consultationId,
            data,
            source: 'NOTIFICATION_ACCEPT',
          );
        }
        return;
      }
      if (actionId == 'decline') {
        AppLogger.d('[FCM SERVICE] Notification DECLINE action pressed');
        final consultationId =
            (data['consultation_id'] ?? data['call_id'] ?? '').toString();
        if (consultationId.isNotEmpty && consultationId != 'null') {
          RingtoneService.stopRingtone();
          IncomingCallActionDispatcher.dispatchDecline(consultationId, consultationId);
        }
        return;
      }

      if (GlobalCallService.isCallActive || GlobalCallService.isRingingShown) {
        AppLogger.d('[FCM SERVICE] Notification tap ignored - call already active/ringing');
        return;
      }
      final action =
          (data['action'] ?? data['type'] ?? data['event'] ?? '').toString().toLowerCase();
      if (action.contains('offer') ||
          action.contains('incoming') ||
          action.contains('initiated')) {
        GlobalCallService.showIncomingCallModal(
          data,
          defaultConsultationId:
              (data['consultation_id'] ?? data['call_id'] ?? '').toString(),
        );
      }
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Notification tap payload parse notice: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    _onNotificationTap(response);
  }

  /// Looks up a caller avatar URL in the incoming-call frame payload. The FCM
  /// payload is a flat map, so try every plausible sender-avatar key.
  static String? _extractCallerAvatarUrl(Map<String, dynamic> data) {
    const List<String> keys = [
      'sender_image_url', 'caller_image_url', 'sender_avatar_url', 'caller_avatar_url',
      'sender_image', 'caller_image', 'sender_avatar', 'caller_avatar',
      'sender_profile_image', 'caller_profile_image', 'profile_image', 'avatar',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final raw = value.toString().trim();
      if (raw.isEmpty || raw == 'null' || raw == '<null>') continue;
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
      // Relative API paths (e.g. /media/avatar/x.png) are resolved against the
      // backend base URL.
      if (raw.startsWith('/')) return '${ApiConfig.baseUrl}$raw';
      if (raw.contains('/') && raw.contains('.')) {
        return '${ApiConfig.baseUrl}/${raw.replaceFirst(RegExp(r'^/'), '')}';
      }
    }
    return null;
  }

  /// Downloads the avatar image bytes for use as the large notification icon.
  /// Returns null on any failure (slow network, not an image, etc.), letting
  /// the notification fall back to the stock app icon.
  static Future<Uint8List?> _loadAvatarBytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      // Sanity check: a plausible binary image (JPEG/PNG).
      final head = response.bodyBytes.length >= 4
          ? response.bodyBytes.sublist(0, 4)
          : response.bodyBytes;
      final bytes = List<int>.from(head);
      final isJpeg = bytes.length == 4 && bytes[0] == 0xFF && bytes[1] == 0xD8;
      final isPng = bytes.length == 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
      if (!isJpeg && !isPng) return null;
      return response.bodyBytes;
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Avatar fetch notice: $e');
      return null;
    }
  }

  /// Shows a heads-up incoming-call notification (Android) / alert (iOS) so the
  /// device visibly rings with a status-bar banner while the in-app caller UI
  /// is displayed. Uses a call category + full-screen intent so it renders like
  /// a real phone call on supported Android versions. Renders the caller as a
  /// large avatar and exposes working Accept / Decline action buttons.
  static Future<void> showIncomingCallNotification({
    String title = 'Incoming Call',
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return;
    await _ensureLocalNotificationsReady();

    final avatarUrl = _extractCallerAvatarUrl(data);
    final avatarBytes = await _loadAvatarBytes(avatarUrl);
    if (avatarBytes != null) {
      AppLogger.d('[FCM SERVICE] Caller avatar loaded (${avatarBytes.length} bytes).');
    }

    try {
      await _localNotificationsPlugin.show(
        id: _incomingCallNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'incoming_call_channel',
            'Incoming Calls',
            channelDescription:
                'Heads-up notification shown when an incoming voice call rings.',
            icon: '@mipmap/ic_launcher',
            largeIcon: avatarBytes != null
                ? ByteArrayAndroidBitmap(avatarBytes)
                : null,
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            ongoing: true,
            autoCancel: false,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'accept',
                'Accept',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'decline',
                'Decline',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            categoryIdentifier: 'incoming_call',
          ),
        ),
        payload: jsonEncode(data),
      );
      AppLogger.d('[FCM SERVICE] Incoming-call heads-up notification shown.');
    } catch (e) {
      AppLogger.d('[FCM SERVICE] Incoming-call notification show notice: $e');
    }
  }

  /// Dismisses the incoming-call heads-up notification (on accept/decline/end).
  static Future<void> dismissIncomingCallNotification() async {
    if (kIsWeb) return;
    AppLogger.d('[FCM SERVICE] Dismiss incoming-call notification start (ready=$_localNotificationsReady id=$_incomingCallNotificationId)');
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        await _localNotificationsPlugin.cancel(id: _incomingCallNotificationId);
        AppLogger.d('[FCM SERVICE] Dismiss incoming-call notification OK id=$_incomingCallNotificationId attempt=$attempt');
        break;
      } catch (e) {
        AppLogger.d('[FCM SERVICE] Incoming-call notification dismiss notice (attempt $attempt): $e');
      }
      if (attempt == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
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