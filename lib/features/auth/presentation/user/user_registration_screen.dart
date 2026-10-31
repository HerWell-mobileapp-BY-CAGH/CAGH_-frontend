import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/auth/presentation/otp_verification_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/standard_app_bar.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/onboarding/presentation/user_type_selection_screen.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _dobError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateFirstName(String value) {
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    setState(() {
      if (value.trim().isEmpty) {
        _firstNameError = AppLocalizations.of(context)!.firstNameRequired;
      } else if (!nameRegExp.hasMatch(value.trim())) {
        _firstNameError = AppLocalizations.of(context)!.nameNoSpecialChars;
      } else {
        _firstNameError = null;
      }
    });
  }

  void _validateLastName(String value) {
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    setState(() {
      if (value.trim().isEmpty) {
        _lastNameError = AppLocalizations.of(context)!.lastNameRequired;
      } else if (!nameRegExp.hasMatch(value.trim())) {
        _lastNameError = AppLocalizations.of(context)!.nameNoSpecialChars;
      } else {
        _lastNameError = null;
      }
    });
  }

  void _validateEmail(String value) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = AppLocalizations.of(context)!.valEmailReq;
      } else if (!emailRegExp.hasMatch(value.trim())) {
        _emailError = AppLocalizations.of(context)!.valInvalidEmail;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _phoneError = null;
      } else {
        final cleanPhone = value.trim().replaceAll(RegExp(r'\s+'), '');
        final ethPhoneRegExp = RegExp(r'^(?:\+251|0)?[97]\d{8}$');
        if (!ethPhoneRegExp.hasMatch(cleanPhone)) {
          _phoneError = AppLocalizations.of(context)!.valInvalidPhone;
        } else {
          _phoneError = null;
        }
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = AppLocalizations.of(context)!.valPasswordReq;
      } else if (value.length < 8) {
        _passwordError = AppLocalizations.of(context)!.passwordMinLength;
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = AppLocalizations.of(context)!.valPasswordConfirmReq;
      } else if (value != _passwordController.text) {
        _confirmPasswordError = AppLocalizations.of(context)!.valPasswordMismatch;
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final dob = _dobController.text;

    setState(() {
      _firstNameError = firstName.isEmpty ? AppLocalizations.of(context)!.firstNameRequired : null;
      _lastNameError = lastName.isEmpty ? AppLocalizations.of(context)!.lastNameRequired : null;
      _emailError = email.isEmpty ? AppLocalizations.of(context)!.valEmailReq : null;
      _dobError = dob.isEmpty ? AppLocalizations.of(context)!.dateOfBirthRequired : null;

      if (password.isEmpty) {
        _passwordError = AppLocalizations.of(context)!.valPasswordReq;
      } else if (password.length < 8) {
        _passwordError = AppLocalizations.of(context)!.passwordMinLength;
      } else {
        _passwordError = null;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = AppLocalizations.of(context)!.valPasswordConfirmReq;
      } else if (password != confirmPassword) {
        _confirmPasswordError = AppLocalizations.of(context)!.valPasswordMismatch;
      } else {
        _confirmPasswordError = null;
      }

      _phoneError = null;
    });

    if (_firstNameError != null ||
        _lastNameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        _dobError != null) {
      return;
    }

    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegExp.hasMatch(firstName)) {
      setState(() => _firstNameError = AppLocalizations.of(context)!.nameNoSpecialChars);
      return;
    }
    if (!nameRegExp.hasMatch(lastName)) {
      setState(() => _lastNameError = AppLocalizations.of(context)!.nameNoSpecialChars);
      return;
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() => _emailError = AppLocalizations.of(context)!.valInvalidEmail);
      return;
    }

    if (phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final ethPhoneRegExp = RegExp(r'^(?:\+251|0)?[97]\d{8}$');
      if (!ethPhoneRegExp.hasMatch(cleanPhone)) {
        setState(() => _phoneError = AppLocalizations.of(context)!.valInvalidPhone);
        return;
      }
    }

    if (password != confirmPassword) {
      setState(() => _confirmPasswordError = AppLocalizations.of(context)!.valPasswordMismatch);
      return;
    }

    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);

    final fullPhone = phone.startsWith('+251')
        ? phone
        : (phone.startsWith('0') ? '+251${phone.substring(1)}' : '+251$phone');

    final result = await AuthService.register(
      email: email,
      password: password,
      passwordConfirm: confirmPassword,
      firstName: firstName,
      lastName: lastName,
      role: 'PATIENT',
      phone: phone.isNotEmpty ? fullPhone : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      CustomSnackBar.show(
        context,
        message: 'Registration successful! Please verify OTP.',
        type: SnackBarType.success,
      );
      navigator.push(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            contact: email,
          ),
        ),
      );
    } else {
      CustomSnackBar.show(
        context,
        message: result.message,
        type: SnackBarType.error,
      );
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
          title: AppLocalizations.of(context)?.userRegistration ?? 'User Sign Up',
          showLanguagePicker: true,
          onBack: navigateToRoleSelection,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Circular Logo
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
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
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        AppLocalizations.of(context)?.createAccount ?? 'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Role subtitle
                      Text(
                        'For adolescent girls and young women',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        AppLocalizations.of(context)?.createAccountSubtitle ??
                            'Your trusted companion for women\'s health and professional healthcare support',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // First & Last Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(AppLocalizations.of(context)!.firstName, textColor),
                                _buildTextField(
                                  controller: _firstNameController,
                                  hint: AppLocalizations.of(context)!.firstName,
                                  prefixIcon: Icons.person_outline,
                                  errorText: _firstNameError,
                                  onChanged: _validateFirstName,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(AppLocalizations.of(context)!.lastName, textColor),
                                _buildTextField(
                                  controller: _lastNameController,
                                  hint: AppLocalizations.of(context)!.lastName,
                                  prefixIcon: Icons.person_outline,
                                  errorText: _lastNameError,
                                  onChanged: _validateLastName,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Phone Number
                      _buildLabel(AppLocalizations.of(context)!.phoneNumberEthiopia, textColor),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '🇪🇹 +251',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              hint: '911 234 567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              errorText: _phoneError,
                              onChanged: _validatePhone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Email Address
                      _buildLabel(AppLocalizations.of(context)!.emailAddress, textColor),
                      _buildTextField(
                        controller: _emailController,
                        hint: AppLocalizations.of(context)!.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: _validateEmail,
                      ),

                      const SizedBox(height: 16),

                      // Date of Birth
                      _buildLabel(AppLocalizations.of(context)!.dateOfBirth, textColor),
                      _buildTextField(
                        controller: _dobController,
                        hint: AppLocalizations.of(context)!.selectDateOfBirth,
                        prefixIcon: Icons.calendar_today_outlined,
                        readOnly: true,
                        errorText: _dobError,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            if (!mounted) return;
                            _dobController.text = "${date.day}/${date.month}/${date.year}";
                            setState(() {
                              _dobError = null;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _buildLabel(AppLocalizations.of(context)!.password, textColor),
                      _buildTextField(
                        controller: _passwordController,
                        hint: AppLocalizations.of(context)!.password,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        onChanged: _validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      _buildLabel(AppLocalizations.of(context)!.confirmPassword, textColor),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: AppLocalizations.of(context)!.confirmPassword,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        errorText: _confirmPasswordError,
                        onChanged: _validateConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Register Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: !_isLoading ? _handleRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryDarkGreen,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
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
                                  AppLocalizations.of(context)?.register ?? 'Create Account',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.alreadyHaveAccount ?? 'Already have an account? ',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                          );
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)?.login ?? 'Login',
                        style: TextStyle(
                          color: linkColor,
                          fontSize: 14,
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

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    VoidCallback? onTap,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.primaryGreen, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        error: errorText != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1.0),
                      child: Icon(Icons.error_outline, color: Colors.red, size: 14),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        errorText,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
