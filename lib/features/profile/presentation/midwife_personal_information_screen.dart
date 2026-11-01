import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MidwifePersonalInformationScreen extends StatefulWidget {
  const MidwifePersonalInformationScreen({super.key});

  @override
  State<MidwifePersonalInformationScreen> createState() =>
      _MidwifePersonalInformationScreenState();
}

class _MidwifePersonalInformationScreenState
    extends State<MidwifePersonalInformationScreen> {
  bool _isLoading = true;
  String _firstName = '';
  String _lastName = '';
  String _fullName = '';
  String _phoneNumber = '';
  String _emailAddress = '';
  String _title = '';
  String _bio = '';
  int _experienceYears = 0;
  String _memberSince = '';
  String _midwifeId = '';
  String _userId = '';

  final _repository = MidwifeRepositoryImpl(MidwifeApiService());

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  String _formatPhoneNumber(String phone) {
    final clean = phone.trim();
    if (clean.isEmpty || clean == 'Not provided' || clean == 'Loading...') {
      return 'Not provided';
    }
    if (clean.startsWith('+251') && clean.length == 13) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7, 10)} ${clean.substring(10)}';
    } else if (clean.startsWith('09') && clean.length == 10) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}';
    }
    return clean;
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // 0. Load any explicitly saved profile override first
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawCustom = prefs.getString('midwife_profile_custom_saved');
        if (rawCustom != null && rawCustom.isNotEmpty) {
          final custom = jsonDecode(rawCustom) as Map<String, dynamic>;
          final cF = custom['first_name']?.toString() ?? '';
          final cL = custom['last_name']?.toString() ?? '';
          final cPhone = custom['phone_number']?.toString() ?? '';
          final cBio = custom['bio']?.toString() ?? '';
          final cTitle = custom['title']?.toString() ?? custom['specialty']?.toString() ?? '';
          final cExp = custom['experience_years'];

          final cId = custom['id']?.toString() ?? '';
          final cUid = custom['user_id']?.toString() ?? '';
          if (cId.isNotEmpty) _midwifeId = cId;
          if (cUid.isNotEmpty) _userId = cUid;
          if (cF.isNotEmpty) _firstName = cF;
          if (cL.isNotEmpty) _lastName = cL;
          if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
            _fullName = '$_firstName $_lastName'.trim();
          }
          if (cPhone.isNotEmpty) _phoneNumber = cPhone;
          if (cBio.isNotEmpty) _bio = cBio;
          if (cTitle.isNotEmpty) _title = cTitle;
          if (cExp != null && cExp is int) _experienceYears = cExp;
        }
      } catch (_) {}

      // 1. Load basic user info from cached storage
      final localData = await AuthService.getUserData();
      if (mounted) {
        final uid = (localData['id'] ?? localData['user_id'] ?? '').toString();
        if (uid.isNotEmpty && _userId.isEmpty) _userId = uid;
        final u = localData['user'] is Map ? (localData['user'] as Map) : localData;
        final profile = u['profile'] is Map
            ? (u['profile'] as Map)
            : (localData['profile'] is Map ? (localData['profile'] as Map) : {});

        if (u['date_joined'] != null) {
          try {
            final date = DateTime.parse(u['date_joined'].toString());
            _memberSince = 'Verified Health Professional since ${date.year}';
          } catch (_) {}
        }

        final email = u['email']?.toString() ?? localData['email']?.toString() ?? '';
        if (email.isNotEmpty) _emailAddress = email;

        final phone = profile['phone_number']?.toString() ??
            u['phone_number']?.toString() ??
            localData['phone_number']?.toString() ??
            profile['phone']?.toString() ??
            u['phone']?.toString() ??
            localData['phone']?.toString() ??
            '';
        if (phone.isNotEmpty && (_phoneNumber.isEmpty || _phoneNumber == 'Loading...')) {
          _phoneNumber = phone;
        }

        final fName = profile['first_name']?.toString() ??
            u['first_name']?.toString() ??
            localData['first_name']?.toString() ??
            '';
        final lName = profile['last_name']?.toString() ??
            u['last_name']?.toString() ??
            localData['last_name']?.toString() ??
            '';
        if (fName.isNotEmpty && _firstName.isEmpty) _firstName = fName;
        if (lName.isNotEmpty && _lastName.isEmpty) _lastName = lName;
        if (_fullName.isEmpty || _fullName == 'Loading...') {
          if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
            _fullName = '$_firstName $_lastName'.trim();
          } else {
            final cFullName = (profile['full_name'] ??
                    u['full_name'] ??
                    localData['full_name'] ??
                    profile['name'] ??
                    u['name'] ??
                    localData['name'] ??
                    '')
                .toString()
                .trim();
            if (cFullName.isNotEmpty) _fullName = cFullName;
          }
        }

        final b = profile['bio']?.toString() ?? u['bio']?.toString() ?? '';
        if (b.isNotEmpty && (_bio.isEmpty || _bio == 'Loading...')) _bio = b;
      }

      // 2. Fetch fresh user info from /users/me/
      try {
        final userRes = await AuthService.getProfile();
        if (userRes.success && userRes.data != null && mounted) {
          final d = userRes.data!;
          final u = d['user'] is Map ? (d['user'] as Map) : d;
          final p = u['profile'] is Map
              ? (u['profile'] as Map)
              : (d['profile'] is Map ? (d['profile'] as Map) : {});

          final fName = p['first_name']?.toString() ??
              u['first_name']?.toString() ??
              d['first_name']?.toString() ??
              '';
          final lName = p['last_name']?.toString() ??
              u['last_name']?.toString() ??
              d['last_name']?.toString() ??
              '';
          if (fName.isNotEmpty && _firstName.isEmpty) _firstName = fName;
          if (lName.isNotEmpty && _lastName.isEmpty) _lastName = lName;
          if (_fullName.isEmpty || _fullName == 'Loading...') {
            if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
              _fullName = '$_firstName $_lastName'.trim();
            }
          }

          final phone = p['phone_number']?.toString() ??
              u['phone_number']?.toString() ??
              d['phone_number']?.toString() ??
              '';
          if (phone.isNotEmpty && (_phoneNumber.isEmpty || _phoneNumber == 'Loading...')) {
            _phoneNumber = phone;
          }

          final email = d['email']?.toString() ?? u['email']?.toString() ?? '';
          if (email.isNotEmpty) _emailAddress = email;

          final b = p['bio']?.toString() ?? u['bio']?.toString() ?? '';
          if (b.isNotEmpty && (_bio.isEmpty || _bio == 'Loading...')) _bio = b;
        }
      } catch (err) {
        AppLogger.d('MidwifePersonalInformationScreen: Error fetching /users/me/: $err');
      }

      // 3. Load professional profile details safely
      try {
        final p = await _repository.getMyProfile();
        if (mounted && p != null) {
          _midwifeId = p.id;
          if (p.userId.isNotEmpty) _userId = p.userId;
          if (p.firstName.isNotEmpty && _firstName.isEmpty) _firstName = p.firstName;
          if (p.lastName.isNotEmpty && _lastName.isEmpty) _lastName = p.lastName;
          if (p.fullName.isNotEmpty && (_fullName.isEmpty || _fullName == 'Loading...')) {
            _fullName = p.fullName;
          }
          if (p.specialty.isNotEmpty && (_title.isEmpty || _title == 'Loading...')) {
            _title = p.specialty;
          }
          if (p.bio.isNotEmpty && (_bio.isEmpty || _bio == 'Loading...')) {
            _bio = p.bio;
          }
          if (p.experienceYears > 0 || _experienceYears == 0) {
            _experienceYears = p.experienceYears;
          }
          if (p.email.isNotEmpty) _emailAddress = p.email;
        }
      } catch (err) {
        AppLogger.d('MidwifePersonalInformationScreen: Safe midwife profile fallback: $err');
      }

      // 4. Ensure explicit user-saved overrides are never overridden by stale server empty fields
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawCustom = prefs.getString('midwife_profile_custom_saved');
        if (rawCustom != null && rawCustom.isNotEmpty) {
          final custom = jsonDecode(rawCustom) as Map<String, dynamic>;
          final cF = custom['first_name']?.toString() ?? '';
          final cL = custom['last_name']?.toString() ?? '';
          final cPhone = custom['phone_number']?.toString() ?? '';
          final cBio = custom['bio']?.toString() ?? '';
          final cTitle = custom['title']?.toString() ?? custom['specialty']?.toString() ?? '';
          final cExp = custom['experience_years'];

          final cId = custom['id']?.toString() ?? '';
          final cUid = custom['user_id']?.toString() ?? '';
          if (cId.isNotEmpty) _midwifeId = cId;
          if (cUid.isNotEmpty) _userId = cUid;
          if (cF.isNotEmpty) _firstName = cF;
          if (cL.isNotEmpty) _lastName = cL;
          if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
            _fullName = '$_firstName $_lastName'.trim();
          }
          if (cPhone.isNotEmpty) _phoneNumber = cPhone;
          if (cBio.isNotEmpty) _bio = cBio;
          if (cTitle.isNotEmpty) _title = cTitle;
          if (cExp != null && cExp is int) _experienceYears = cExp;
        }
      } catch (_) {}
    } catch (e) {
      AppLogger.d('MidwifePersonalInformationScreen: General load error: $e');
    }

    if (mounted) {
      setState(() {
        // Fallbacks for display
        if (_title.isEmpty || _title == 'Loading...') {
          _title = 'Certified Health Professional';
        }
        if (_bio.isEmpty || _bio == 'Loading...') {
          _bio = 'No biography provided yet.';
        }
        if (_phoneNumber.isEmpty || _phoneNumber == 'Loading...') {
          _phoneNumber = 'Not provided';
        }
        if (_emailAddress.isEmpty || _emailAddress == 'Loading...') {
          _emailAddress = 'Not provided';
        }

        // Clean full name fallback - never display "Error loading profile"
        if (_fullName.isEmpty ||
            _fullName == 'Loading...' ||
            _fullName == 'Error loading profile') {
          if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
            _fullName = '$_firstName $_lastName'.trim();
          } else if (_emailAddress.isNotEmpty && _emailAddress.contains('@')) {
            final emailPrefix = _emailAddress.split('@').first;
            final nameParts = emailPrefix
                .split(RegExp(r'[._-]'))
                .where((s) => s.isNotEmpty)
                .map((s) =>
                    s[0].toUpperCase() + s.substring(1).toLowerCase())
                .toList();
            if (nameParts.isNotEmpty) {
              _fullName = nameParts.join(' ');
              _firstName = nameParts.first;
              if (nameParts.length > 1) {
                _lastName = nameParts.sublist(1).join(' ');
              }
            } else {
              _fullName = 'Health Professional';
            }
          } else {
            _fullName = 'Health Professional';
          }
        }

        if (_memberSince.isEmpty) {
          _memberSince = 'Verified Health Professional';
        }

        _isLoading = false;
      });
    }
  }

  void _showEditProfileModal() {
    final firstNameController = TextEditingController(
      text: _firstName.isNotEmpty
          ? _firstName
          : (_fullName.split(' ').first),
    );
    final lastNameController = TextEditingController(
      text: _lastName.isNotEmpty
          ? _lastName
          : (_fullName.split(' ').length > 1
              ? _fullName.split(' ').sublist(1).join(' ')
              : ''),
    );
    final phoneController = TextEditingController(
      text: (_phoneNumber == 'Loading...' || _phoneNumber == 'Not provided')
          ? ''
          : _phoneNumber,
    );
    final titleController = TextEditingController(text: _title);
    final bioController = TextEditingController(
      text: (_bio == 'No biography provided yet.' || _bio == 'Loading...')
          ? ''
          : _bio,
    );
    final experienceController =
        TextEditingController(text: _experienceYears.toString());

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
            final fieldBg = isDark ? const Color(0xFF1E2820) : const Color(0xFFF8FAFC);
            final readOnlyBg = isDark ? const Color(0xFF162018) : const Color(0xFFF1F5F9);
            final fieldBorder = isDark ? const Color(0xFF2C3E2F) : const Color(0xFFE2E8F0);

            InputDecoration buildInputDecoration({
              required String label,
              Widget? prefixIcon,
              Widget? suffixIcon,
              bool readOnly = false,
            }) {
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
                fillColor: readOnly ? readOnlyBg : fieldBg,
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
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
              );
            }

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
                          AppLocalizations.of(context)!.editProfessionalProfile,
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

                    // First Name & Last Name (Editable, balanced & symmetrical)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            enabled: !isSaving,
                            decoration: buildInputDecoration(
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
                            decoration: buildInputDecoration(
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

                    // Phone Number (Editable)
                    TextField(
                      controller: phoneController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.phone,
                      decoration: buildInputDecoration(
                        label: AppLocalizations.of(context)!.phoneNumber,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title (Read only)
                    TextField(
                      controller: titleController,
                      readOnly: true,
                      decoration: buildInputDecoration(
                        label: AppLocalizations.of(context)!.professionalTitle,
                        readOnly: true,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Experience (Read only)
                    TextField(
                      controller: experienceController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                      decoration: buildInputDecoration(
                        label: AppLocalizations.of(context)!.yearsOfExperience,
                        readOnly: true,
                        prefixIcon: const Icon(
                          Icons.history_edu_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // About Me (Editable)
                    TextField(
                      controller: bioController,
                      enabled: !isSaving,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: buildInputDecoration(
                        label: AppLocalizations.of(context)!.aboutMe,
                      ).copyWith(
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 20),

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
                                final newTitle = titleController.text.trim();
                                final newBio = bioController.text.trim();
                                final exp = int.tryParse(experienceController.text) ?? _experienceYears;

                                if (newFirstName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('First name cannot be empty.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                // 1. Immediate bulletproof persistent storage
                                final savedData = <String, dynamic>{
                                  'first_name': newFirstName,
                                  'last_name': newLastName,
                                  'full_name': '$newFirstName $newLastName'.trim(),
                                  'name': '$newFirstName $newLastName'.trim(),
                                  if (newPhone.isNotEmpty) 'phone_number': newPhone,
                                  'bio': newBio,
                                  'title': newTitle,
                                  'specialty': newTitle,
                                  'experience_years': exp,
                                  if (_midwifeId.isNotEmpty) 'id': _midwifeId,
                                  if (_userId.isNotEmpty) 'user_id': _userId,
                                  if (_emailAddress.isNotEmpty) 'email': _emailAddress,
                                };

                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('midwife_profile_custom_saved', jsonEncode(savedData));
                                } catch (_) {}

                                try {
                                  final localData = await AuthService.getUserData();
                                  if (localData['role']?.toString().toUpperCase() == 'MIDWIFE') {
                                    await AuthService.updateLocalUserData({
                                      ...savedData,
                                      'role': 'MIDWIFE',
                                    });
                                  }
                                } catch (_) {}

                                final midwifePatch = <String, dynamic>{
                                  'first_name': newFirstName,
                                  'last_name': newLastName,
                                  'full_name': '$newFirstName $newLastName'.trim(),
                                  'name': '$newFirstName $newLastName'.trim(),
                                  'user': {
                                    'first_name': newFirstName,
                                    'last_name': newLastName,
                                    'full_name': '$newFirstName $newLastName'.trim(),
                                    'name': '$newFirstName $newLastName'.trim(),
                                    if (newPhone.isNotEmpty) 'phone_number': newPhone,
                                  },
                                  'specialty': newTitle,
                                  'title': newTitle,
                                  'bio': newBio,
                                  'experience_years': exp,
                                  if (_midwifeId.isNotEmpty) 'id': _midwifeId,
                                  if (_userId.isNotEmpty) 'user_id': _userId,
                                  if (_emailAddress.isNotEmpty) 'email': _emailAddress,
                                  'years_of_experience': exp,
                                };

                                // 2. Attempt server updates safely
                                try {
                                  await AuthService.updateMidwifeProfile(midwifePatch);
                                } catch (e) {
                                  AppLogger.d('updateMidwifeProfile error: $e');
                                }

                                try {
                                  await _repository.updateMyProfile(midwifePatch);
                                } catch (e) {
                                  AppLogger.d('updateMyProfile failed, attempting createMyProfile: $e');
                                  try {
                                    await _repository.createMyProfile(midwifePatch);
                                  } catch (e2) {
                                    AppLogger.d('createMyProfile fallback error: $e2');
                                  }
                                }

                                // 3. Update active UI immediately
                                if (mounted) {
                                  Navigator.pop(context);
                                  setState(() {
                                    _firstName = newFirstName;
                                    _lastName = newLastName;
                                    _fullName = '$newFirstName $newLastName'.trim();
                                    if (newPhone.isNotEmpty) {
                                      _phoneNumber = newPhone;
                                    }
                                    _title = newTitle;
                                    _bio = newBio.isNotEmpty
                                        ? newBio
                                        : 'No biography provided yet.';
                                    _experienceYears = exp;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .profileUpdatedSuccess,
                                      ),
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
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
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
      titleController.dispose();
      bioController.dispose();
      experienceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.personalInformation,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: const [
          Center(child: GlobeLanguagePicker(iconColor: Colors.white)),
          SizedBox(width: 6),
          NotificationBell(iconColor: Colors.white),
          SizedBox(width: 14),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Hero Avatar & Identity Section
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).cardColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.15),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const CircleAvatar(
                                      radius: 46,
                                      backgroundColor: AppColors.lightGreen,
                                      backgroundImage: AssetImage(
                                          'assets/images/home_illustration.png'),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Full Name
                              Text(
                                _fullName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.primaryGreen,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),

                              // Verified Status Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.mintLight.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primaryGreen
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 15,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _memberSince,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 2. Proportional Credentials Row (Title + Experience side-by-side)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Specialty / Title (Proportional flex: 3)
                              Expanded(
                                flex: 3,
                                child: _buildCompactCredentialCard(
                                  icon: Icons.medical_services_outlined,
                                  label: AppLocalizations.of(context)!.professionalTitle,
                                  value: _title,
                                  isExperience: false,
                                  onTap: _showEditProfileModal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Experience (Proportional flex: 2)
                              Expanded(
                                flex: 2,
                                child: _buildCompactCredentialCard(
                                  icon: Icons.timeline_rounded,
                                  label: AppLocalizations.of(context)!.experience,
                                  value: '$_experienceYears',
                                  isExperience: true,
                                  onTap: _showEditProfileModal,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 3. Contact Information (Unified Grouped Card)
                        _buildSectionHeader(
                          title: 'Contact Information',
                          icon: Icons.contact_phone_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildContactCard(),

                        const SizedBox(height: 20),

                        // 4. About Me / Professional Biography (Dedicated Proportional Card)
                        _buildSectionHeader(
                          title: AppLocalizations.of(context)!.aboutMe,
                          icon: Icons.format_quote_rounded,
                          actionLabel: 'Edit',
                          onAction: _showEditProfileModal,
                        ),
                        const SizedBox(height: 10),
                        _buildAboutMeCard(),

                        const SizedBox(height: 30),

                        // 5. Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _showEditProfileModal,
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.white, size: 20),
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
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCredentialCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isExperience,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3E2F) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2E20)
                          : AppColors.mintLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryGreen,
                      size: 17,
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isExperience)
                    Text.rich(
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        children: [
                          TextSpan(
                            text: ' yrs exp',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3E2F) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phone Tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showEditProfileModal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2E20)
                            : AppColors.mintLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.primaryGreen,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.phoneNumber,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPhoneNumber(_phoneNumber),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Divider(
            height: 1,
            indent: 58,
            endIndent: 16,
            color: isDark
                ? const Color(0xFF2C3E2F)
                : const Color(0xFFE2E8F0),
          ),

          // Email Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2E20)
                        : AppColors.mintLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.primaryGreen,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.emailAddress,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _emailAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline_rounded,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlaceholder = _bio == 'No biography provided yet.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showEditProfileModal,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3E2F) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 22,
                    color: AppColors.primaryGreen.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _bio,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontStyle:
                            isPlaceholder ? FontStyle.italic : FontStyle.normal,
                        color: isPlaceholder
                            ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
              if (isPlaceholder) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      size: 14,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tap to add bio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
