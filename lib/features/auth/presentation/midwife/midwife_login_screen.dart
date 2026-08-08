import 'package:flutter/material.dart';
import 'midwife_registration_screen.dart';
import '../forgot_password_screen.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/midwife_home_screen.dart';
import 'package:cagh_frontend/features/home/presentation/user/user_home_screen.dart';

class MidwifeLoginScreen extends StatefulWidget {
  const MidwifeLoginScreen({super.key});

  @override
  State<MidwifeLoginScreen> createState() => _MidwifeLoginScreenState();
}

class _MidwifeLoginScreenState extends State<MidwifeLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: const Color(0xFFFFF0E8)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                      const Spacer(),
                      Text(
                        LanguageService.tr('midwife_login'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageService.tr('welcome_back'),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                LanguageService.tr('email_phone'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: LanguageService.tr('enter_contact_details'),
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F8F8),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                LanguageService.tr('password'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: LanguageService.tr('enter_password'),
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F8F8),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
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
                                        const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    LanguageService.tr('forgot_password'),
                                    style: const TextStyle(
                                      color: Color(0xFF6A1B9A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          final identifier = _emailController.text.trim();
                                          final password = _passwordController.text;

                                          if (identifier.isEmpty || password.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Please enter email/phone and password'),
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() => _isLoading = true);

                                          final result = await AuthService.login(
                                            identifier: identifier,
                                            password: password,
                                          );

                                          if (!mounted) return;
                                          setState(() => _isLoading = false);

                                          if (result.success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Login successful!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );

                                            final profileRes = await AuthService.getProfile();
                                            final isMidwife = profileRes.success &&
                                                profileRes.data != null &&
                                                profileRes.data!['role'] == 'MIDWIFE';

                                            if (!mounted) return;

                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => isMidwife
                                                    ? const MidwifeHomeScreen()
                                                    : const UserHomeScreen(),
                                              ),
                                              (route) => false,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(result.message),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
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
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          LanguageService.tr('login'),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              LanguageService.tr('dont_have_account'),
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const MidwifeRegistrationScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                LanguageService.tr('register'),
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
