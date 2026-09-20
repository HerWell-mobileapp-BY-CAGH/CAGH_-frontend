import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/onboarding/presentation/user_type_selection_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_personal_information_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_notification_settings_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/appearance_accessibility_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_inbox_screen.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cagh_frontend/shared/widgets/app_profile_avatar.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class MidwifeProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackTap;
  final bool showAppBar;
  const MidwifeProfileScreen({super.key, this.onBackTap, this.showAppBar = false});

  @override
  ConsumerState<MidwifeProfileScreen> createState() => _MidwifeProfileScreenState();
}

class _MidwifeProfileScreenState extends ConsumerState<MidwifeProfileScreen> {
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
      appBar: widget.showAppBar ? AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: widget.onBackTap != null,
        leading: widget.onBackTap != null ? IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: widget.onBackTap,
        ) : null,
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ) : null,
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
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 18,
                                    color: Color(0xFF385A2E),
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
                  _buildSectionHeader(AppLocalizations.of(context)!.accountAndRecords),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: AppLocalizations.of(context)!.personalInformation,
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
                      badge: ref.watch(notificationProvider).unreadMessagesCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                ref.watch(notificationProvider).unreadMessagesCount.toString(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MidwifeInboxScreen()),
                        ).then((_) {
                          ref.read(notificationProvider.notifier).refreshNotifications();
                        });
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 2. Settings
                  _buildSectionHeader(AppLocalizations.of(context)!.settings),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.palette_outlined,
                      title: AppLocalizations.of(context)!.appearanceAccessibility,
                      subtitle: AppLocalizations.of(context)!.themeAndTextSize,
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
                      title: AppLocalizations.of(context)!.languageSettings,
                      subtitle: activeLang,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: LanguageService.currentLanguage.value,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF2E5E2A)),
                            style: const TextStyle(
                              color: Color(0xFF2E5E2A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'am', child: Text('አማርኛ')),
                              DropdownMenuItem(value: 'om', child: Text('Afaan Oromoo')),
                              DropdownMenuItem(value: 'so', child: Text('Somali')),
                            ],
                            onChanged: (lang) async {
                              if (lang != null) {
                                await LanguageService.setLanguage(lang);
                                if (mounted) setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.notifications_none_rounded,
                      title: AppLocalizations.of(context)!.notifications,
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
                      title: AppLocalizations.of(context)!.privacySecurity,
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),



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
                      label: Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(
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
                    AppLocalizations.of(context)!.appVersion('2.4.1', '890'),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?badge,
              if (badge != null) const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Theme.of(context).dividerColor, size: 22),
            ],
          ),
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
