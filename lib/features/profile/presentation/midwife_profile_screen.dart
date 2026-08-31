import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/constants/app_constants.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/features/onboarding/presentation/user_type_selection_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_personal_information_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_notification_settings_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/appearance_accessibility_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_inbox_screen.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/widgets/app_profile_avatar.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class MidwifeProfileScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  const MidwifeProfileScreen({super.key, this.onBackTap});

  @override
  State<MidwifeProfileScreen> createState() => _MidwifeProfileScreenState();
}

class _MidwifeProfileScreenState extends State<MidwifeProfileScreen> {
  bool isLoading = true;
  String fullName = '';
  String email = '';
  String status = 'PENDING';
  String title = 'Certified Midwife';
  
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());

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
          if (fName.isNotEmpty || lName.isNotEmpty) {
            fullName = '$fName $lName'.trim();
          }
          final emailVal = localData['email']?.toString() ?? u['email']?.toString() ?? '';
          if (emailVal.isNotEmpty) {
            email = emailVal;
          } else {
            final phone = localData['phone_number']?.toString() ?? u['phone_number']?.toString() ?? '';
            if (phone.isNotEmpty) email = phone;
          }
        });
      }

      final p = await _repository.getMyProfile();
      if (mounted) {
        setState(() {
          if (p != null) {
            if (p.fullName.isNotEmpty) fullName = p.fullName;
            if (p.specialty.isNotEmpty) title = p.specialty;
            status = p.verificationStatus.toUpperCase() == 'APPROVED' ? 'VERIFIED' : 'PENDING';
          }
        });
      }
    } catch (e) {
      AppLogger.d('MidwifeProfileScreen: Error parsing profile data: $e');
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
    final isVerified = status == 'VERIFIED';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: widget.onBackTap != null,
        leading: widget.onBackTap != null ? IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.accentYellow),
          onPressed: () {
            if (widget.onBackTap != null) {
              widget.onBackTap!();
            }
          },
        ) : null,
        title: Text(
          fullName.isNotEmpty ? fullName : AppLocalizations.of(context)!.profile,
          style: const TextStyle(
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
                  // Avatar Header
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MidwifePersonalInformationScreen(),
                              ),
                            ).then((_) => _fetchProfile());
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isVerified ? AppColors.accentPurpleStrong : Colors.orange,
                                ),
                                child: const AppProfileAvatar(
                                  radius: 42,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isVerified ? AppColors.accentPurpleStrong : Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  isVerified ? Icons.verified : Icons.hourglass_top,
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: 140,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MidwifePersonalInformationScreen(),
                                ),
                              ).then((_) => _fetchProfile());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
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
                            builder: (context) => MidwifePersonalInformationScreen(),
                          ),
                        ).then((_) => _fetchProfile());
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.chat_bubble_outline,
                      title: AppLocalizations.of(context)!.myMessages,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MidwifeInboxScreen()),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 2. Settings
                  _buildSectionHeader('Settings'),
                  SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.palette_outlined,
                      title: AppLocalizations.of(context)!.appearanceAccessibility,
                      subtitle: 'Theme and text size',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppearanceAccessibilityScreen(),
                          ),
                        ).then((_) {
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MidwifeNotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 3. Support & Info
                  _buildSectionHeader('App Information'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.policy_outlined,
                      title: 'Privacy Policy',
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
                              builder: (context) => const UserTypeSelectionScreen(),
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

                  const SizedBox(height: 100), // Spacing for floating navbar
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppColors.primaryGreen, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            )
          : null,
      trailing: trailing ??
          Icon(Icons.chevron_right, color: Theme.of(context).dividerColor, size: 22),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 16,
      endIndent: 16,
    );
  }
}
