import 'package:cagh_frontend/core/services/remote_translation_service.dart';
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
import 'package:cagh_frontend/core/services/fcm_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.d('[FCM] Background message received: ${message.messageId}');
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
      _setupFcmForegroundListener();
    }
  }

  void _setupFcmForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Refresh notifications and show popup for incoming notifications (messages, appointment updates, etc.)
      AppLogger.d('FCM Foreground: Refreshing notifications and showing popup');
      FcmService.showForegroundNotification(message);
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (_, langCode, _) {
        return ValueListenableBuilder<int>(
          valueListenable: RemoteTranslationService.updatesNotifier,
          builder: (_, _, _) {
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
                  title: 'Her Well',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: ThemeData(
                    brightness: Brightness.light,
                    primaryColor: AppColors.primaryGreen,
                    scaffoldBackgroundColor: AppColors.backgroundPale,
                    cardColor: Colors.white,
                    dividerColor: AppColors.borderGreenGray,
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryGreen,
                      primaryContainer: AppColors.lightGreen,
                      secondary: AppColors.accentYellow,
                      tertiary: AppColors.purple,
                      surface: Colors.white,
                      surfaceContainerHighest: AppColors.backgroundMintWhiteAlt,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textDark,
                      onSurfaceVariant: AppColors.sageGrey,
                      outline: AppColors.borderGreenGray,
                    ),
                    cardTheme: const CardThemeData(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        side: BorderSide(color: AppColors.borderGreenGray, width: 1),
                      ),
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    bottomSheetTheme: const BottomSheetThemeData(
                      backgroundColor: Colors.white,
                      modalBackgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(color: AppColors.textDark),
                      bodyMedium: TextStyle(color: AppColors.textDark),
                      bodySmall: TextStyle(color: AppColors.sageGrey),
                      titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                      titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                      titleSmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
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
                      unselectedItemColor: AppColors.sageGrey,
                      type: BottomNavigationBarType.fixed,
                    ),
                    chipTheme: ChipThemeData(
                      backgroundColor: AppColors.backgroundMintWhiteAlt,
                      selectedColor: AppColors.lightGreen,
                      disabledColor: AppColors.borderGray,
                      labelStyle: const TextStyle(color: AppColors.textDark),
                      secondaryLabelStyle: const TextStyle(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderGreenGray),
                      ),
                    ),
                    tabBarTheme: const TabBarThemeData(
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: AppColors.sageGrey,
                      indicatorColor: AppColors.primaryGreen,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: AppColors.backgroundMintWhiteAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGreenGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGreenGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      ),
                      labelStyle: const TextStyle(color: AppColors.sageGrey),
                      hintStyle: const TextStyle(color: AppColors.sageGrey),
                    ),
                  ),
                  darkTheme: ThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.darkPrimary,
                    scaffoldBackgroundColor: AppColors.darkBackground,
                    cardColor: AppColors.darkSurface,
                    dividerColor: AppColors.darkBorder,
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.darkPrimary,
                      primaryContainer: AppColors.darkButtonGreen,
                      secondary: AppColors.darkAccentYellow,
                      tertiary: AppColors.darkAccentPurple,
                      tertiaryContainer: AppColors.darkPurpleSurface,
                      surface: AppColors.darkSurface,
                      surfaceContainerHighest: AppColors.darkSurfaceVariant,
                      onPrimary: Colors.white,
                      onSurface: AppColors.darkTextPrimary,
                      onSurfaceVariant: AppColors.darkTextSecondary,
                      outline: AppColors.darkBorder,
                    ),
                    cardTheme: const CardThemeData(
                      color: AppColors.darkSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        side: BorderSide(color: AppColors.darkBorder, width: 1),
                      ),
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    bottomSheetTheme: const BottomSheetThemeData(
                      backgroundColor: AppColors.darkSurface,
                      modalBackgroundColor: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
                      bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
                      bodySmall: TextStyle(color: AppColors.darkTextSecondary),
                      titleLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
                      titleMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
                      titleSmall: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
                    ),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: AppColors.darkSurface,
                      foregroundColor: AppColors.darkTextPrimary,
                      elevation: 0,
                      centerTitle: true,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                        statusBarBrightness: Brightness.dark,
                      ),
                    ),
                    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                      backgroundColor: AppColors.darkSurface,
                      selectedItemColor: AppColors.darkPrimary,
                      unselectedItemColor: AppColors.darkTextSecondary,
                      type: BottomNavigationBarType.fixed,
                    ),
                    chipTheme: ChipThemeData(
                      backgroundColor: AppColors.darkSurfaceVariant,
                      selectedColor: AppColors.darkButtonGreen,
                      disabledColor: AppColors.darkBorder,
                      labelStyle: const TextStyle(color: AppColors.darkTextPrimary),
                      secondaryLabelStyle: const TextStyle(color: AppColors.darkPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.darkBorder),
                      ),
                    ),
                    tabBarTheme: const TabBarThemeData(
                      labelColor: AppColors.darkPrimary,
                      unselectedLabelColor: AppColors.darkTextSecondary,
                      indicatorColor: AppColors.darkPrimary,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: AppColors.darkSurfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.darkBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.darkBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
                      ),
                      labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
                      hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
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
