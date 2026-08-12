import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';

class MidwifeProfileScreen extends StatefulWidget {
  const MidwifeProfileScreen({super.key});

  @override
  State<MidwifeProfileScreen> createState() => _MidwifeProfileScreenState();
}

class _MidwifeProfileScreenState extends State<MidwifeProfileScreen> {

  bool isLoading = true;
  String? errorMessage;
  MidwifeProfile? profile;
  
  // Editable fields bound to the UI modal
  String name = '';
  String title = '';
  String status = 'PENDING';
  String bio = '';
  List<String> expertises = [];
  List<Map<String, String>> languages = [];
  List<Map<String, String>> qualifications = [];
  
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final p = await _repository.getMyProfile();
      if (mounted) {
        setState(() {
          profile = p;
          name = p.fullName;
          title = p.specialty;
          status = p.verificationStatus.toUpperCase() == 'APPROVED' ? 'VERIFIED' : 'PENDING';
          bio = p.bio;
          expertises = p.offeredConsultationTypes.isNotEmpty ? p.offeredConsultationTypes : [p.specialty];
          
          // Converting from List<String> to UI maps (mock format for now until full UI rewrite)
          languages = p.languages.map((l) => {'lang': l, 'level': 'Fluent'}).toList();
          if (languages.isEmpty) languages = [{'lang': 'English', 'level': 'Fluent'}];
          
          qualifications = [
            {'title': 'Certified Midwife', 'institution': 'National Board'}
          ];
          
          if (qualifications.isEmpty || qualifications.first['title']!.isEmpty) {
            qualifications = [
              {'title': 'Certified Midwife', 'institution': 'National Board'}
            ];
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load profile. Please check your connection and try again.\n\nDetails: $e';
        });
      }
    }
  }

  void _showEditModal() {
    final firstNameController = TextEditingController(text: profile?.firstName ?? name.split(' ').first);
    final lastNameController = TextEditingController(text: profile?.lastName ?? (name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : ''));
    final titleController = TextEditingController(text: title);
    final bioController = TextEditingController(text: bio);
    final newTagController = TextEditingController();

    final tempExpertises = List<String>.from(expertises);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
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
                          'Edit Profile Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF274E13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // First Name & Last Name Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: firstNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: lastNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text('Professional Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // About Me Bio
                    const Text('About Me (Bio)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell patients about your midwifery experience...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Expertise Tags
                    const Text('Expertise Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tempExpertises.map((exp) {
                        return Chip(
                          label: Text(exp, style: const TextStyle(fontSize: 12, color: Color(0xFF274E13))),
                          backgroundColor: const Color(0xFFE8F5E9),
                          deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                          onDeleted: () {
                            setModalState(() {
                              tempExpertises.remove(exp);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newTagController,
                            decoration: InputDecoration(
                              hintText: 'Add expertise (e.g. Postnatal Care)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF274E13), size: 32),
                          onPressed: () {
                            final tag = newTagController.text.trim();
                            if (tag.isNotEmpty) {
                              setModalState(() {
                                tempExpertises.add(tag);
                                newTagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newFirstName = firstNameController.text.trim();
                          final newLastName = lastNameController.text.trim();
                          final newTitle = titleController.text.trim();
                          final newBio = bioController.text.trim();

                          setState(() {
                            if (newFirstName.isNotEmpty) name = '$newFirstName $newLastName'.trim();
                            if (newTitle.isNotEmpty) title = newTitle;
                            if (newBio.isNotEmpty) bio = newBio;
                            expertises = tempExpertises;
                          });

                          await Future.wait([
                            AuthService.updateUserProfile({
                              'first_name': newFirstName,
                              'last_name': newLastName,
                              'profile': {
                                'first_name': newFirstName,
                                'last_name': newLastName,
                              },
                              'user': {
                                'first_name': newFirstName,
                                'last_name': newLastName,
                              }
                            }),
                            AuthService.updateMidwifeProfile({
                              'title': newTitle,
                              'bio': newBio,
                              'first_name': newFirstName,
                              'last_name': newLastName,
                              'user': {
                                'first_name': newFirstName,
                                'last_name': newLastName,
                              }
                            }),
                          ]);

                          if (mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: Color(0xFF274E13),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF274E13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
    final isVerified = status == 'APPROVED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          LanguageService.tr('profile'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const GlobeLanguagePicker(iconColor: Colors.amber),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF274E13)),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _loadProfile,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF274E13)),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: () async {
                                await AuthService.logout();
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const MidwifeLoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                children: [
                  // Top Profile Summary Card (Matching Screenshot input_file_0.png)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE8F5E9),
                                border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/home_illustration.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 64,
                                    color: Color(0xFF274E13),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'VERIFIED'
                                    ? const Color(0xFF5B4075) // Deep purple badge matching screenshot
                                    : Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status == 'VERIFIED'
                                        ? Icons.check_circle_rounded
                                        : Icons.hourglass_top,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'VERIFIED' ? 'Verified' : 'Pending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Edit Profile Button (Dark Green Pill Button matching screenshot)
                        SizedBox(
                          width: 170,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: _showEditModal,
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                            label: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF274E13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About Me Section (Purple Title & Purple Icon matching screenshot)
                  _buildCardSection(
                    icon: Icons.person_outline,
                    title: 'About Me',
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Expertise Section (Purple Title & Tags matching screenshot)
                  _buildCardSection(
                    icon: Icons.medical_services_outlined,
                    title: 'Expertise',
                    trailingIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B4075), // Purple floating icon badge matching screenshot
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expertises.map((exp) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5ED),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            exp,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF274E13),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Spoken Languages Section (Matching Screenshot)
                  _buildCardSection(
                    icon: Icons.translate,
                    title: 'Languages',
                    child: Column(
                      children: languages.map((langItem) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                langItem['lang']!,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEFEF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  langItem['level']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Qualifications Section (Matching Screenshot Purple Timeline Dots)
                  _buildCardSection(
                    icon: Icons.school_outlined,
                    title: 'Qualifications',
                    child: Column(
                      children: qualifications.map((q) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 5, right: 12),
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5B4075), // Purple dot matching screenshot
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q['title']!,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      q['institution']!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logout Button (Light Pink/Red Outlined Pill matching screenshot)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MidwifeLoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF0F0),
                        side: const BorderSide(color: Color(0xFFFFCDD2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Extra padding for floating nav bar
                ],
              ),
            ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailingIcon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF5B4075), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B4075),
                    ),
                  ),
                ],
              ),
              if (trailingIcon != null) trailingIcon,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
