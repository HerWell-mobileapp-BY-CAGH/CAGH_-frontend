import 'dart:async';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';
import 'language_selection_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/home/presentation/user/user_home_screen.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/midwife_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), _onTimerFired);
  }

  void _onTimerFired() async {
    if (!mounted) return;

    final isCallActiveOrPending = CallNavigationCoordinator.hasCallNavigationActiveOrPending;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    if (isCallActiveOrPending || !isCurrentRoute) {
      AppLogger.d('[SPLASH] Delaying/Aborting splash navigation: callActiveOrPending=$isCallActiveOrPending isCurrentRoute=$isCurrentRoute');
      _timer = Timer(const Duration(milliseconds: 500), _onTimerFired);
      return;
    }

    // Concurrent check: session validity & cached user data
    final results = await Future.wait([
      AuthService.isSessionValid(),
      AuthService.getUserData(),
    ]);

    final isValid = results[0] as bool;
    final userData = results[1] as Map<String, dynamic>;

    if (!mounted) return;

    if (isValid) {
      AppLogger.d('[SPLASH] Valid session found. Syncing user call listener and FCM device token.');
      
      // Background non-blocking background initialization
      unawaited(GlobalCallService.initUserCallListener().catchError((e) {
        AppLogger.d('[SPLASH] Notice initializing user call listener: $e');
      }));
      unawaited(Future.microtask(() => FcmService.registerDeviceToken(force: true)));

      final role = (userData['role'] ?? '').toString().toUpperCase();

      if (role == 'MIDWIFE') {
        AuthService.setMockRole('MIDWIFE');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MidwifeHomeScreen()),
        );
      } else {
        AuthService.setMockRole('PATIENT');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        );
      }
    } else {
      AppLogger.d('[SPLASH] No valid session or expired. Proceeding to LanguageSelectionScreen.');
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
            Text(
              AppLocalizations.of(context)!.appTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.secureConnection,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
