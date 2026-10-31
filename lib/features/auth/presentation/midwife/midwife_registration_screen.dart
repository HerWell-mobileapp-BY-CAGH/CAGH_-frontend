import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/auth/presentation/otp_verification_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/standard_app_bar.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/onboarding/presentation/user_type_selection_screen.dart';

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

  String _selectedProfession = 'Midwife';
  final List<String> _professions = [
    'Midwife',
    'Nurse',
    'General Practitioner (GP)',
    'Obstetrician / Gynecologist',
    'Psychologist',
    'Psychiatrist',
    'Health Officer',
    'Other Healthcare Professional',
  ];

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
        _confirmPasswordError =
            AppLocalizations.of(context)!.valPasswordConfirmReq;
      } else if (value != _passwordController.text) {
        _confirmPasswordError =
            AppLocalizations.of(context)!.valPasswordMismatch;
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
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.failedToUploadFile}: $e'),
        ),
      );
    }
  }

  String _getProfessionLabel(BuildContext context, String prof) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return prof;
    switch (prof) {
      case 'Midwife':
        return l10n.professionMidwife;
      case 'Nurse':
        return l10n.professionNurse;
      case 'General Practitioner (GP)':
        return l10n.professionDoctor;
      case 'Obstetrician / Gynecologist':
        return l10n.professionGyn;
      case 'Psychologist':
        return l10n.professionPsychologist;
      case 'Psychiatrist':
        return l10n.professionPsychiatrist;
      case 'Health Officer':
        return l10n.professionHealthOfficer;
      case 'Other Healthcare Professional':
        return l10n.professionOther;
      default:
        return prof;
    }
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final dob = _dobController.text;
    final hospital = _hospitalController.text.trim();

    setState(() {
      _firstNameError = firstName.isEmpty
          ? AppLocalizations.of(context)!.firstNameRequired
          : null;
      _lastNameError = lastName.isEmpty
          ? AppLocalizations.of(context)!.lastNameRequired
          : null;
      _emailError = email.isEmpty
          ? AppLocalizations.of(context)!.valEmailReq
          : null;
      _dobError = dob.isEmpty
          ? AppLocalizations.of(context)!.dateOfBirthRequired
          : null;

      if (password.isEmpty) {
        _passwordError = AppLocalizations.of(context)!.valPasswordReq;
      } else if (password.length < 8) {
        _passwordError = AppLocalizations.of(context)!.passwordMinLength;
      } else {
        _passwordError = null;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError =
            AppLocalizations.of(context)!.valPasswordConfirmReq;
      } else if (password != confirmPassword) {
        _confirmPasswordError =
            AppLocalizations.of(context)!.valPasswordMismatch;
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
      setState(() => _firstNameError =
          AppLocalizations.of(context)!.nameNoSpecialChars);
      return;
    }
    if (!nameRegExp.hasMatch(lastName)) {
      setState(() => _lastNameError =
          AppLocalizations.of(context)!.nameNoSpecialChars);
      return;
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() =>
          _emailError = AppLocalizations.of(context)!.valInvalidEmail);
      return;
    }

    if (phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final ethPhoneRegExp = RegExp(r'^(?:\+251|0)?[97]\d{8}$');
      if (!ethPhoneRegExp.hasMatch(cleanPhone)) {
        setState(() =>
            _phoneError = AppLocalizations.of(context)!.valInvalidPhone);
        return;
      }
    }

    if (password != confirmPassword) {
      setState(() => _confirmPasswordError =
          AppLocalizations.of(context)!.valPasswordMismatch);
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
      hospitalName: hospital.isNotEmpty
          ? '$hospital ($_selectedProfession)'
          : _selectedProfession,
      specialty: _selectedProfession,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      CustomSnackBar.show(
        context,
        message: 'Professional registration successful! Verify OTP.',
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF6F8F5);
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final primaryDarkGreen = const Color(0xFF385A2E);
    final linkColor =
        isDark ? const Color(0xFF66BB6A) : const Color(0xFF1B5E20);

    void navigateToRoleSelection() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const UserTypeSelectionScreen()),
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
          title: AppLocalizations.of(context)?.midwifeRegistration ??
              'Professional Sign Up',
          showLanguagePicker: true,
          onBack: navigateToRoleSelection,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Top Header Card
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
                        AppLocalizations.of(context)?.midwifeRegistration ??
                            'Professional Sign Up',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Role Subtitle
                      Text(
                        'For healthcare professionals',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      Text(
                        'Join HerWell\'s certified network of healthcare providers',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Section Header: Personal Details
                      _buildSectionHeader(
                        icon: Icons.person_outline,
                        title: AppLocalizations.of(context)!.personalDetails,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 14),

                      // First & Last Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                    AppLocalizations.of(context)!.firstName,
                                    textColor),
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
                                _buildLabel(
                                    AppLocalizations.of(context)!.lastName,
                                    textColor),
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
                      _buildLabel(
                          AppLocalizations.of(context)!.phoneNumberEthiopia,
                          textColor),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
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
                      _buildLabel(
                          AppLocalizations.of(context)!.emailAddress,
                          textColor),
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
                      _buildLabel(
                          AppLocalizations.of(context)!.dateOfBirth, textColor),
                      _buildTextField(
                        controller: _dobController,
                        hint: AppLocalizations.of(context)!.selectDateOfBirth,
                        prefixIcon: Icons.calendar_today_outlined,
                        readOnly: true,
                        errorText: _dobError,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1995),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            if (!mounted) return;
                            _dobController.text =
                                "${date.day}/${date.month}/${date.year}";
                            setState(() {
                              _dobError = null;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Section Header: Professional Details
                      _buildSectionHeader(
                        icon: Icons.medical_services_outlined,
                        title: 'PROFESSIONAL CREDENTIALS',
                        textColor: textColor,
                      ),
                      const SizedBox(height: 14),

                      // Profession Dropdown
                      _buildLabel(
                          AppLocalizations.of(context)?.profession ??
                              'Profession',
                          textColor),
                      DropdownButtonFormField<String>(
                        value: _selectedProfession,
                        items: _professions.map((prof) {
                          return DropdownMenuItem<String>(
                            value: prof,
                            child: Text(
                              _getProfessionLabel(context, prof),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedProfession = val);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryGreen, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Hospital Affiliation
                      _buildLabel(
                          AppLocalizations.of(context)!
                              .hospitalAffiliationOptional,
                          textColor),
                      _buildTextField(
                        controller: _hospitalController,
                        hint:
                            'e.g. Black Lion Hospital, St. Paul\'s, or Clinic',
                        prefixIcon: Icons.local_hospital_outlined,
                      ),

                      const SizedBox(height: 24),

                      // Section Header: Security
                      _buildSectionHeader(
                        icon: Icons.shield_outlined,
                        title: 'SECURITY',
                        textColor: textColor,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _buildLabel(
                          AppLocalizations.of(context)!.password, textColor),
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
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      _buildLabel(
                          AppLocalizations.of(context)!.confirmPassword,
                          textColor),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: AppLocalizations.of(context)!.confirmPassword,
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
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section Header: CV / Documents
                      _buildSectionHeader(
                        icon: Icons.upload_file_outlined,
                        title: 'DOCUMENTS (OPTIONAL)',
                        textColor: textColor,
                      ),
                      const SizedBox(height: 12),

                      // CV Upload Zone
                      GestureDetector(
                        onTap: _pickCV,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: selectedFile == null
                                ? (isDark
                                    ? Colors.grey.shade800.withValues(alpha: 0.5)
                                    : Colors.grey.shade50)
                                : AppColors.mintLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedFile == null
                                  ? (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300)
                                  : AppColors.primaryGreen,
                              width: selectedFile == null ? 1 : 1.5,
                            ),
                          ),
                          child: selectedFile == null
                              ? Column(
                                  children: [
                                    const Icon(Icons.cloud_upload_outlined,
                                        size: 32,
                                        color: AppColors.primaryGreen),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!.cvResume,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PDF, DOC, DOCX up to 10MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.description_outlined,
                                        color: AppColors.primaryGreen,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedFile!.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() => selectedFile = null);
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Verification Notice Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.mintLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primaryGreen
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .midwifeReviewNotice,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
                                  AppLocalizations.of(context)!.register,
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
                      AppLocalizations.of(context)?.alreadyHaveAccount ??
                          'Already have an account? ',
                      style: TextStyle(
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade700,
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
                            MaterialPageRoute(
                                builder: (context) =>
                                    const MidwifeLoginScreen()),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ],
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryGreen, width: 1.5),
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
                      child:
                          Icon(Icons.error_outline, color: Colors.red, size: 14),
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
