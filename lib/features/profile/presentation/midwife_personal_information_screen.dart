import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

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
      // 1. Load basic user info from cached storage
      final localData = await AuthService.getUserData();
      if (mounted) {
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
        if (phone.isNotEmpty) _phoneNumber = phone;

        final fName = profile['first_name']?.toString() ??
            u['first_name']?.toString() ??
            localData['first_name']?.toString() ??
            '';
        final lName = profile['last_name']?.toString() ??
            u['last_name']?.toString() ??
            localData['last_name']?.toString() ??
            '';
        if (fName.isNotEmpty) _firstName = fName;
        if (lName.isNotEmpty) _lastName = lName;
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

        final b = profile['bio']?.toString() ?? u['bio']?.toString() ?? '';
        if (b.isNotEmpty) _bio = b;
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
          if (fName.isNotEmpty) _firstName = fName;
          if (lName.isNotEmpty) _lastName = lName;
          if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
            _fullName = '$_firstName $_lastName'.trim();
          }

          final phone = p['phone_number']?.toString() ??
              u['phone_number']?.toString() ??
              d['phone_number']?.toString() ??
              '';
          if (phone.isNotEmpty) _phoneNumber = phone;

          final email = d['email']?.toString() ?? u['email']?.toString() ?? '';
          if (email.isNotEmpty) _emailAddress = email;

          final b = p['bio']?.toString() ?? u['bio']?.toString() ?? '';
          if (b.isNotEmpty) _bio = b;
        }
      } catch (err) {
        AppLogger.d('MidwifePersonalInformationScreen: Error fetching /users/me/: $err');
      }

      // 3. Load professional profile details safely
      try {
        final p = await _repository.getMyProfile();
        if (mounted && p != null) {
          if (p.firstName.isNotEmpty) _firstName = p.firstName;
          if (p.lastName.isNotEmpty) _lastName = p.lastName;
          if (p.fullName.isNotEmpty) _fullName = p.fullName;
          if (p.specialty.isNotEmpty) _title = p.specialty;
          if (p.bio.isNotEmpty) _bio = p.bio;
          _experienceYears = p.experienceYears;
          if (p.email.isNotEmpty) _emailAddress = p.email;
        }
      } catch (err) {
        AppLogger.d('MidwifePersonalInformationScreen: Safe midwife profile fallback: $err');
      }
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
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // First Name & Last Name (Editable)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.firstName,
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: AppColors.primaryGreen, size: 20),
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: AppColors.mintLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryGreen, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.lastName,
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: AppColors.mintLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryGreen, width: 1.5),
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
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: AppColors.primaryGreen, size: 20),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppColors.mintLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title (Read only)
                    TextField(
                      controller: titleController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.professionalTitle,
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        suffixIcon:
                            const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Experience (Read only)
                    TextField(
                      controller: experienceController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.yearsOfExperience,
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        suffixIcon:
                            const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // About Me (Editable)
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.aboutMe,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppColors.mintLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGreen, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newFirstName = firstNameController.text.trim();
                          final newLastName = lastNameController.text.trim();
                          final newPhone = phoneController.text.trim();
                          final newTitle = titleController.text.trim();
                          final newBio = bioController.text.trim();
                          final exp =
                              int.tryParse(experienceController.text) ??
                                  _experienceYears;

                          if (newFirstName.isNotEmpty) {
                            final userPatch = <String, dynamic>{
                              'first_name': newFirstName,
                              'last_name': newLastName,
                              'phone_number': newPhone,
                              'profile': {
                                'first_name': newFirstName,
                                'last_name': newLastName,
                                'phone_number': newPhone,
                                'bio': newBio,
                              },
                            };

                            final midwifePatch = <String, dynamic>{
                              'title': newTitle,
                              'bio': newBio,
                              'experience_years': exp,
                              'first_name': newFirstName,
                              'last_name': newLastName,
                              'phone_number': newPhone,
                            };

                            try {
                              await Future.wait([
                                AuthService.updateUserProfile(userPatch),
                                AuthService.updateMidwifeProfile(midwifePatch),
                                _repository.updateMyProfile(midwifePatch),
                              ]);
                            } catch (_) {}

                            await AuthService.updateLocalUserData({
                              'first_name': newFirstName,
                              'last_name': newLastName,
                              'phone_number': newPhone,
                              'bio': newBio,
                              'profile': {
                                'first_name': newFirstName,
                                'last_name': newLastName,
                                'phone_number': newPhone,
                                'bio': newBio,
                              },
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {
                                _firstName = newFirstName;
                                _lastName = newLastName;
                                _fullName =
                                    '$newFirstName $newLastName'.trim();
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
                                          .profileUpdatedSuccess),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                              _loadProfileData();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.personalInformation,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                              Text(
                                _memberSince,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 2. Proportional Credentials Row (Title + Experience side-by-side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Specialty / Title (Proportional flex: 3)
                      Expanded(
                        flex: 3,
                        child: _buildCompactCredentialCard(
                          icon: Icons.medical_services_outlined,
                          label: AppLocalizations.of(context)!
                              .professionalTitle
                              .toUpperCase(),
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
                          label: AppLocalizations.of(context)!
                              .experience
                              .toUpperCase(),
                          value: '$_experienceYears',
                          isExperience: true,
                          onTap: _showEditProfileModal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Contact Information (Unified Grouped Card)
                  _buildSectionHeader(
                    title: 'CONTACT INFORMATION',
                    icon: Icons.contact_phone_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildContactCard(),

                  const SizedBox(height: 18),

                  // 4. About Me / Professional Biography (Dedicated Proportional Card)
                  _buildSectionHeader(
                    title: AppLocalizations.of(context)!.aboutMe.toUpperCase(),
                    icon: Icons.format_quote_rounded,
                    actionLabel: 'Edit',
                    onAction: _showEditProfileModal,
                  ),
                  const SizedBox(height: 8),
                  _buildAboutMeCard(),

                  const SizedBox(height: 32),

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
                        elevation: 2,
                        shadowColor:
                            AppColors.primaryGreen.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMintGray3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: Colors.grey,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                if (isExperience)
                  Text.rich(
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      children: [
                        TextSpan(
                          text: ' yrs exp',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
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
                      height: 1.2,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phone Tile
          InkWell(
            onTap: _showEditProfileModal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMintGray3,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .phoneNumber
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatPhoneNumber(_phoneNumber),
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
                    Icons.chevron_right,
                    color: Theme.of(context).dividerColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            indent: 58,
            endIndent: 16,
            color: isDark
                ? Colors.grey.shade800
                : Theme.of(context).dividerColor.withValues(alpha: 0.6),
          ),

          // Email Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMintGray3,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .emailAddress
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _emailAddress,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  color: Colors.grey,
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

    return GestureDetector(
      onTap: _showEditProfileModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                  color: AppColors.primaryGreen.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _bio,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle:
                          isPlaceholder ? FontStyle.italic : FontStyle.normal,
                      color: isPlaceholder
                          ? Colors.grey.shade500
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
                  Icon(Icons.add_circle_outline,
                      size: 14, color: AppColors.primaryGreen),
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
    );
  }
}
