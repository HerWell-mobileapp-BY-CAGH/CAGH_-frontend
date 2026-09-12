import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  String _fullName = 'Loading...';
  String _dateOfBirth = 'Loading...';
  String _phoneNumber = 'Loading...';
  String _emailAddress = 'Loading...';
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedAvatarIndex = 1;
                            });
                            AuthService.updateUserProfile({'avatar_index': 1});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.cameraPhotoUpdated),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedAvatarIndex = 2;
                            });
                            AuthService.updateUserProfile({'avatar_index': 2});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.galleryPhotoUpdated),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
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
                      letterSpacing: 0.8,
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
                          onTap: () {
                            setModalState(() {
                              _selectedAvatarIndex = index;
                            });
                            setState(() {
                              _selectedAvatarIndex = index;
                            });
                            AuthService.updateUserProfile({'avatar_index': index});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Profile photo updated to ${item['label']}!'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
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

  Future<void> _loadUserData() async {
    final localData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        final u = localData['user'] is Map ? localData['user'] : localData;
        final profile = u['profile'] is Map ? u['profile'] : (localData['profile'] is Map ? localData['profile'] : {});
        
        if (u['date_joined'] != null) {
          try {
            final date = DateTime.parse(u['date_joined'].toString());
            _memberSince = 'Bloom Member since ${date.year}';
          } catch (_) {}
        }
        
        final fName = profile['first_name']?.toString() ?? u['first_name']?.toString() ?? localData['first_name']?.toString() ?? '';
        final lName = profile['last_name']?.toString() ?? u['last_name']?.toString() ?? localData['last_name']?.toString() ?? '';
        final cFullName = profile['full_name']?.toString() ?? u['full_name']?.toString() ?? localData['full_name']?.toString() ?? '';
        final name = profile['name']?.toString() ?? u['name']?.toString() ?? localData['name']?.toString() ?? '';

        if (cFullName.isNotEmpty) {
          _fullName = cFullName;
        } else if (name.isNotEmpty) {
          _fullName = name;
        } else if (fName.isNotEmpty || lName.isNotEmpty) {
          _fullName = '$fName $lName'.trim();
        }

        final email = profile['email']?.toString() ?? u['email']?.toString() ?? localData['email']?.toString() ?? '';
        if (email.isNotEmpty) {
          _emailAddress = email;
        }
        
        final phone = profile['phone_number']?.toString() ?? u['phone_number']?.toString() ?? localData['phone_number']?.toString() ?? profile['phone']?.toString() ?? u['phone']?.toString() ?? localData['phone']?.toString() ?? '';
        if (phone.isNotEmpty) {
          _phoneNumber = phone;
        }
        
        final dob = profile['date_of_birth']?.toString() ?? u['date_of_birth']?.toString() ?? localData['date_of_birth']?.toString() ?? profile['dob']?.toString() ?? u['dob']?.toString() ?? localData['dob']?.toString() ?? '';
        if (dob.isNotEmpty) {
          _dateOfBirth = dob;
        }
      });
    }

    final res = await AuthService.getProfile();
    if (res.success && res.data != null && mounted) {
      final data = res.data!;
      setState(() {
        final u = data['user'] is Map ? data['user'] : data;
        final profile = u['profile'] is Map ? u['profile'] : (data['profile'] is Map ? data['profile'] : {});

        final fName = profile['first_name']?.toString() ?? u['first_name']?.toString() ?? data['first_name']?.toString() ?? '';
        final lName = profile['last_name']?.toString() ?? u['last_name']?.toString() ?? data['last_name']?.toString() ?? '';
        final cFullName = profile['full_name']?.toString() ?? u['full_name']?.toString() ?? data['full_name']?.toString() ?? '';
        final name = profile['name']?.toString() ?? u['name']?.toString() ?? data['name']?.toString() ?? '';

        if (cFullName.isNotEmpty) {
          _fullName = cFullName;
        } else if (name.isNotEmpty) {
          _fullName = name;
        } else if (fName.isNotEmpty || lName.isNotEmpty) {
          _fullName = '$fName $lName'.trim();
        }

        final email = profile['email']?.toString() ?? u['email']?.toString() ?? data['email']?.toString() ?? '';
        if (email.isNotEmpty) {
          _emailAddress = email;
        }

        final phone = profile['phone_number']?.toString() ?? u['phone_number']?.toString() ?? data['phone_number']?.toString() ?? profile['phone']?.toString() ?? u['phone']?.toString() ?? data['phone']?.toString() ?? '';
        if (phone.isNotEmpty) {
          _phoneNumber = phone;
        }
        
        final dob = profile['date_of_birth']?.toString() ?? u['date_of_birth']?.toString() ?? data['date_of_birth']?.toString() ?? profile['dob']?.toString() ?? u['dob']?.toString() ?? data['dob']?.toString() ?? '';
        if (dob.isNotEmpty) {
          _dateOfBirth = dob;
        } else if (_dateOfBirth == 'Loading...') {
          _dateOfBirth = 'Not provided';
        }
        if (u['date_joined'] != null) {
          try {
            final date = DateTime.parse(u['date_joined'].toString());
            _memberSince = 'Bloom Member since ${date.year}';
          } catch (_) {}
        }
      });
    }
  }

  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(text: _phoneNumber);
    final emailController = TextEditingController(text: _emailAddress);
    String selectedDob = _dateOfBirth;

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
                          AppLocalizations.of(context)!.editPersonalProfile,
                          style: TextStyle(
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

                    // Full Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fullName,
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primaryGreen),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.mintLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.mintLight),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date of Birth Field
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2008, 3, 12),
                          firstDate: DateTime(1950),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade800 
                              : AppColors.backgroundSoftMintAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth',
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedDob,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Phone Number Field
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryGreen),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.mintLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.mintLight),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Email Address Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
                        suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.mintLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.mintLight),
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
                          final updatedName = nameController.text.trim();
                          final updatedPhone = phoneController.text.trim();
                          final updatedEmail = emailController.text.trim();

                          if (updatedName.isNotEmpty) {
                            final nameParts = updatedName.trim().split(' ');
                            final firstName = nameParts.first;
                            final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

                            final res = await AuthService.updateUserProfile({
                              'phone_number': updatedPhone,
                              'profile': {
                                'first_name': firstName,
                                'last_name': lastName,
                                'date_of_birth': selectedDob,
                              }
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              if (res.success) {
                                setState(() {
                                  _fullName = updatedName;
                                  _phoneNumber = updatedPhone;
                                  _dateOfBirth = selectedDob;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.profileUpdatedSuccess),
                                    backgroundColor: AppColors.primaryGreen,
                                  ),
                                );
                                _loadUserData(); // refresh to get true source
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.message ?? AppLocalizations.of(context)!.failedToUpdateStatus),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildInnerPageAppBar(
        context,
        title: AppLocalizations.of(context)!.personalInformation,
        showLanguage: false,
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
                color: AppColors.backgroundMintGray3,
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
                      letterSpacing: 0.8,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_memberSince.isNotEmpty)
                    Text(
                      _memberSince,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
