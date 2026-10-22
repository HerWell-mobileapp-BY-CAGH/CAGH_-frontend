import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/app_text_field.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;

      if (oldPassword.isEmpty) {
        _oldPasswordError = l10n.currentPasswordRequired;
      }

      if (newPassword.isEmpty) {
        _newPasswordError = l10n.passwordMinLength;
      } else if (newPassword.length < 8) {
        _newPasswordError = l10n.passwordMinLength;
      } else if (newPassword == oldPassword) {
        _newPasswordError = 'New password must be different from current password';
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = l10n.passwordsDoNotMatch;
      } else if (newPassword != confirmPassword) {
        _confirmPasswordError = l10n.passwordsDoNotMatch;
      }
    });

    if (_oldPasswordError != null || _newPasswordError != null || _confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      newPasswordConfirm: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      CustomSnackBar.show(
        context,
        message: l10n.passwordChangedSuccessfully,
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    } else {
      final msg = res.message;
      final lower = msg.toLowerCase();
      setState(() {
        if (lower.contains('current password') || lower.contains('old_password') || lower.contains('old password') || lower.contains('incorrect')) {
          _oldPasswordError = 'Current password is incorrect';
        } else if (lower.contains('new_password_confirm') || lower.contains('match')) {
          _confirmPasswordError = l10n.passwordsDoNotMatch;
        } else if (lower.contains('new_password') || lower.contains('short') || lower.contains('entirely numeric')) {
          _newPasswordError = msg;
        } else {
          CustomSnackBar.show(
            context,
            message: msg,
            type: SnackBarType.error,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? (isDark ? theme.scaffoldBackgroundColor : Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.changePassword,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security & Account Protection',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a strong, unique password to keep your health data private.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Current Password
                    AppTextField(
                      controller: _oldPasswordController,
                      labelText: l10n.currentPassword,
                      hintText: l10n.enterCurrentPassword,
                      isPassword: true,
                      errorText: _oldPasswordError,
                      prefixIcon: const Icon(Icons.lock_open_rounded),
                      onChanged: (_) {
                        if (_oldPasswordError != null) setState(() => _oldPasswordError = null);
                      },
                    ),
                    const SizedBox(height: 18),

                    // New Password
                    AppTextField(
                      controller: _newPasswordController,
                      labelText: l10n.newPassword,
                      hintText: l10n.enterNewPassword,
                      isPassword: true,
                      errorText: _newPasswordError,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      onChanged: (_) {
                        if (_newPasswordError != null) setState(() => _newPasswordError = null);
                      },
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'Minimum 8 characters with letters and numbers',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Confirm New Password
                    AppTextField(
                      controller: _confirmPasswordController,
                      labelText: l10n.confirmNewPassword,
                      hintText: l10n.reEnterNewPassword,
                      isPassword: true,
                      errorText: _confirmPasswordError,
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                      onChanged: (_) {
                        if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                l10n.changePassword,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
