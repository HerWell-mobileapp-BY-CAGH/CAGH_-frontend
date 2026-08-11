import 'package:flutter/material.dart';
import '../otp_verification_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF5),
      body: Column(
        children: [
          // Green Header Bar
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
                        LanguageService.tr('app_title'),
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
                  Text(
                    LanguageService.tr('create_account'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    LanguageService.tr('create_account_subtitle'),
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
                              hint: 'e.g. Sarah',
                              prefixIcon: Icons.person_outline,
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
                              hint: 'e.g. Tesfaye',
                              prefixIcon: Icons.person_outline,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '🇪🇹 +251',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20),
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
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Email Address
                  _buildLabel('Email Address'),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'name@domain.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
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
                        _dobController.text =
                            "${date.day}/${date.month}/${date.year}";
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  // Password
                  _buildLabel(LanguageService.tr('password')),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Create a password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Confirm Password
                  _buildLabel(LanguageService.tr('confirm_password')),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirm,
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
                          activeColor: const Color(0xFF1B5E20),
                          onChanged: (value) {
                            setState(() => _agreeTerms = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageService.tr('agree_terms'),
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

                              // 1. Required fields check
                              if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // 2. Name validation: No numbers allowed
                              final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
                              if (!nameRegExp.hasMatch(firstName)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('First Name cannot contain numbers or special characters'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (!nameRegExp.hasMatch(lastName)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Last Name cannot contain numbers or special characters'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // 3. Email validation
                              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(email)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid email address (e.g. name@domain.com)'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // 4. Ethiopian Phone validation (Optional if empty, but if provided must follow format)
                              if (phone.isNotEmpty) {
                                final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
                                final ethPhoneRegExp = RegExp(r'^(?:\+251|0)?[97]\d{8}$');
                                if (!ethPhoneRegExp.hasMatch(cleanPhone)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid Ethiopian phone number (e.g. 0911234567 or +251911234567)'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }

                              // 5. Password match check
                              if (password != confirmPassword) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Passwords do not match'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              setState(() => _isLoading = true);

                              final fullName = "$firstName $lastName";
                              final fullPhone = phone.startsWith('+251')
                                  ? phone
                                  : (phone.startsWith('0') ? '+251${phone.substring(1)}' : '+251$phone');

                              final result = await AuthService.register(
                                email: email,
                                password: password,
                                passwordConfirm: confirmPassword,
                                fullName: fullName,
                                role: 'PATIENT',
                                phone: phone.isNotEmpty ? fullPhone : null,
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (result.success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration successful! Please verify OTP.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) => OtpVerificationScreen(
                                      contact: email,
                                    ),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(result.message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
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

                  const SizedBox(height: 20),

                  // Already have account
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          LanguageService.tr('already_have_account'),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            LanguageService.tr('login'),
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
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
          color: Color(0xFF333333),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
        ),
      ),
    );
  }
}
