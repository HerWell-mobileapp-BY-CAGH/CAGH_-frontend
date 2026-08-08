import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  String _fullName = 'Registered User';
  String _dateOfBirth = 'Not specified';
  String _phoneNumber = '+251911223344';
  String _emailAddress = 'user@cagh.org';
  final String _memberSince = 'Bloom Member since 2023';

  int _selectedAvatarIndex = 0;
  final List<Map<String, dynamic>> _avatarOptions = [
    {
      'label': 'Original Photo',
      'bgColor': const Color(0xFFE8F5E9),
      'iconColor': const Color(0xFF274E13),
      'icon': Icons.person,
      'isAsset': true,
      'assetPath': 'assets/images/home_illustration.png',
    },
    {
      'label': 'Warm Amber',
      'bgColor': const Color(0xFFFFF8E1),
      'iconColor': const Color(0xFFF57F17),
      'icon': Icons.face_rounded,
      'isAsset': false,
    },
    {
      'label': 'Ocean Blue',
      'bgColor': const Color(0xFFE1F5FE),
      'iconColor': const Color(0xFF0288D1),
      'icon': Icons.account_circle,
      'isAsset': false,
    },
    {
      'label': 'Royal Purple',
      'bgColor': const Color(0xFFF3E5F5),
      'iconColor': const Color(0xFF7B1FA2),
      'icon': Icons.face_retouching_natural,
      'isAsset': false,
    },
    {
      'label': 'Soft Coral',
      'bgColor': const Color(0xFFFFEBEE),
      'iconColor': const Color(0xFFC62828),
      'icon': Icons.person_pin,
      'isAsset': false,
    },
  ];

  void _showChangePhotoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                          color: Color(0xFF274E13),
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
                              const SnackBar(
                                content: Text('Camera photo captured and profile updated!'),
                                backgroundColor: Color(0xFF274E13),
                              ),
                            );
                          },
                          icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF274E13)),
                          label: const Text('Take Photo', style: TextStyle(color: Color(0xFF274E13), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF274E13)),
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
                              const SnackBar(
                                content: Text('Gallery photo uploaded successfully!'),
                                backgroundColor: Color(0xFF274E13),
                              ),
                            );
                          },
                          icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF274E13)),
                          label: const Text('From Gallery', style: TextStyle(color: Color(0xFF274E13), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF274E13)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'CHOOSE AVATAR STYLE',
                    style: TextStyle(
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
                                backgroundColor: const Color(0xFF274E13),
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
                                      color: isSelected ? const Color(0xFF274E13) : Colors.transparent,
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
                                    color: isSelected ? const Color(0xFF274E13) : Colors.black87,
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
        if (localData['full_name'] != null && localData['full_name'].toString().isNotEmpty) {
          _fullName = localData['full_name'].toString();
        }
        if (localData['email'] != null && localData['email'].toString().isNotEmpty) {
          _emailAddress = localData['email'].toString();
        }
        if (localData['phone_number'] != null && localData['phone_number'].toString().isNotEmpty) {
          _phoneNumber = localData['phone_number'].toString();
        }
      });
    }

    final res = await AuthService.getProfile();
    if (res.success && res.data != null && mounted) {
      final data = res.data!;
      setState(() {
        if (data['full_name'] != null && data['full_name'].toString().isNotEmpty) {
          _fullName = data['full_name'].toString();
        }
        if (data['email'] != null && data['email'].toString().isNotEmpty) {
          _emailAddress = data['email'].toString();
        }
        if (data['phone_number'] != null && data['phone_number'].toString().isNotEmpty) {
          _phoneNumber = data['phone_number'].toString();
        }
        if (data['date_of_birth'] != null && data['date_of_birth'].toString().isNotEmpty) {
          _dateOfBirth = data['date_of_birth'].toString();
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
      backgroundColor: Colors.white,
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
                        const Text(
                          'Edit Personal Profile',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF274E13),
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
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF274E13)),
                        filled: true,
                        fillColor: const Color(0xFFF9FBF7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF274E13), width: 1.5),
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
                                  primary: Color(0xFF274E13),
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
                          color: const Color(0xFFF9FBF7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: Color(0xFF274E13), size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedDob,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
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
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF274E13)),
                        filled: true,
                        fillColor: const Color(0xFFF9FBF7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF274E13), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Email Address Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF274E13)),
                        filled: true,
                        fillColor: const Color(0xFFF9FBF7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF274E13), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedName = nameController.text.trim();
                          final updatedPhone = phoneController.text.trim();
                          final updatedEmail = emailController.text.trim();

                          if (updatedName.isNotEmpty) {
                            setState(() {
                              _fullName = updatedName;
                              _phoneNumber = updatedPhone;
                              _emailAddress = updatedEmail;
                              _dateOfBirth = selectedDob;
                            });

                            AuthService.updateUserProfile({
                              'full_name': updatedName,
                              'phone_number': updatedPhone,
                              'email': updatedEmail,
                              'date_of_birth': selectedDob,
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Personal profile updated successfully!'),
                                backgroundColor: Color(0xFF274E13),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF274E13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                            color: const Color(0xFFFFC107), // Yellow camera icon container
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
                      color: Color(0xFF274E13),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle Member since
                  Text(
                    _memberSince,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Card 1: FULL NAME
            _buildInfoCard(
              icon: Icons.badge_outlined,
              label: 'FULL NAME',
              value: _fullName,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 16),

            // Card 2: DATE OF BIRTH
            _buildInfoCard(
              icon: Icons.calendar_today_outlined,
              label: 'DATE OF BIRTH',
              value: _dateOfBirth,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 16),

            // Card 3: PHONE NUMBER
            _buildInfoCard(
              icon: Icons.phone_outlined,
              label: 'PHONE NUMBER',
              value: _phoneNumber,
              onTap: _showEditProfileModal,
            ),

            const SizedBox(height: 16),

            // Card 4: EMAIL ADDRESS
            _buildInfoCard(
              icon: Icons.mail_outline,
              label: 'EMAIL ADDRESS',
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
                    backgroundColor: const Color(0xFF274E13),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
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
                color: const Color(0xFFF1F6EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF274E13),
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
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
