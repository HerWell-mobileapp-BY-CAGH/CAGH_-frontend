import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../otp_verification_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

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
  bool _agreeTerms = false;
  bool _isLoading = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

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
        _firstNameError = AppLocalizations.of(context)!.valNameReq;
      } else if (!nameRegExp.hasMatch(value.trim())) {
        _firstNameError = 'Cannot contain numbers or special characters';
      } else {
        _firstNameError = null;
      }
    });
  }

  void _validateLastName(String value) {
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    setState(() {
      if (value.trim().isEmpty) {
        _lastNameError = AppLocalizations.of(context)!.valNameReq;
      } else if (!nameRegExp.hasMatch(value.trim())) {
        _lastNameError = 'Cannot contain numbers or special characters';
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
        _phoneError = null; // Optional initially
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Green Header Bar
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
                      icon: Icon(Icons.arrow_back, color: AppColors.accentYellow),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.appTitle,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
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
                    AppLocalizations.of(context)!.createAccount,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    AppLocalizations.of(context)!.createAccountSubtitle,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // First Name & Last Name (Side by Side)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('First Name'),
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
                            _buildLabel('Last Name'),
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

                  const SizedBox(height: 18),

                  // Phone Number (Ethiopian Standard)
                  _buildLabel('Phone Number (Ethiopia)'),
                  Row(
                    children: [
                      Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '🇪🇹 +251',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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

                  SizedBox(height: 18),

                  // Email Address
                  _buildLabel('Email Address'),
                  _buildTextField(
                    controller: _emailController,
                    hint: AppLocalizations.of(context)!.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: _validateEmail,
                  ),

                  const SizedBox(height: 18),

                  // Date of Birth
                  _buildLabel('Date of Birth'),
                  _buildTextField(
                    controller: _dobController,
                    hint: 'Select your date of birth',
                    prefixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        if (!mounted) return;
                        _dobController.text =
                            "${date.day}/${date.month}/${date.year}";
                      }
                    },
                  ),

                  SizedBox(height: 18),

                  // Password
                  _buildLabel(AppLocalizations.of(context)!.password),
                  _buildTextField(
                    controller: _passwordController,
                    hint: AppLocalizations.of(context)!.password,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    onChanged: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 18),

                  // Confirm Password
                  _buildLabel(AppLocalizations.of(context)!.confirmPassword),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirm,
                    errorText: _confirmPasswordError,
                    onChanged: _validateConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeTerms,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) {
                            setState(() => _agreeTerms = value ?? false);
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.agreeTerms,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_agreeTerms && !_isLoading)
                          ? () async {
                              final firstName = _firstNameController.text.trim();
                              final lastName = _lastNameController.text.trim();
                              final email = _emailController.text.trim();
                              final phone = _phoneController.text.trim();
                              final password = _passwordController.text;
                              final confirmPassword = _confirmPasswordController.text;

                              setState(() {
                                _firstNameError = firstName.isEmpty ? AppLocalizations.of(context)!.valNameReq : null;
                                _lastNameError = lastName.isEmpty ? AppLocalizations.of(context)!.valNameReq : null;
                                _emailError = email.isEmpty ? AppLocalizations.of(context)!.valEmailReq : null;
                                _passwordError = password.isEmpty ? AppLocalizations.of(context)!.valPasswordReq : null;
                                _confirmPasswordError = confirmPassword.isEmpty ? AppLocalizations.of(context)!.valPasswordConfirmReq : null;
                                _phoneError = null;
                              });

                              if (_firstNameError != null || _lastNameError != null || _emailError != null || _passwordError != null || _confirmPasswordError != null) {
                                return;
                              }

                              final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
                              if (!nameRegExp.hasMatch(firstName)) {
                                setState(() => _firstNameError = 'Cannot contain numbers or special characters');
                                return;
                              }
                              if (!nameRegExp.hasMatch(lastName)) {
                                setState(() => _lastNameError = 'Cannot contain numbers or special characters');
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
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        disabledBackgroundColor: Colors.grey.shade400,
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
                          : const Text(
                              'Register >',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Already have account
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.alreadyHaveAccount,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            AppLocalizations.of(context)!.login,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textGray,
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorText: errorText,
      ),
    );
  }
}
