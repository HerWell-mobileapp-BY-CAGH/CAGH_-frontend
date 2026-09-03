import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class MidwifePersonalInformationScreen extends StatefulWidget {
  const MidwifePersonalInformationScreen({super.key});

  @override
  State<MidwifePersonalInformationScreen> createState() => _MidwifePersonalInformationScreenState();
}

class _MidwifePersonalInformationScreenState extends State<MidwifePersonalInformationScreen> {
  bool _isLoading = true;
  String _fullName = 'Loading...';
  String _phoneNumber = 'Loading...';
  String _emailAddress = 'Loading...';
  String _title = 'Loading...';
  String _bio = 'Loading...';
  int _experienceYears = 0;
  String _memberSince = '';
  
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());
  
  // Reuse the avatar logic from user side
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
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // First try to load basic user info to get email/phone/member since
      final localData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          final u = localData['user'] is Map ? localData['user'] : localData;
          if (u['date_joined'] != null) {
            try {
              final date = DateTime.parse(u['date_joined'].toString());
              _memberSince = 'Verified Midwife since ${date.year}';
            } catch (_) {}
          }
          final email = u['email']?.toString() ?? localData['email']?.toString() ?? '';
          if (email.isNotEmpty) _emailAddress = email;
          
          final phone = u['phone_number']?.toString() ?? localData['phone_number']?.toString() ?? '';
          if (phone.isNotEmpty) _phoneNumber = phone;
        });
      }

      // Then load Midwife specific profile
      final p = await _repository.getMyProfile();
      if (mounted) {
        setState(() {
          if (p != null) {
            _fullName = p.fullName;
            _title = p.specialty;
            if (_title.isEmpty) _title = AppLocalizations.of(context)!.certifiedMidwife;
            _bio = p.bio;
            if (_bio.isEmpty) _bio = 'No biography provided yet.';
            _experienceYears = p.experienceYears;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fullName = 'Error loading profile';
        });
      }
    }
  }

  void _showEditProfileModal() {
    final firstNameController = TextEditingController(text: _fullName.split(' ').first);
    final lastNameController = TextEditingController(text: _fullName.split(' ').length > 1 ? _fullName.split(' ').sublist(1).join(' ') : '');
    final titleController = TextEditingController(text: _title);
    final bioController = TextEditingController(text: _bio == 'No biography provided yet.' ? '' : _bio);
    final experienceController = TextEditingController(text: _experienceYears.toString());

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

                    // First Name & Last Name
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.firstName,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.professionalTitle,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    SizedBox(height: 14),

                    // Experience
                    TextField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.yearsOfExperience,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // About Me
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.aboutUs,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                          final newTitle = titleController.text.trim();
                          final newBio = bioController.text.trim();
                          final exp = int.tryParse(experienceController.text) ?? _experienceYears;

                          if (newFirstName.isNotEmpty) {
                            await Future.wait([
                              AuthService.updateUserProfile({
                                'first_name': newFirstName,
                                'last_name': newLastName,
                              }),
                              AuthService.updateMidwifeProfile({
                                'title': newTitle,
                                'bio': newBio,
                                'experience_years': exp,
                                'first_name': newFirstName,
                                'last_name': newLastName,
                              }),
                            ]);

                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {
                                _fullName = '$newFirstName $newLastName'.trim();
                                _title = newTitle;
                                _bio = newBio;
                                _experienceYears = exp;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.profileUpdatedSuccess),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                              _loadProfileData(); // refresh
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
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.lightGreen,
                      backgroundImage: AssetImage('assets/images/home_illustration.png'),
                    ),
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
            SizedBox(height: 16),

            // Card 2: TITLE
            _buildInfoCard(
              icon: Icons.work_outline,
              label: AppLocalizations.of(context)!.professionalTitle,
              value: _title,
              onTap: _showEditProfileModal,
            ),
            SizedBox(height: 16),

            // Card 3: EXPERIENCE
            _buildInfoCard(
              icon: Icons.timeline,
              label: AppLocalizations.of(context)!.experience,
              value: '$_experienceYears Years',
              onTap: _showEditProfileModal,
            ),
            const SizedBox(height: 16),

            // Card 4: PHONE
            _buildInfoCard(
              icon: Icons.phone_outlined,
              label: AppLocalizations.of(context)!.phoneNumber,
              value: _phoneNumber,
              onTap: _showEditProfileModal,
            ),
            const SizedBox(height: 16),

            // Card 5: EMAIL
            _buildInfoCard(
              icon: Icons.mail_outline,
              label: AppLocalizations.of(context)!.emailAddress,
              value: _emailAddress,
              onTap: _showEditProfileModal,
            ),
            SizedBox(height: 16),
            
            // Card 6: BIO
            _buildInfoCard(
              icon: Icons.person_outline,
              label: AppLocalizations.of(context)!.aboutMe,
              value: _bio,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 36),

            // Edit Profile Button
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),
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
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Theme.of(context).dividerColor, size: 20),
          ],
        ),
      ),
    );
  }
}
