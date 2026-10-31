import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'password_reset_success_screen.dart';
import 'widgets/password_input_field.dart';
import 'widgets/password_strength_indicator.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String contact;
  final String resetToken;
  final bool isMidwife;

  const CreateNewPasswordScreen({
    super.key,
    required this.contact,
    required this.resetToken,
    this.isMidwife = false,
  });

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  PasswordStrength _strength = PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final pass = _passwordController.text;
    if (pass.isEmpty) {
      setState(() => _strength = PasswordStrength.none);
      return;
    }
    
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass) && RegExp(r'[!@#\$&*~]').hasMatch(pass)) score++;

    setState(() {
      if (score <= 1) {
        _strength = PasswordStrength.weak;
      } else if (score == 2) {
        _strength = PasswordStrength.medium;
      } else {
        _strength = PasswordStrength.strong;
      }
    });
  }

  bool _isValid() {
    final p1 = _passwordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1.length < 8) return false;
    if (p1 != p2) return false;
    if (_strength == PasswordStrength.weak || _strength == PasswordStrength.none) return false;

    return true;
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? Colors.green : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_isValid()) return;
    
    setState(() => _isLoading = true);

    final res = await AuthService.resetPassword(
      contact: widget.contact,
      newPassword: _passwordController.text,
      resetToken: widget.resetToken,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordResetSuccessScreen(isMidwife: widget.isMidwife),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final passwordsMatch = pass.isNotEmpty && confirm.isNotEmpty && pass == confirm;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundMintWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Pops back to ForgotPasswordScreen securely
        ),
        title: Text(
          AppLocalizations.of(context)!.createNewPassword,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.createNewPassword,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a strong new password for your Her Well account.',
              style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey.shade700),
            ),
            SizedBox(height: 36),

            PasswordInputField(
              controller: _passwordController,
              label: AppLocalizations.of(context)!.newPassword,
              hint: 'Enter your new password',
            ),
            
            const SizedBox(height: 12),
            PasswordStrengthIndicator(strength: _strength),
            
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.passwordMustContain,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGray),
            ),
            const SizedBox(height: 8),
            _buildRequirement('At least 8 characters', pass.length >= 8),
            _buildRequirement('One uppercase & lowercase letter', RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[a-z]').hasMatch(pass)),
            _buildRequirement('One number', RegExp(r'[0-9]').hasMatch(pass)),
            _buildRequirement('One special character (e.g. !, @, #, \$, %)', RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass)),

            SizedBox(height: 24),

            PasswordInputField(
              controller: _confirmPasswordController,
              label: AppLocalizations.of(context)!.confirmNewPassword,
              hint: 'Re-enter your new password',
              onChanged: (v) => setState((){}),
            ),
            
            if (confirm.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      passwordsMatch ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: passwordsMatch ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                      style: TextStyle(
                        fontSize: 13,
                        color: passwordsMatch ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isValid() && !_isLoading && passwordsMatch) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
