import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cagh_frontend/features/onboarding/presentation/splash_screen.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/core/services/appearance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/callkit_service.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final action = (message.data['action'] ?? message.data['type'] ?? message.data['event'] ?? '').toString().toLowerCase();
  if (action.contains('incoming') || action.contains('offer') || action.contains('initiated')) {
    final callId = (message.data['call_id'] ?? message.data['consultation_id'] ?? '').toString();
    final callerId = (message.data['caller_id'] ?? message.data['caller'] ?? message.data['sender_id'] ?? message.data['sender']?['id'] ?? message.data['user_id'] ?? '').toString().trim();
    
    AppLogger.d('[CALL][FCM] Incoming call received');
    AppLogger.d('[CALL][FCM] call_id=$callId');
    AppLogger.d('[CALL][FCM] App state=background/terminated');

    try {
      // Note: Executed in an isolated background Dart isolate.
      final currentUserId = (await GlobalCallService.getAuthenticatedUserId() ?? '').trim();

      if (callerId.isNotEmpty && currentUserId.isNotEmpty && callerId == currentUserId) {
        AppLogger.d('[CALL][DEDUP] Duplicate/Self call ignored');
        return;
      }
    } catch (e) {
      AppLogger.d('[CALL][FCM] Error inspecting incoming call notification: $e');
    }

    final consultationId = message.data['consultation_id']?.toString() ?? callId;
    GlobalCallService.showIncomingCallModal(
      Map<String, dynamic>.from(message.data),
      defaultConsultationId: consultationId,
    );
  }
}

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await LanguageService.init();
  await AppearanceService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryGreen,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // Run FCM service initialization in background without blocking runApp()
      FcmService.initialize().catchError((e) {
        AppLogger.d('FCM Service background init notice: $e');
      });
    } catch (e) {
      AppLogger.d('Firebase initialization failed: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      CallKitService().init();
      _setupFcmForegroundListener();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallNavigationCoordinator.checkAndNavigatePendingCall();
    });
  }

  void _setupFcmForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final action = (message.data['action'] ?? message.data['type'] ?? message.data['event'] ?? '').toString().toLowerCase();
      if (action.contains('incoming') || action.contains('offer') || action.contains('initiated')) {
        if (GlobalCallService.isCallActive || GlobalCallService.isRingingShown) {
          AppLogger.d('FCM Foreground: Ignoring incoming_call push — call is already active/ringing');
          return;
        }

        final callerId = (message.data['caller_id'] ?? message.data['caller'] ?? message.data['sender_id'] ?? message.data['sender']?['id'] ?? message.data['user_id'] ?? '').toString().trim();
        try {
          final currentUserId = (await GlobalCallService.getAuthenticatedUserId() ?? '').trim();
          if (callerId.isNotEmpty && currentUserId.isNotEmpty && callerId == currentUserId) {
            AppLogger.d('FCM Foreground: IGNORED self incoming call notification');
            return;
          }
        } catch (e) {
          AppLogger.d('FCM Foreground: Error inspecting incoming call notification: $e');
        }

        final consultationId = message.data['consultation_id']?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}';

        GlobalCallService.showIncomingCallModal(
          Map<String, dynamic>.from(message.data),
          defaultConsultationId: consultationId,
        );
      } else {
        // Refresh notifications for other actions (like messages, consultation updates, etc)
        AppLogger.d('FCM Foreground: Refreshing notifications and showing popup');
        FcmService.showForegroundNotification(message);
        ref.read(notificationProvider.notifier).refreshNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (_, langCode, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppearanceService.currentThemeMode,
          builder: (_, themeMode, _) {
            return ValueListenableBuilder<double>(
              valueListenable: AppearanceService.currentTextScale,
              builder: (_, textScale, _) {
                return MaterialApp(
                  navigatorKey: globalNavigatorKey,
                  locale: Locale(langCode),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    const FallbackMaterialLocalizationsDelegate(),
                    const FallbackCupertinoLocalizationsDelegate(),
                  ],
                  // We have to use a static string or an initial translated string for the title since it requires context
                  title: 'Digital Midwife',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: ThemeData(
                    brightness: Brightness.light,
                    primaryColor: AppColors.primaryGreen,
                    scaffoldBackgroundColor: Colors.white,
                    cardColor: Colors.white,
                    dividerColor: Colors.grey.shade200,
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primaryGreen,
                      secondary: AppColors.accentYellow,
                      surface: Colors.white,
                      onSurface: AppColors.textDark,
                    ),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(color: AppColors.textDark),
                      bodyMedium: TextStyle(color: AppColors.textDark),
                      bodySmall: TextStyle(color: AppColors.textGray),
                    ),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      centerTitle: true,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: AppColors.primaryGreen,
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.dark,
                      ),
                    ),
                    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                      backgroundColor: Colors.white,
                      selectedItemColor: AppColors.primaryGreen,
                      unselectedItemColor: Colors.grey,
                      type: BottomNavigationBarType.fixed,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.mintLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.mintLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryGreen),
                      ),
                      labelStyle: const TextStyle(color: AppColors.textGray),
                    ),
                  ),
                  darkTheme: ThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.primaryGreen,
                    scaffoldBackgroundColor: AppColors.textDarkAlt,
                    cardColor: AppColors.textNearBlack,
                    dividerColor: Colors.grey.shade800,
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.primaryGreen,
                      secondary: AppColors.accentYellow,
                      surface: AppColors.textNearBlack,
                      onSurface: Colors.white,
                    ),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(color: Colors.white),
                      bodyMedium: TextStyle(color: Colors.white),
                      bodySmall: TextStyle(color: Colors.white70),
                    ),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: AppColors.textNearBlack,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      centerTitle: true,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.dark,
                      ),
                    ),
                    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                      backgroundColor: AppColors.textNearBlack,
                      selectedItemColor: AppColors.primaryGreen,
                      unselectedItemColor: Colors.white54,
                      type: BottomNavigationBarType.fixed,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: AppColors.textDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryGreen),
                      ),
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  builder: (context, child) {
                    final data = MediaQuery.of(context);
                    return MediaQuery(
                      data: data.copyWith(
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: child!,
                    );
                  },
                  home: const SplashScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('en', 'US'));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('en', 'US'));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
