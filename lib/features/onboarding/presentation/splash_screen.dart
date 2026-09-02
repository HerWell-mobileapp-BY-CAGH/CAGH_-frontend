import 'dart:async';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'language_selection_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

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
    _timer = Timer(const Duration(milliseconds: 3600), _onTimerFired);
  }

  void _onTimerFired() {
    if (!mounted) return;

    final isCallActiveOrPending = CallNavigationCoordinator.hasCallNavigationActiveOrPending;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

    if (isCallActiveOrPending || !isCurrentRoute) {
      AppLogger.d('[SPLASH] Delaying/Aborting splash navigation: callActiveOrPending=$isCallActiveOrPending isCurrentRoute=$isCurrentRoute');
      _timer = Timer(const Duration(milliseconds: 1000), _onTimerFired);
      return;
    }

    AppLogger.d('[SPLASH] Proceeding to main application destination (LanguageSelectionScreen)');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Logo circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            Spacer(flex: 2),

            // App name
            Text(
              AppLocalizations.of(context)!.appTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.primaryGreen,
              ),
            ),

            const SizedBox(height: 12),

            // Secure text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.secureConnection,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
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
