import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/core/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';

class MidwifeProfileScreen extends StatefulWidget {
  const MidwifeProfileScreen({super.key});

  @override
  State<MidwifeProfileScreen> createState() => _MidwifeProfileScreenState();
}

class _MidwifeProfileScreenState extends State<MidwifeProfileScreen> {
  bool isLoading = true;
  String name = 'Nurse Midwife';
  String title = 'Senior Nurse Midwife (MSc, RM)';
  String status = 'APPROVED';
  String bio =
      'Dedicated midwife with over 12 years of experience in facilitating natural births and providing comprehensive antenatal and postnatal care. My philosophy is rooted in empowering families through education and personalized support, ensuring a safe and positive transition into parenthood.';
  List<String> expertises = [
    'Antenatal Care',
    'Breastfeeding Support',
    'Neonatal Care',
    'Water Birth'
  ];
  List<Map<String, String>> languages = [
    {'lang': 'English', 'level': 'Native'},
    {'lang': 'Spanish', 'level': 'Fluent'},
  ];
  List<Map<String, String>> qualifications = [
    {
      'title': 'MSc in Advanced Midwifery',
      'institution': 'University of Health Sciences, 2018'
    },
    {
      'title': 'Registered Midwife Certification',
      'institution': 'National Board of Nursing, 2012'
    },
    {
      'title': 'BSc in Nursing Science',
      'institution': 'State Medical College, 2011'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final localData = await AuthService.getUserData();
      if (localData['full_name'] != null && localData['full_name'].toString().isNotEmpty && mounted) {
        setState(() {
          name = localData['full_name'].toString();
        });
      }

      final res = await AuthService.getMidwifeProfile();
      if (res.success && res.data != null && mounted) {
        final d = res.data!;
        final u = d['user'] ?? {};

        setState(() {
          if (u['full_name'] != null && u['full_name'].toString().isNotEmpty) {
            name = u['full_name'].toString();
          } else if (u['email'] != null) {
            name = u['email'].toString();
          }

          if (d['verification_status'] != null) {
            status = d['verification_status'].toString();
          }

          if (d['bio'] != null && d['bio'].toString().isNotEmpty) {
            bio = d['bio'].toString();
          }

          if (d['title'] != null && d['title'].toString().isNotEmpty) {
            title = d['title'].toString();
          } else if (d['experience_years'] != null) {
            title = 'Senior Nurse Midwife (${d['experience_years']} Years Exp)';
          }

          if (d['qualifications'] != null && d['qualifications'] is List) {
            final list = d['qualifications'] as List;
            if (list.isNotEmpty) {
              qualifications = list.map((q) {
                return {
                  'title': q['title']?.toString() ?? 'Midwifery Qualification',
                  'institution':
                      '${q['institution'] ?? ''}, ${q['year_obtained'] ?? ''}'
                          .trim(),
                };
              }).toList();
            }
          }

          if (d['expertises'] != null && d['expertises'] is List) {
            final exList = d['expertises'] as List;
            if (exList.isNotEmpty) {
              expertises = exList.map((e) => e['name'].toString()).toList();
            }
          }
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showEditModal() {
    final nameController = TextEditingController(text: name);
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

                    // Full Name
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
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
                          final newName = nameController.text.trim();
                          final newTitle = titleController.text.trim();
                          final newBio = bioController.text.trim();

                          setState(() {
                            if (newName.isNotEmpty) name = newName;
                            if (newTitle.isNotEmpty) title = newTitle;
                            if (newBio.isNotEmpty) bio = newBio;
                            expertises = tempExpertises;
                          });

                          await AuthService.updateMidwifeProfile({
                            'full_name': newName,
                            'title': newTitle,
                            'bio': newBio,
                          });

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
                                color: isVerified
                                    ? const Color(0xFF5B4075) // Deep purple badge matching screenshot
                                    : Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified
                                        ? Icons.check_circle_rounded
                                        : Icons.hourglass_top,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isVerified ? 'Verified' : 'Pending',
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

                  const SizedBox(height: 30),
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
