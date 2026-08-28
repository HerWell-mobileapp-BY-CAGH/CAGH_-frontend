import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_constants.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/personal_information_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/appearance_accessibility_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class UserProfileScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  const UserProfileScreen({super.key, this.onBackTap});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isLoading = true;
  bool notificationsEnabled = true;
  String fullName = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final localData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          final u = localData['user'] is Map ? localData['user'] : localData;
          final p = u['profile'] is Map ? u['profile'] : (localData['profile'] is Map ? localData['profile'] : {});
          
          final fName = p['first_name']?.toString() ?? u['first_name']?.toString() ?? localData['first_name']?.toString() ?? '';
          final lName = p['last_name']?.toString() ?? u['last_name']?.toString() ?? localData['last_name']?.toString() ?? '';
          final cFullName = p['full_name']?.toString() ?? u['full_name']?.toString() ?? localData['full_name']?.toString() ?? '';
          
          if (cFullName.isNotEmpty) {
            fullName = cFullName;
          } else if (fName.isNotEmpty || lName.isNotEmpty) {
            fullName = '$fName $lName'.trim();
          }
          if (localData['email'] != null && localData['email'].toString().isNotEmpty) {
            email = localData['email'].toString();
          } else if (localData['phone_number'] != null && localData['phone_number'].toString().isNotEmpty) {
            email = localData['phone_number'].toString();
          }
        });
      }

      final res = await AuthService.getProfile();
      if (res.success && res.data != null && mounted) {
        final d = res.data!;
        setState(() {
          final u = d['user'] is Map ? d['user'] : d;
          final p = u['profile'] is Map ? u['profile'] : (d['profile'] is Map ? d['profile'] : {});
          
          final fName = p['first_name']?.toString() ?? u['first_name']?.toString() ?? d['first_name']?.toString() ?? '';
          final lName = p['last_name']?.toString() ?? u['last_name']?.toString() ?? d['last_name']?.toString() ?? '';
          final cFullName = p['full_name']?.toString() ?? u['full_name']?.toString() ?? d['full_name']?.toString() ?? '';
          
          if (cFullName.isNotEmpty) {
            fullName = cFullName;
          } else if (fName.isNotEmpty || lName.isNotEmpty) {
            fullName = '$fName $lName'.trim();
          }
          if (d['email'] != null && d['email'].toString().isNotEmpty) {
            email = d['email'].toString();
          } else if (d['phone_number'] != null) {
            email = d['phone_number'].toString();
          }
        });
      }
    } catch (e) {
      AppLogger.d('UserProfileScreen: Error parsing profile data: $e');
    }
    if (mounted) {
      setState(() {
         isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = LanguageService.currentLanguage.value == 'am'
        ? 'Amharic (አማርኛ)'
        : 'English (US)';

    return Scaffold(
      backgroundColor: AppColors.backgroundWarmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accentYellow),
          onPressed: () {
            if (widget.onBackTap != null) {
              widget.onBackTap!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          fullName.isNotEmpty ? fullName : LanguageService.tr(context, 'profile'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // User Avatar Header
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PersonalInformationScreen(),
                              ),
                            ).then((_) => _fetchProfile());
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentYellow,
                                ),
                                child: const CircleAvatar(
                                  radius: 42,
                                  backgroundColor: AppColors.lightGreen,
                                  backgroundImage: NetworkImage(AppConstants.placeholderAvatarUrl),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Account & Records
                  _buildSectionHeader('Account & Records'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalInformationScreen(),
                          ),
                        ).then((_) => _fetchProfile());
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.assignment_outlined,
                      title: 'Medical Records',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Appointments',
                      badge: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '1 UPCOMING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'Consultation History',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Saved Midwives',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 2. Settings
                  _buildSectionHeader('Settings'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.palette_outlined,
                      title: 'Appearance & Accessibility',
                      subtitle: 'Theme and text size',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppearanceAccessibilityScreen(),
                          ),
                        ).then((_) {
                          // In case we want to fetch profile or update UI on return
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: activeLang,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.mint),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: LanguageService.currentLanguage.value,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryGreen, size: 20),
                            borderRadius: BorderRadius.circular(12),
                            items: LanguageService.supportedLanguages.map((lang) {
                              return DropdownMenuItem<String>(
                                value: lang.code,
                                child: Text(
                                  '${lang.flag} ${lang.nativeName}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? code) async {
                              if (code != null) {
                                await LanguageService.setLanguage(code);
                                if (mounted) setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      trailing: Switch(
                        value: notificationsEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setState(() => notificationsEnabled = val);
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.contact_phone_outlined,
                      title: 'Emergency Contacts',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 3. Support
                  _buildSectionHeader('Support'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserLoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderRedSoft, width: 1.5),
                        backgroundColor: AppColors.backgroundPinkWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Version 2.4.1 (Build 890)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? badge,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppColors.primaryGreen, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textNearBlackAlt,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[badge, const SizedBox(width: 8)],
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
            ],
          ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }
}
