import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_registration_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/midwife_home_screen.dart';
import 'package:cagh_frontend/features/home/presentation/user/user_bottom_nav_bar.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_setup_profile_screen.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/app_text_field.dart';
import 'package:cagh_frontend/shared/widgets/primary_button.dart';
import 'package:cagh_frontend/shared/widgets/standard_app_bar.dart';

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
  String? _apiError;

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
      _apiError = null;
      _emailError = identifier.isEmpty ? LanguageService.tr(context, 'val_email_phone_req') ?? 'Please enter your email or phone' : null;
      _passwordError = password.isEmpty ? LanguageService.tr(context, 'val_password_req') ?? 'Please enter your password' : null;
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
        message: LanguageService.tr(context, 'login_successful') ?? 'Welcome back!',
        type: SnackBarType.success,
      );

      if (!mounted) return;
      
      final userRole = result.data?['user']?['role']?.toString().toUpperCase();
      
      if (userRole == 'PATIENT') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserBottomNavBar()),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = true);
        try {
          final repo = MidwifeRepositoryImpl(MidwifeApiService());
          final profile = await repo.getMyProfile();
          
          if (profile == null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MidwifeSetupProfileScreen()),
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
      }
    } else {
      setState(() {
        _apiError = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: StandardAppBar(
        title: LanguageService.tr(context, 'midwife_login') ?? 'Midwife Login',
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5E6),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      LanguageService.tr(context, 'welcome_back') ?? 'Welcome Back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 28),

                    AppTextField(
                      controller: _emailController,
                      labelText: LanguageService.tr(context, 'email_phone'),
                      hintText: LanguageService.tr(context, 'enter_contact_details'),
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),

                    AppTextField(
                      controller: _passwordController,
                      labelText: LanguageService.tr(context, 'password'),
                      hintText: LanguageService.tr(context, 'enter_password'),
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
                              builder: (_) => const ForgotPasswordScreen(isMidwife: true),
                            ),
                          );
                        },
                        child: Text(
                          LanguageService.tr(context, 'forgot_password') ?? 'Forgot Password?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (_apiError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _apiError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 16),

                    PrimaryButton(
                      text: LanguageService.tr(context, 'login') ?? 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LanguageService.tr(context, 'dont_have_account') ?? "Don't have an account?",
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade800),
                  ),
                  const SizedBox(width: 4),
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
                      LanguageService.tr(context, 'register') ?? 'Register',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w700,
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
