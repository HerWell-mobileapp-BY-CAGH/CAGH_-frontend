import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cagh_frontend/features/onboarding/presentation/splash_screen.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/core/services/appearance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';
import 'package:cagh_frontend/features/consultations/data/services/callkit_service.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
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
    final callerName = NameFormatter.format((message.data['caller_name'] ?? message.data['sender_name'] ?? 'Care Provider').toString());

    await CallKitService().init();
    AppLogger.d('[CALL][NOTIFICATION] Incoming call notification created');
    AppLogger.d('[CALL][NOTIFICATION] Full-screen intent triggered');
    await CallKitService().showCallkitIncoming(
      consultationId: consultationId,
      name: callerName,
      extra: Map<String, dynamic>.from(message.data),
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
        AppLogger.d('[FCM FOREGROUND] Incoming call notification received');
        final event = IncomingCallEvent.fromMap(
          Map<String, dynamic>.from(message.data),
          defaultConsultationId: message.data['consultation_id']?.toString() ?? '',
        );
        await GlobalCallService.handleIncomingCallEvent(event);
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
                  supportedLocales: const [
                    Locale('en', ''),
                    Locale('am', ''),
                    Locale('om', ''),
                    Locale('so', ''),
                    Locale('ti', ''),
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    FallbackMaterialLocalizationsDelegate(),
                    FallbackCupertinoLocalizationsDelegate(),
                  ],
                  title: LanguageService.trStatic('app_title'),
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: ThemeData(
                    brightness: Brightness.light,
                    primaryColor: AppColors.primaryGreen,
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
                    scaffoldBackgroundColor: Colors.white,
                    cardColor: Colors.white,
                    dividerColor: Colors.grey.shade200,
                  ),
                  darkTheme: ThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.primaryGreen,
                    scaffoldBackgroundColor: AppColors.textDarkAlt,
                    cardColor: AppColors.textNearBlack,
                    dividerColor: Colors.grey.shade800,
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
