import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_registration_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/midwife_home_screen.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_setup_profile_screen.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/app_text_field.dart';
import 'package:cagh_frontend/shared/widgets/primary_button.dart';
import 'package:cagh_frontend/shared/widgets/standard_app_bar.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class MidwifeLoginScreen extends StatefulWidget {
  const MidwifeLoginScreen({super.key});

  @override
  State<MidwifeLoginScreen> createState() => _MidwifeLoginScreenState();
}

class _MidwifeLoginScreenState extends State<MidwifeLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      if (identifier.isEmpty) {
        _emailError = AppLocalizations.of(context)!.valEmailPhoneReq;
      } else {
        final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        final cleanPhone = identifier.replaceAll(RegExp(r'[\s\-()]'), '');
        final ethPhoneRegExp = RegExp(r'^(?:\+251|0)?[97]\d{8}$');
        final genericPhoneRegExp = RegExp(r'^\+?\d{8,15}$');

        if (!emailRegExp.hasMatch(identifier) &&
            !ethPhoneRegExp.hasMatch(cleanPhone) &&
            !genericPhoneRegExp.hasMatch(cleanPhone)) {
          _emailError =
              AppLocalizations.of(context)?.valInvalidEmailPhone ??
              'Please enter a valid email or phone number';
        } else {
          _emailError = null;
        }
      }

      _passwordError = password.isEmpty
          ? AppLocalizations.of(context)!.valPasswordReq
          : null;
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      identifier: identifier,
      password: password,
      role: 'MIDWIFE',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      CustomSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.loginSuccessful,
        type: SnackBarType.success,
      );

      if (!mounted) return;

      final userRole = result.data?['user']?['role']?.toString().toUpperCase();

      if (userRole != null && userRole.isNotEmpty && userRole != 'MIDWIFE') {
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.roleMismatchMidwifeError,
          type: SnackBarType.error,
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final repo = MidwifeRepositoryImpl(MidwifeApiService());
        final profile = await repo.getMyProfile();
        if (!mounted) return;

        if (profile == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MidwifeSetupProfileScreen(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MidwifeHomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MidwifeHomeScreen()),
          (route) => false,
        );
      }
      if (mounted) setState(() => _isLoading = false);
    } else {
      String err = result.message;
      final lowerErr = err.toLowerCase();
      if (lowerErr.contains('incorrect email or password') ||
          lowerErr.contains('incorrect email') ||
          lowerErr.contains('invalid credentials') ||
          lowerErr.contains('no active account') ||
          lowerErr.contains('unauthorized')) {
        err =
            AppLocalizations.of(context)?.invalidCredentials ??
            'Incorrect email, phone number, or password. Please try again.';
      }
      setState(() {
        _passwordError = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.white;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final linkColor = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: StandardAppBar(
        title: AppLocalizations.of(context)!.midwifeLogin,
        showLanguagePicker: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) {
                              return const Icon(Icons.spa, color: AppColors.primaryGreen, size: 28);
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.welcomeBack,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    AppTextField(
                      controller: _emailController,
                      labelText: AppLocalizations.of(context)!.emailPhone,
                      hintText: AppLocalizations.of(
                        context,
                      )!.enterContactDetails,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      prefixIcon: Icon(
                        _emailController.text.trim().startsWith(
                              RegExp(r'[\d+]'),
                            )
                            ? Icons.phone_outlined
                            : Icons.alternate_email,
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (_emailError != null) _emailError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      controller: _passwordController,
                      labelText: AppLocalizations.of(context)!.password,
                      hintText: AppLocalizations.of(context)!.enterPassword,
                      isPassword: true,
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ForgotPasswordScreen(isMidwife: true),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: TextStyle(
                            color: linkColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      text: AppLocalizations.of(context)!.login,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dontHaveAccount,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MidwifeRegistrationScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.register,
                      style: TextStyle(
                        fontSize: 15,
                        color: linkColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
