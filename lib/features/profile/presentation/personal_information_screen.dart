import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  String _firstName = '';
  String _lastName = '';
  String _fullName = '';
  String _dateOfBirth = 'Not set';
  String _phoneNumber = '';
  String _emailAddress = '';
  String _memberSince = '';

  int _selectedAvatarIndex = 0;
  final List<Map<String, dynamic>> _avatarOptions = [
    {
      'label': 'Original Photo',
      'bgColor': AppColors.lightGreen,
      'iconColor': AppColors.primaryGreen,
      'icon': Icons.person,
      'isAsset': true,
      'assetPath': 'assets/images/home_illustration.png',
    },
    {
      'label': 'Warm Amber',
      'bgColor': AppColors.cream,
      'iconColor': AppColors.accentYellow,
      'icon': Icons.face_rounded,
      'isAsset': false,
    },
    {
      'label': 'Ocean Blue',
      'bgColor': AppColors.infoBlueBg,
      'iconColor': AppColors.infoBlue,
      'icon': Icons.account_circle,
      'isAsset': false,
    },
    {
      'label': 'Royal Purple',
      'bgColor': AppColors.accentPurpleBg,
      'iconColor': AppColors.accentPurpleStrong,
      'icon': Icons.face_retouching_natural,
      'isAsset': false,
    },
    {
      'label': 'Soft Coral',
      'bgColor': AppColors.backgroundSoftPink,
      'iconColor': AppColors.errorRedDark,
      'icon': Icons.person_pin,
      'isAsset': false,
    },
  ];

  void _showChangePhotoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Profile Photo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Camera & Gallery
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              _selectedAvatarIndex = 1;
                            });
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final rawCustom = prefs.getString('user_profile_custom_saved');
                              final map = rawCustom != null ? jsonDecode(rawCustom) as Map<String, dynamic> : <String, dynamic>{};
                              map['avatar_index'] = 1;
                              await prefs.setString('user_profile_custom_saved', jsonEncode(map));
                            } catch (_) {}
                            AuthService.updateUserProfile({'avatar_index': 1});
                            AuthService.updateLocalUserData({'avatar_index': 1});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.cameraPhotoUpdated),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                          label: Text(AppLocalizations.of(context)!.takePhoto, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              _selectedAvatarIndex = 2;
                            });
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final rawCustom = prefs.getString('user_profile_custom_saved');
                              final map = rawCustom != null ? jsonDecode(rawCustom) as Map<String, dynamic> : <String, dynamic>{};
                              map['avatar_index'] = 2;
                              await prefs.setString('user_profile_custom_saved', jsonEncode(map));
                            } catch (_) {}
                            AuthService.updateUserProfile({'avatar_index': 2});
                            AuthService.updateLocalUserData({'avatar_index': 2});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.galleryPhotoUpdated),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined, color: AppColors.primaryGreen),
                          label: Text(AppLocalizations.of(context)!.fromGallery, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    AppLocalizations.of(context)!.chooseAvatarStyle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Avatar Options Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_avatarOptions.length, (index) {
                        final item = _avatarOptions[index];
                        final isSelected = index == _selectedAvatarIndex;

                        return GestureDetector(
                          onTap: () async {
                            setModalState(() {
                              _selectedAvatarIndex = index;
                            });
                            setState(() {
                              _selectedAvatarIndex = index;
                            });
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final rawCustom = prefs.getString('user_profile_custom_saved');
                              final map = rawCustom != null ? jsonDecode(rawCustom) as Map<String, dynamic> : <String, dynamic>{};
                              map['avatar_index'] = index;
                              await prefs.setString('user_profile_custom_saved', jsonEncode(map));
                            } catch (_) {}
                            AuthService.updateUserProfile({'avatar_index': index});
                            AuthService.updateLocalUserData({'avatar_index': index});
                            Navigator.pop(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profile photo updated to ${item['label']}!'),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: item['bgColor'] as Color,
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: item['iconColor'] as Color,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primaryGreen : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  DateTime _parseDateOfBirth(String dobString) {
    if (dobString.isEmpty || dobString == 'Loading...' || dobString == 'Not set' || dobString == 'Not provided') {
      return DateTime(2000, 1, 1);
    }
    // Try ISO format
    try {
      final parsed = DateTime.parse(dobString);
      if (parsed.isBefore(DateTime.now())) return parsed;
    } catch (_) {}

    // Try "Month Day, Year" or "Day Month Year"
    try {
      final cleaned = dobString.replaceAll(',', '').trim();
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length == 3) {
        const months = [
          'january', 'february', 'march', 'april', 'may', 'june',
          'july', 'august', 'september', 'october', 'november', 'december'
        ];
        final mIdx = months.indexOf(parts[0].toLowerCase());
        if (mIdx != -1) {
          final day = int.tryParse(parts[1]) ?? 1;
          final year = int.tryParse(parts[2]) ?? 2000;
          final dt = DateTime(year, mIdx + 1, day);
          if (dt.isBefore(DateTime.now())) return dt;
        }
      }
    } catch (_) {}

    return DateTime(2000, 1, 1);
  }

  Future<void> _loadUserData() async {
    // 1. Immediately read user_profile_custom_saved from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCustom = prefs.getString('user_profile_custom_saved');
      if (rawCustom != null && rawCustom.isNotEmpty) {
        final custom = jsonDecode(rawCustom) as Map<String, dynamic>;
        if (custom.containsKey('specialty') || custom.containsKey('experience_years') || custom.containsKey('title')) {
          await prefs.remove('user_profile_custom_saved');
        } else {
        final cF = custom['first_name']?.toString() ?? '';
        final cL = custom['last_name']?.toString() ?? '';
        final cFull = custom['full_name']?.toString() ?? '';
        final cPhone = custom['phone_number']?.toString() ?? '';
        final cEmail = custom['email']?.toString() ?? '';
        final cDob = custom['date_of_birth']?.toString() ?? '';
        final cAvatar = custom['avatar_index'];

        if (cF.isNotEmpty) _firstName = cF;
        if (cL.isNotEmpty) _lastName = cL;
        if (cFull.isNotEmpty) {
          _fullName = cFull;
        } else if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
          _fullName = '$_firstName $_lastName'.trim();
        }
        if (cPhone.isNotEmpty) _phoneNumber = cPhone;
        if (cEmail.isNotEmpty) _emailAddress = cEmail;
        if (cDob.isNotEmpty && cDob != 'Loading...' && cDob != 'Not provided') {
          _dateOfBirth = cDob;
        }
        if (cAvatar != null && cAvatar is int && cAvatar >= 0 && cAvatar < _avatarOptions.length) {
          _selectedAvatarIndex = cAvatar;
        }
        if (mounted) setState(() {});
        }
      }
    } catch (_) {}

    // 2. Load from AuthService.getUserData()
    try {
      final localData = await AuthService.getUserData();
      if (mounted) {
        final u = localData['user'] is Map ? (localData['user'] as Map) : localData;
        final profile = u['profile'] is Map
            ? (u['profile'] as Map)
            : (localData['profile'] is Map ? (localData['profile'] as Map) : {});

        if (u['date_joined'] != null) {
          try {
            final date = DateTime.parse(u['date_joined'].toString());
            _memberSince = 'Bloom Member since ${date.year}';
          } catch (_) {}
        }

        final fName = profile['first_name']?.toString() ?? u['first_name']?.toString() ?? localData['first_name']?.toString() ?? '';
        final lName = profile['last_name']?.toString() ?? u['last_name']?.toString() ?? localData['last_name']?.toString() ?? '';
        final cFullName = profile['full_name']?.toString() ?? u['full_name']?.toString() ?? localData['full_name']?.toString() ?? profile['name']?.toString() ?? u['name']?.toString() ?? localData['name']?.toString() ?? '';

        if (_firstName.isEmpty && fName.isNotEmpty) _firstName = fName;
        if (_lastName.isEmpty && lName.isNotEmpty) _lastName = lName;

        if (_fullName.isEmpty || _fullName == 'Loading...') {
          if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
            _fullName = '$_firstName $_lastName'.trim();
          } else if (cFullName.isNotEmpty) {
            _fullName = cFullName;
            final parts = cFullName.split(RegExp(r'\s+'));
            _firstName = parts.isNotEmpty ? parts.first : '';
            _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
        }

        final email = profile['email']?.toString() ?? u['email']?.toString() ?? localData['email']?.toString() ?? '';
        if ((_emailAddress.isEmpty || _emailAddress == 'Loading...') && email.isNotEmpty) {
          _emailAddress = email;
        }

        final phone = profile['phone_number']?.toString() ?? u['phone_number']?.toString() ?? localData['phone_number']?.toString() ?? profile['phone']?.toString() ?? u['phone']?.toString() ?? localData['phone']?.toString() ?? '';
        if ((_phoneNumber.isEmpty || _phoneNumber == 'Loading...') && phone.isNotEmpty) {
          _phoneNumber = phone;
        }

        final dob = profile['date_of_birth']?.toString() ?? u['date_of_birth']?.toString() ?? localData['date_of_birth']?.toString() ?? profile['dob']?.toString() ?? u['dob']?.toString() ?? localData['dob']?.toString() ?? '';
        if (_dateOfBirth.isEmpty || _dateOfBirth == 'Loading...' || _dateOfBirth == 'Not set') {
          if (dob.isNotEmpty && dob != 'Loading...' && dob != 'Not provided') {
            _dateOfBirth = dob;
          } else {
            _dateOfBirth = 'Not set';
          }
        }

        final avIdx = profile['avatar_index'] ?? u['avatar_index'] ?? localData['avatar_index'];
        if (avIdx is int && avIdx >= 0 && avIdx < _avatarOptions.length && _selectedAvatarIndex == 0) {
          _selectedAvatarIndex = avIdx;
        }

        setState(() {});
      }
    } catch (_) {}

    // 3. Background fetch from server (non-blocking, never overwrites saved values with blanks)
    try {
      final res = await AuthService.getProfile();
      if (res.success && res.data != null && mounted) {
        final data = res.data!;
        final u = data['user'] is Map ? (data['user'] as Map) : data;
        final profile = u['profile'] is Map
            ? (u['profile'] as Map)
            : (data['profile'] is Map ? (data['profile'] as Map) : {});

        final fName = profile['first_name']?.toString() ?? u['first_name']?.toString() ?? data['first_name']?.toString() ?? '';
        final lName = profile['last_name']?.toString() ?? u['last_name']?.toString() ?? data['last_name']?.toString() ?? '';
        final cFullName = profile['full_name']?.toString() ?? u['full_name']?.toString() ?? data['full_name']?.toString() ?? profile['name']?.toString() ?? u['name']?.toString() ?? data['name']?.toString() ?? '';

        setState(() {
          if (_firstName.isEmpty && fName.isNotEmpty) _firstName = fName;
          if (_lastName.isEmpty && lName.isNotEmpty) _lastName = lName;
          if (_fullName.isEmpty || _fullName == 'Loading...') {
            if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
              _fullName = '$_firstName $_lastName'.trim();
            } else if (cFullName.isNotEmpty) {
              _fullName = cFullName;
            }
          }

          final email = profile['email']?.toString() ?? u['email']?.toString() ?? data['email']?.toString() ?? '';
          if ((_emailAddress.isEmpty || _emailAddress == 'Loading...') && email.isNotEmpty) {
            _emailAddress = email;
          }

          final phone = profile['phone_number']?.toString() ?? u['phone_number']?.toString() ?? data['phone_number']?.toString() ?? profile['phone']?.toString() ?? u['phone']?.toString() ?? data['phone']?.toString() ?? '';
          if ((_phoneNumber.isEmpty || _phoneNumber == 'Loading...') && phone.isNotEmpty) {
            _phoneNumber = phone;
          }

          final dob = profile['date_of_birth']?.toString() ?? u['date_of_birth']?.toString() ?? data['date_of_birth']?.toString() ?? profile['dob']?.toString() ?? u['dob']?.toString() ?? data['dob']?.toString() ?? '';
          if ((_dateOfBirth.isEmpty || _dateOfBirth == 'Loading...' || _dateOfBirth == 'Not set') &&
              dob.isNotEmpty &&
              dob != 'Loading...' &&
              dob != 'Not provided') {
            _dateOfBirth = dob;
          }

          if (u['date_joined'] != null) {
            try {
              final date = DateTime.parse(u['date_joined'].toString());
              _memberSince = 'Bloom Member since ${date.year}';
            } catch (_) {}
          }
        });
      }
    } catch (_) {}
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final focusedBorder = AppColors.primaryGreen;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: fieldBorder, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: fieldBorder, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusedBorder, width: 1.8),
      ),
    );
  }

  void _showEditProfileModal() {
    String initFirst = _firstName;
    String initLast = _lastName;
    if (initFirst.isEmpty && initLast.isEmpty && _fullName.isNotEmpty && _fullName != 'Loading...') {
      final parts = _fullName.trim().split(RegExp(r'\s+'));
      initFirst = parts.isNotEmpty ? parts.first : '';
      initLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final firstNameController = TextEditingController(text: initFirst);
    final lastNameController = TextEditingController(text: initLast);
    final phoneController = TextEditingController(
      text: (_phoneNumber == 'Loading...' || _phoneNumber == 'Not set') ? '' : _phoneNumber,
    );
    final emailController = TextEditingController(
      text: (_emailAddress == 'Loading...' || _emailAddress == 'Not set') ? '' : _emailAddress,
    );
    String selectedDob = (_dateOfBirth == 'Loading...' || _dateOfBirth == 'Not set' || _dateOfBirth == 'Not provided')
        ? ''
        : _dateOfBirth;

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.editPersonalProfile,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // First Name & Last Name (Side by side)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            enabled: !isSaving,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              context: context,
                              label: AppLocalizations.of(context)!.firstName,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            enabled: !isSaving,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              context: context,
                              label: AppLocalizations.of(context)!.lastName,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Date of Birth Field
                    GestureDetector(
                      onTap: isSaving
                          ? null
                          : () async {
                              final initialDate = _parseDateOfBirth(selectedDob);
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(1920),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primaryGreen,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                final months = [
                                  'January', 'February', 'March', 'April', 'May', 'June',
                                  'July', 'August', 'September', 'October', 'November', 'December'
                                ];
                                setModalState(() {
                                  selectedDob = '${months[picked.month - 1]} ${picked.day}, ${picked.year}';
                                });
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.dateOfBirth,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (selectedDob.isEmpty || selectedDob == 'Loading...' || selectedDob == 'Not set' || selectedDob == 'Not provided')
                                        ? AppLocalizations.of(context)!.selectDateOfBirth
                                        : selectedDob,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: (selectedDob.isEmpty || selectedDob == 'Loading...' || selectedDob == 'Not set' || selectedDob == 'Not provided')
                                          ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                                          : Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Phone Number Field
                    TextField(
                      controller: phoneController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration(
                        context: context,
                        label: AppLocalizations.of(context)!.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryGreen, size: 20),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Email Address Field
                    TextField(
                      controller: emailController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        context: context,
                        label: AppLocalizations.of(context)!.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen, size: 20),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newFirstName = firstNameController.text.trim();
                                final newLastName = lastNameController.text.trim();
                                final newPhone = phoneController.text.trim();
                                final newEmail = emailController.text.trim();

                                if (newFirstName.isEmpty && newLastName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.firstNameRequired),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final newFullName = '$newFirstName $newLastName'.trim();
                                final effectiveDob = (selectedDob.isNotEmpty &&
                                        selectedDob != 'Loading...' &&
                                        selectedDob != 'Not set' &&
                                        selectedDob != 'Not provided')
                                    ? selectedDob
                                    : '';

                                final savedData = <String, dynamic>{
                                  'first_name': newFirstName,
                                  'last_name': newLastName,
                                  'full_name': newFullName,
                                  'name': newFullName,
                                  'phone_number': newPhone,
                                  'phone': newPhone,
                                  if (newEmail.isNotEmpty) 'email': newEmail,
                                  if (effectiveDob.isNotEmpty) 'date_of_birth': effectiveDob,
                                };

                                // 1. Immediately persist to dedicated cache (bulletproof)
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final existingRaw = prefs.getString('user_profile_custom_saved');
                                  final existingMap = existingRaw != null ? jsonDecode(existingRaw) as Map<String, dynamic> : <String, dynamic>{};
                                  existingMap.addAll(savedData);
                                  await prefs.setString('user_profile_custom_saved', jsonEncode(existingMap));
                                } catch (_) {}

                                // 2. Update local user data in auth service
                                try {
                                  await AuthService.updateLocalUserData(savedData);
                                } catch (_) {}

                                // 3. Immediately reflect in memory and UI on this screen
                                setState(() {
                                  _firstName = newFirstName;
                                  _lastName = newLastName;
                                  _fullName = newFullName;
                                  if (newPhone.isNotEmpty) _phoneNumber = newPhone;
                                  if (newEmail.isNotEmpty) _emailAddress = newEmail;
                                  if (effectiveDob.isNotEmpty) _dateOfBirth = effectiveDob;
                                });

                                // 4. Update backend profile
                                final payload = <String, dynamic>{
                                  'first_name': newFirstName,
                                  'last_name': newLastName,
                                  'phone_number': newPhone,
                                  if (newEmail.isNotEmpty) 'email': newEmail,
                                  if (effectiveDob.isNotEmpty) 'date_of_birth': effectiveDob,
                                  'profile': {
                                    'first_name': newFirstName,
                                    'last_name': newLastName,
                                    'phone_number': newPhone,
                                    if (newEmail.isNotEmpty) 'email': newEmail,
                                    if (effectiveDob.isNotEmpty) 'date_of_birth': effectiveDob,
                                  }
                                };

                                try {
                                  await AuthService.updateUserProfile(payload);
                                } catch (_) {}

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.profileUpdatedSuccess),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.saveChanges,
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
            );
          },
        );
      },
    ).then((_) {
      firstNameController.dispose();
      lastNameController.dispose();
      phoneController.dispose();
      emailController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildInnerPageAppBar(
        context,
        title: AppLocalizations.of(context)!.personalInformation,
        showLanguage: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar Section (Matching Screenshot)
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _showChangePhotoModal,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: _avatarOptions[_selectedAvatarIndex]['bgColor'] as Color,
                            backgroundImage: _avatarOptions[_selectedAvatarIndex]['isAsset'] == true
                                ? AssetImage(_avatarOptions[_selectedAvatarIndex]['assetPath'] as String)
                                : null,
                            child: _avatarOptions[_selectedAvatarIndex]['isAsset'] == true
                                ? null
                                : Icon(
                                    _avatarOptions[_selectedAvatarIndex]['icon'] as IconData,
                                    size: 54,
                                    color: _avatarOptions[_selectedAvatarIndex]['iconColor'] as Color,
                                  ),
                          ),
                        ),
                      ),

                      // Yellow Camera Badge Icon
                      GestureDetector(
                        onTap: _showChangePhotoModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow, // Yellow camera icon container
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Full Name
                  Text(
                    _fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),

                  if (_memberSince.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _memberSince,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Card 1: FULL NAME
            _buildInfoCard(
              icon: Icons.badge_outlined,
              label: AppLocalizations.of(context)!.fullName,
              value: _fullName,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 16),

            // Card 2: DATE OF BIRTH
            _buildInfoCard(
              icon: Icons.calendar_today_outlined,
              label: AppLocalizations.of(context)!.dateOfBirth,
              value: _dateOfBirth,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 16),

            // Card 3: PHONE NUMBER
            _buildInfoCard(
              icon: Icons.phone_outlined,
              label: AppLocalizations.of(context)!.phoneNumber,
              value: _phoneNumber,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 16),

            // Card 4: EMAIL ADDRESS
            _buildInfoCard(
              icon: Icons.mail_outline,
              label: AppLocalizations.of(context)!.emailAddress,
              value: _emailAddress,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 36),

            // Edit Profile Button (Matching Screenshot Pill Design)
            Center(
              child: SizedBox(
                width: 220,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showEditProfileModal,
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayValue = (value.isEmpty || value == 'Loading...') ? 'Not set' : value;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : AppColors.backgroundMintGray3,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
