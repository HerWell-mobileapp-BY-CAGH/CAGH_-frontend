import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../otp_verification_screen.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';

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

  String? selectedQualification;
  final List<String> qualifications = [
    'Bachelor of Midwifery',
    'Diploma in Midwifery',
    'Master of Midwifery',
    'Certificate in Midwifery',
  ];

  final List<String> expertiseOptions = [
    'Antenatal Care',
    'Postnatal Support',
    'Adolescent Health',
    'Contraception',
    'Breastfeeding',
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

  Future<void> _pickCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
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
      backgroundColor: const Color(0xFFFFF8F5),
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
                            color: const Color(0xFF1B5E20),
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
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Step 1 of 3: Professional Profile',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
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
                            child: const Text('🇪🇹 +251', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              hint: '911 234 567',
                              keyboardType: TextInputType.phone,
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
                      const SizedBox(height: 16),
                      _buildLabel('Confirm Password'),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm your password',
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
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Primary Qualification'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
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

                  // Areas of Expertise
                  _buildSection(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Areas of Expertise',
                    children: [
                      const Text(
                        'Select all that apply to your practice.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: expertiseOptions.map((item) {
                          final isSelected = selectedExpertise.contains(item);
                          return FilterChip(
                            label: Text(item),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedExpertise.add(item);
                                } else {
                                  selectedExpertise.remove(item);
                                }
                              });
                            },
                            selectedColor: const Color(0xFFC8E6C9),
                            checkmarkColor: const Color(0xFF1B5E20),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1B5E20)
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1B5E20)
                                  : Colors.grey.shade300,
                            ),
                          );
                        }).toList(),
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
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedFile == null
                                  ? Colors.grey.shade300
                                  : const Color(0xFF1B5E20),
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
                                  color: Color(0xFF1B5E20), size: 32),
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
                                        color: Color(0xFF1A1A1A),
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

                              if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in First Name, Last Name, Email, and Password'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Name Validation: Letters & spaces only
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

                              // Email validation
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

                              // Ethiopian Phone validation
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
                                role: 'MIDWIFE',
                                phone: phone.isNotEmpty ? fullPhone : null,
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (result.success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Midwife registration successful! Verify OTP.'),
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
        color: Colors.white,
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
              Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
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
          color: Color(0xFF333333),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
        ),
      ),
    );
  }
}
