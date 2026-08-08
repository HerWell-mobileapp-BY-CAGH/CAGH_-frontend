import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/home/presentation/user/user_home_screen.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/midwife_home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String contact;

  const OtpVerificationScreen({
    super.key,
    required this.contact,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _autoSendOtp();
  }

  Future<void> _autoSendOtp() async {
    final res = await AuthService.sendOtp(phoneOrEmail: widget.contact);
    if (mounted && res.message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF5),
      body: Column(
        children: [
          // Green App Bar
          Container(
            width: double.infinity,
            color: const Color(0xFF1B5E20),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.amber),
                    ),
                    Expanded(
                      child: Text(
                        LanguageService.tr('verify_code'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.sms_outlined,
                    size: 64,
                    color: Color(0xFF1B5E20),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    LanguageService.tr('enter_code'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.contact,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // OTP Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B5E20),
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                            if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Resend Timer
                  Text(
                    _secondsRemaining > 0
                        ? '00:${_secondsRemaining.toString().padLeft(2, '0')}'
                        : '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  if (_secondsRemaining == 0)
                    TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        _startTimer();
                        final result = await AuthService.sendOtp(phoneOrEmail: widget.contact);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: result.success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                      child: Text(
                        LanguageService.tr('resend_code'),
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 50),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              final code = _otpCode;
                              if (code.length == 6) {
                                setState(() => _isLoading = true);

                                final result = await AuthService.verifyOtp(
                                  phoneOrEmail: widget.contact,
                                  code: code,
                                );

                                if (!mounted) return;
                                setState(() => _isLoading = false);

                                if (result.success) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('OTP Verified Successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  final profileRes = await AuthService.getProfile();
                                  final isMidwife = profileRes.success &&
                                      profileRes.data != null &&
                                      profileRes.data!['role'] == 'MIDWIFE';

                                  if (!mounted) return;

                                  navigator.pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => isMidwife
                                          ? const MidwifeHomeScreen()
                                          : const UserHomeScreen(),
                                    ),
                                    (route) => false,
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(result.message),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter the full 6-digit code'),
                                    behavior: SnackBarBehavior.floating,
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
                              '${LanguageService.tr('verify')}  →',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
