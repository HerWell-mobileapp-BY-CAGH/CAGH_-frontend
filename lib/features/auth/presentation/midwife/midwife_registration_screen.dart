import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../otp_verification_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class MidwifeRegistrationScreen extends StatefulWidget {
  const MidwifeRegistrationScreen({super.key});

  @override
  State<MidwifeRegistrationScreen> createState() =>
      _MidwifeRegistrationScreenState();
}

class _MidwifeRegistrationScreenState extends State<MidwifeRegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _licenseError;
  String? _passwordError;
  String? _confirmPasswordError;

  String? selectedQualification;
  final List<String> qualifications = [
    'Bachelor of Midwifery',
    'Diploma in Midwifery',
    'Master of Midwifery',
    'Certificate in Midwifery',
  ];

  final List<String> expertiseOptions = [
    'Puberty Education',
    'Menstrual Health',
    'Adolescent Psychology',
    'Nutrition & Growth',
    'Sexual Education',
    'Mental Wellbeing',
  ];

  final Set<String> selectedExpertise = {};
  PlatformFile? selectedFile;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateFirstName(String value) {
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    setState(() {
      if (value.trim().isEmpty) {
        _firstNameError = LanguageService.tr(context, 'val_name_req');
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
        _lastNameError = LanguageService.tr(context, 'val_name_req');
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
        _emailError = LanguageService.tr(context, 'val_email_req');
      } else if (!emailRegExp.hasMatch(value.trim())) {
        _emailError = LanguageService.tr(context, 'val_invalid_email');
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
          _phoneError = LanguageService.tr(context, 'val_invalid_phone');
        } else {
          _phoneError = null;
        }
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = LanguageService.tr(context, 'val_password_req');
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = LanguageService.tr(context, 'val_password_confirm_req');
      } else if (value != _passwordController.text) {
        _confirmPasswordError = LanguageService.tr(context, 'val_password_mismatch');
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  Future<void> _pickCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const Expanded(
                      child: Text(
                        'Join Our Team',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.creamAlt,
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
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medical_services,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Midwife Registration',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personal Details
                  _buildSection(
                    icon: Icons.person_outline,
                    title: 'Personal Details',
                    children: [
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
                                  hint: 'e.g. Mitchell',
                                  errorText: _lastNameError,
                                  onChanged: _validateLastName,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Email Address'),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'sarah.m@example.com',
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Phone Number (Ethiopia)'),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text('🇪🇹 +251', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              hint: '911 234 567',
                              keyboardType: TextInputType.phone,
                              errorText: _phoneError,
                              onChanged: _validatePhone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Password'),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Create a password',
                        obscureText: _obscurePassword,
                        onChanged: _validatePassword,
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
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Confirm Password'),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm your password',
                        obscureText: _obscureConfirm,
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
                        errorText: _confirmPasswordError,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Credentials
                  _buildSection(
                    icon: Icons.verified_user_outlined,
                    title: 'Credentials',
                    children: [
                      _buildLabel('License Number'),
                      _buildTextField(
                        controller: _licenseController,
                        hint: 'State/National License ID',
                        errorText: _licenseError,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Primary Qualification'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedQualification,
                            isExpanded: true,
                            hint: const Text('Select qualification'),
                            items: qualifications.map((q) {
                              return DropdownMenuItem(value: q, child: Text(q));
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedQualification = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Years of Experience
                  _buildSection(
                    icon: Icons.work_history_outlined,
                    title: 'Experience',
                    children: [
                      _buildLabel('Years of Experience'),
                      _buildTextField(
                        controller: TextEditingController(), // Just a dummy for now since this screen drops data anyway
                        hint: 'e.g., 5',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Professional CV
                  _buildSection(
                    icon: Icons.upload_file_outlined,
                    title: 'Professional CV',
                    children: [
                      GestureDetector(
                        onTap: _pickCV,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: selectedFile == null
                                ? Colors.grey.shade50
                                : AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedFile == null
                                  ? Colors.grey.shade300
                                  : AppColors.primaryGreen,
                              width: selectedFile == null ? 1 : 1.5,
                            ),
                          ),
                          child: selectedFile == null
                              ? Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 36, color: Colors.grey.shade500),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to upload your CV or resume',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF, DOC (Max 5MB)',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          )
                              : Row(
                            children: [
                              const Icon(Icons.insert_drive_file,
                                  color: AppColors.primaryGreen, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedFile!.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() => selectedFile = null);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final firstName = _firstNameController.text.trim();
                              final lastName = _lastNameController.text.trim();
                              final email = _emailController.text.trim();
                              final phone = _phoneController.text.trim();
                              final password = _passwordController.text;
                              final confirmPassword = _confirmPasswordController.text;

                              setState(() {
                                _firstNameError = firstName.isEmpty ? LanguageService.tr(context, 'val_name_req') : null;
                                _lastNameError = lastName.isEmpty ? LanguageService.tr(context, 'val_name_req') : null;
                                _emailError = email.isEmpty ? LanguageService.tr(context, 'val_email_req') : null;
                                _passwordError = password.isEmpty ? LanguageService.tr(context, 'val_password_req') : null;
                                _confirmPasswordError = confirmPassword.isEmpty ? LanguageService.tr(context, 'val_password_confirm_req') : null;
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
                                setState(() => _emailError = LanguageService.tr(context, 'val_invalid_email'));
                                return;
                              }

                              if (phone.isNotEmpty) {
                                final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
                                final ethPhoneRegExp = RegExp(r'^(?:\+251|0)?[97]\d{8}$');
                                if (!ethPhoneRegExp.hasMatch(cleanPhone)) {
                                  setState(() => _phoneError = LanguageService.tr(context, 'val_invalid_phone'));
                                  return;
                                }
                              }

                              if (password != confirmPassword) {
                                setState(() => _confirmPasswordError = LanguageService.tr(context, 'val_password_mismatch'));
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
                                role: 'MIDWIFE',
                                phone: phone.isNotEmpty ? fullPhone : null,
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (result.success) {
                                CustomSnackBar.show(
                                  context,
                                  message: 'Midwife registration successful! Verify OTP.',
                                  type: SnackBarType.success,
                                );
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) => OtpVerificationScreen(
                                      contact: email,
                                      isMidwife: true,
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
                          : const Text(
                              'Continue to Admin Check',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      'By continuing, you agree to the professional\nterms of service and privacy policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textGray,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: suffixIcon,
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
