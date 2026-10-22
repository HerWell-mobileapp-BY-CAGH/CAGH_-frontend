import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../otp_verification_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _hospitalController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _dobError;

  PlatformFile? selectedFile;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _hospitalController.dispose();
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

  void _validateDOB(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _dobError = AppLocalizations.of(context)!.dateOfBirthRequired;
      } else {
        _dobError = null;
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
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUploadFile}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.midwifeRegistration,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // (Header card removed)

                  const SizedBox(height: 24),

                  // Personal Details
                  _buildSection(
                    icon: Icons.person_outline,
                    title: AppLocalizations.of(context)!.personalDetails,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(AppLocalizations.of(context)!.firstName),
                                _buildTextField(
                                  controller: _firstNameController,
                                  hint: AppLocalizations.of(context)!.firstName,
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
                                _buildLabel(AppLocalizations.of(context)!.lastName),
                                _buildTextField(
                                  controller: _lastNameController,
                                  hint: AppLocalizations.of(context)!.lastName,
                                  errorText: _lastNameError,
                                  onChanged: _validateLastName,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(AppLocalizations.of(context)!.emailAddress),
                      _buildTextField(
                        controller: _emailController,
                        hint: AppLocalizations.of(context)!.emailAddress,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(AppLocalizations.of(context)!.phoneNumberEthiopia),
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
                      _buildLabel(AppLocalizations.of(context)!.dateOfBirth),
                      _buildTextField(
                        controller: _dobController,
                        hint: AppLocalizations.of(context)!.selectDateOfBirth,
                        errorText: _dobError,
                        onChanged: _validateDOB,
                        suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(AppLocalizations.of(context)!.hospitalAffiliationOptional),
                      _buildTextField(
                        controller: _hospitalController,
                        hint: 'e.g. Black Lion Hospital, St. Paul\'s, or Health Center',
                        prefixIcon: const Icon(Icons.local_hospital_outlined, color: AppColors.primaryGreen, size: 20),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(AppLocalizations.of(context)!.password),
                      _buildTextField(
                        controller: _passwordController,
                        hint: AppLocalizations.of(context)!.password,
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
                      _buildLabel(AppLocalizations.of(context)!.confirmPassword),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: AppLocalizations.of(context)!.confirmPassword,
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

                  // CV / Resume
                  _buildSection(
                    icon: Icons.post_add,
                    title: AppLocalizations.of(context)!.cvResume,
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
                                  size: 36, color: AppColors.primaryGreen),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.tapToUploadCv,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.cvFileFormatLimit,
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

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        // Registration logic remains the same
                        final firstName = _firstNameController.text.trim();
                        final lastName = _lastNameController.text.trim();
                        final email = _emailController.text.trim();
                        final phone = _phoneController.text.trim();
                        final password = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;

                        setState(() {
                          _firstNameError = firstName.isEmpty ? AppLocalizations.of(context)!.firstNameRequired : null;
                          _lastNameError = lastName.isEmpty ? AppLocalizations.of(context)!.lastNameRequired : null;
                          _emailError = email.isEmpty ? AppLocalizations.of(context)!.valEmailReq : null;

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

                        if (_firstNameError != null || _lastNameError != null || _emailError != null || _passwordError != null || _confirmPasswordError != null) {
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

                        final hospital = _hospitalController.text.trim();

                        final result = await AuthService.register(
                          email: email,
                          password: password,
                          passwordConfirm: confirmPassword,
                          firstName: firstName,
                          lastName: lastName,
                          role: 'MIDWIFE',
                          phone: phone.isNotEmpty ? fullPhone : null,
                          hospitalName: hospital.isNotEmpty ? hospital : null,
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
                              builder: (_) => OtpVerificationScreen(
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
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppLocalizations.of(context)!.register,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Info Text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.midwifeReviewNotice,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
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
    Widget? prefixIcon,
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
        fillColor: Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: prefixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        error: errorText != null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.0),
                    child: Icon(Icons.error, color: Colors.red, size: 14),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
