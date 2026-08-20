import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cagh_frontend/features/onboarding/presentation/splash_screen.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/core/services/appearance_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter/services.dart';
import 'package:cagh_frontend/core/services/ringtone_service.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['action'] == 'INCOMING_CALL') {
    CallKitParams params = CallKitParams(
      id: message.data['consultation_id'],
      nameCaller: message.data['caller_name'],
      appName: 'CAGH Health',
      avatar: 'assets/images/caller_avatar.png',
      type: 0, // 0 for Voice, 1 for Video
      duration: 30000,
      extra: message.data,
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
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
      statusBarColor: Color(0xFF315E26),
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
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
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
      _setupCallkitListener();
    }
  }

  void _setupCallkitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      
      if (event is CallEventActionCallAccept) {
        final extra = event.callKitParams.extra ?? {};
        final consultationId = extra['consultation_id'];
        final callerName = extra['caller_name'] ?? 'Caller';

        if (consultationId != null) {
          globalNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => VoiceConsultationScreen(
                consultationId: consultationId.toString(),
                midwifeName: callerName.toString(),
                phoneNumber: 'Incoming Call',
                isCaller: false,
              ),
            ),
          );
        }
      } else if (event is CallEventActionCallDecline) {
        // Future: hit backend to decline
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, langCode, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppearanceService.currentThemeMode,
          builder: (context, themeMode, child) {
            return ValueListenableBuilder<double>(
              valueListenable: AppearanceService.currentTextScale,
              builder: (context, textScale, child) {
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
                    primaryColor: const Color(0xFF315E26),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Color(0xFF315E26),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      centerTitle: true,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: Color(0xFF315E26),
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
                    primaryColor: const Color(0xFF315E26),
                    scaffoldBackgroundColor: const Color(0xFF121212),
                    cardColor: const Color(0xFF1E1E1E),
                    dividerColor: Colors.grey.shade800,
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Color(0xFF1E1E1E),
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
                    return Listener(
                      onPointerDown: (_) => RingtoneService.unlockAudio(),
                      child: MediaQuery(
                        data: data.copyWith(
                          textScaler: TextScaler.linear(textScale),
                        ),
                        child: child!,
                      ),
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
