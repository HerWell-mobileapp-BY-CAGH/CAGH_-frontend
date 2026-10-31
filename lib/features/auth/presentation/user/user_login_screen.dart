import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_registration_screen.dart';
import 'package:cagh_frontend/features/onboarding/presentation/user_type_selection_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:cagh_frontend/features/home/presentation/user/user_home_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/app_text_field.dart';
import 'package:cagh_frontend/shared/widgets/standard_app_bar.dart';

import 'package:shared_preferences/shared_preferences.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted && prefs.containsKey('remember_me')) {
      setState(() {
        _rememberMe = prefs.getBool('remember_me') ?? true;
      });
    }
  }

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
          _emailError = AppLocalizations.of(context)?.valInvalidEmailPhone ??
              'Please enter a valid email or phone number';
        } else {
          _emailError = null;
        }
      }
      
      if (password.isEmpty) {
        _passwordError = AppLocalizations.of(context)!.valPasswordReq;
      } else if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
      } else {
        _passwordError = null;
      }
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      identifier: identifier,
      password: password,
      role: 'PATIENT',
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final userRole = result.data?['user']?['role']?.toString().toUpperCase();
      if (userRole != null && userRole.isNotEmpty && userRole != 'PATIENT') {
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.roleMismatchPatientError,
          type: SnackBarType.error,
        );
        return;
      }

      CustomSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.loginSuccessful,
        type: SnackBarType.success,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        (route) => false,
      );
    } else {
      String err = result.message;
      final lowerErr = err.toLowerCase();
      if (lowerErr.contains('incorrect email or password') ||
          lowerErr.contains('incorrect email') ||
          lowerErr.contains('invalid credentials') ||
          lowerErr.contains('no active account') ||
          lowerErr.contains('unauthorized')) {
        err = AppLocalizations.of(context)?.invalidCredentials ??
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
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF6F8F5);
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final primaryDarkGreen = const Color(0xFF385A2E);
    final linkColor = isDark ? const Color(0xFF66BB6A) : const Color(0xFF1B5E20);

    void navigateToRoleSelection() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserTypeSelectionScreen()),
        );
      }
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigateToRoleSelection();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: StandardAppBar(
          title: AppLocalizations.of(context)?.userLogin ?? 'User Login',
          showLanguagePicker: true,
          onBack: navigateToRoleSelection,
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Logo Container with Shadow
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
                              return Icon(Icons.spa, color: primaryDarkGreen, size: 28);
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
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)?.userRoleSubtitle ?? 'For adolescent girls and young women',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppTextField(
                      controller: _emailController,
                      labelText: AppLocalizations.of(context)!.emailPhone,
                      hintText: AppLocalizations.of(context)!.enterContactDetails,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      prefixIcon: Icon(
                        _emailController.text.trim().startsWith(RegExp(r'[\d+]'))
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
                      prefixIcon: const Icon(Icons.lock_outline),
                      onChanged: (val) {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                      activeColor: isDark ? const Color(0xFF66BB6A) : const Color(0xFF385A2E),
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.keepMeLoggedIn,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textColor.withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(isMidwife: false),
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDarkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppLocalizations.of(context)!.login,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                      ),
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
                      color: isDark ? Colors.white70 : const Color(0xFF1C1C1E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRegistrationScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)?.signUp ?? 'Sign Up',
                      style: TextStyle(
                        fontSize: 15,
                        color: linkColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
}
