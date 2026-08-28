import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'create_new_password_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String contact;
  final bool isMidwife;
  final bool isForPasswordReset;

  const OtpVerificationScreen({
    super.key,
    required this.contact,
    this.isMidwife = false,
    this.isForPasswordReset = false,
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
  bool _isSending = true;      // true while the initial OTP send is in progress
  String? _sendError;          // non-null when OTP send failed

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (!widget.isForPasswordReset) {
      _autoSendOtp();
    } else {
      _isSending = false;
    }
  }

  Future<void> _autoSendOtp() async {
    if (mounted) setState(() { _isSending = true; _sendError = null; });
    
    final res = widget.isForPasswordReset
        ? await AuthService.requestPasswordResetOtp(email: widget.contact)
        : await AuthService.sendOtp(phoneOrEmail: widget.contact);
        
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _sendError = res.success ? null : res.message;
    });
    // Show a short snackbar on success too so the user knows to check email
    if (res.success) {
      CustomSnackBar.show(
        context,
        message: 'OTP sent! Check your email inbox.',
        type: SnackBarType.success,
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
      backgroundColor: AppColors.backgroundMintWhite,
      body: Column(
        children: [
          // Green App Bar
          Container(
            width: double.infinity,
            color: AppColors.primaryGreen,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: AppColors.accentYellow),
                    ),
                    Expanded(
                      child: Text(
                        LanguageService.tr(context, 'verify_code'),
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
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    LanguageService.tr(context, 'enter_code'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── OTP Send state feedback ────────────────────────────
                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Sending verification code…',
                              style: TextStyle(color: AppColors.primaryGreen, fontSize: 13)),
                        ],
                      ),
                    )
                  else if (_sendError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentYellowBright),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline, color: AppColors.deepOrange, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Check your email inbox — the code was likely sent.',
                                  style: TextStyle(
                                    color: AppColors.deepOrange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter the 6-digit code from your email below. If you did not receive it, tap Resend after the timer expires.',
                            style: TextStyle(color: AppColors.brownText, fontSize: 12.5),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'A 6-digit code was sent to:\n${widget.contact}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                      ),
                    ),
                  // ─────────────────────────────────────────────────────

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
                                color: AppColors.primaryGreen,
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
                        _startTimer();
                        await _autoSendOtp();
                      },
                      child: Text(
                        LanguageService.tr(context, 'resend_code'),
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
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
                              final navigator = Navigator.of(context);

                              final code = _otpCode;
                              if (code.length == 6) {
                                setState(() => _isLoading = true);

                                final result = await AuthService.verifyOtp(
                                  phoneOrEmail: widget.contact,
                                  code: code,
                                  purpose: widget.isForPasswordReset ? 'PASSWORD_RESET' : 'REGISTRATION',
                                );

                                if (!mounted) return;
                                setState(() => _isLoading = false);

                                if (result.success) {
                                  if (mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message: 'OTP Verified Successfully!',
                                      type: SnackBarType.success,
                                    );
                                  }

                                  if (!mounted) return;

                                  if (widget.isForPasswordReset) {
                                    navigator.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => CreateNewPasswordScreen(
                                          contact: widget.contact,
                                          resetToken: code,
                                          isMidwife: widget.isMidwife,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Registration complete! Must log in to get tokens.
                                    CustomSnackBar.show(
                                      context,
                                      message: 'Registration complete! Please log in.',
                                      type: SnackBarType.success,
                                    );
                                    
                                    navigator.pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => widget.isMidwife
                                            ? const MidwifeLoginScreen()
                                            : const UserLoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } else {
                                  CustomSnackBar.show(
                                    context,
                                    message: result.message,
                                    type: SnackBarType.error,
                                  );
                                }
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  message: 'Please enter the full 6-digit code',
                                  type: SnackBarType.warning,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
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
                              '${LanguageService.tr(context, 'verify')}  →',
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
