import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/find_midwife_screen.dart';
import 'package:cagh_frontend/features/nearby/presentation/screens/nearby_healthcare_screen.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/user_profile_screen.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/shared/widgets/ai_assistant_fab.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:cagh_frontend/shared/widgets/hotline_fab.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/features/learning/presentation/screens/learning_center_screen.dart';
import 'package:cagh_frontend/features/appointments/presentation/screens/my_appointments_screen.dart';
import 'package:cagh_frontend/features/hotline/presentation/emergency_support_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Left empty since _userProfile is no longer used, but kept for future use.
  }

  // Replaced by NotificationsScreen

// Review modal has been moved to user_chat_room_screen.dart
  Widget _buildFloatingButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // Padding to avoid bottom nav bar
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const HotlineFab(),
          const SizedBox(height: 16),
          AiAssistantFab(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiAssistantScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ===== GREEN APP BAR (Applied to all tabs) =====
          Container(
            width: double.infinity,
            color: const Color(0xFF385A2E),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // Left spacer — same width as the right icons to keep title centered
                    const SizedBox(width: 88),
                    // Centered title
                    Expanded(
                      child: Text(
                        _getTabTitle(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Right icons — globe + notification bell
                    const GlobeLanguagePicker(iconColor: Colors.white, iconSize: 24),
                    const NotificationBell(iconColor: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          // ===== MAIN BODY BASED ON SELECTED TAB =====

            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeTab(),
                  _buildConsultTab(),
                  _buildLearnTab(),
                  _buildNearbyTab(),
                  UserProfileScreen(
                    onBackTap: () => setState(() => _currentIndex = 0),
                    onAppointmentsTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      floatingActionButton: _buildFloatingButtons(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _getTabTitle(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return AppLocalizations.of(context)!.home;
      case 1:
        return AppLocalizations.of(context)!.consultations;
      case 2:
        return AppLocalizations.of(context)!.learningModule;
      case 3:
        return AppLocalizations.of(context)!.nearbyFacilities;
      case 4:
        return AppLocalizations.of(context)!.profile;
      default:
        return '';
    }
  }

  // TAB 0: HOME / FEED
  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryDarkGreen = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;
    
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.welcome,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.favorite, color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.welcomeSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.sageGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Image.asset(
                    'assets/images/home_illustration.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(height: 100),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 2. Need urgent help? Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencySupportScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryDarkGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.phone, color: primaryDarkGreen, size: 28),
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '24/7',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.needUrgentHelp,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.talkToProfessionalNow,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmergencySupportScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.phone_in_talk_rounded, color: primaryDarkGreen, size: 18),
                        label: Text(
                          AppLocalizations.of(context)!.startQuickConsultation,
                          style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // 3. Focus Areas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.focusAreas,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryDarkGreen,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 2,
                    color: const Color(0xFFF9A825),
                    margin: const EdgeInsets.only(top: 4),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 2; // Jump to Learning Center tab
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.viewAll,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimary : primaryDarkGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isDark ? AppColors.darkPrimary : primaryDarkGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.adolescentGirlsHealthAndNutrition,
                    subtitle: AppLocalizations.of(context)!.adolescentGirlsHealthAndNutritionDesc,
                    onTap: () => _showFocusAreaBottomSheet(context, 0),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.preventionAndAwareness,
                    subtitle: AppLocalizations.of(context)!.preventionAndAwarenessDesc,
                    onTap: () => _showFocusAreaBottomSheet(context, 1),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.psychosocialSupportAndProtection,
                    subtitle: AppLocalizations.of(context)!.psychosocialSupportAndProtectionDesc,
                    onTap: () => _showFocusAreaBottomSheet(context, 2),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.reproductiveHealthAndCare,
                    subtitle: AppLocalizations.of(context)!.reproductiveHealthAndCareDesc,
                    onTap: () => _showFocusAreaBottomSheet(context, 3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 4. About Us
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.aboutUs,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryDarkGreen,
                ),
              ),
              Container(
                width: 30,
                height: 2,
                color: const Color(0xFFF9A825),
                margin: const EdgeInsets.only(top: 4, bottom: 16),
              ),
            ],
          ),
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).cardColor : const Color(0xFFF6F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E7E1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: isDark ? const Color(0xFF81C784) : primaryDarkGreen, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.aboutUsDesc,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.grey.shade300 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.local_florist, color: const Color(0xFFF9A825), size: 40),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // 5. Helpful Services
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.helpfulServices,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryDarkGreen,
                ),
              ),
              Container(
                width: 30,
                height: 2,
                color: const Color(0xFFF9A825),
                margin: const EdgeInsets.only(top: 4, bottom: 16),
              ),
            ],
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildHelpfulServiceChip(
                  icon: Icons.calendar_today_rounded,
                  iconColor: primaryDarkGreen,
                  iconBg: const Color(0xFFD6E5D0),
                  title: AppLocalizations.of(context)!.bookAppointment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FindMidwifeScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildHelpfulServiceChip(
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF6B4C9A),
                  iconBg: const Color(0xFFEBE6F3),
                  title: AppLocalizations.of(context)!.healthResources,
                  onTap: () {
                    setState(() {
                      _currentIndex = 2; // Jump to Learning Center tab
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildHelpfulServiceChip(
                  icon: Icons.location_on_rounded,
                  iconColor: primaryDarkGreen,
                  iconBg: const Color(0xFFD6E5D0),
                  title: AppLocalizations.of(context)!.findNearbyServices,
                  onTap: () {
                    setState(() {
                      _currentIndex = 3; // Jump to Nearby Facility tab
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    ),
  );
  }

  void _showFocusAreaBottomSheet(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;

    String title;
    String subtitle;
    String category;
    IconData icon;
    Color themeColor;
    List<String> keyTopics;

    switch (index) {
      case 0:
        title = l10n.adolescentGirlsHealthAndNutrition;
        subtitle = l10n.adolescentGirlsHealthAndNutritionDesc;
        category = 'NUTRITION & GROWTH';
        icon = Icons.spa_rounded;
        themeColor = const Color(0xFF2E7D32);
        keyTopics = [
          'Puberty & Hormonal Development',
          'Menstrual Hygiene Management (MHM)',
          'Iron & Micronutrient Nutrition',
          'Healthy Body Image & Mental Well-being',
        ];
        break;
      case 1:
        title = l10n.preventionAndAwareness;
        subtitle = l10n.preventionAndAwarenessDesc;
        category = 'PREVENTION & SAFETY';
        icon = Icons.shield_rounded;
        themeColor = const Color(0xFFE65100);
        keyTopics = [
          'STI & HIV Transmission & Safe Prevention',
          'HPV Vaccination & Early Screening',
          'Healthy Relationships & Boundary Setting',
          'Community Health Stigma Reduction',
        ];
        break;
      case 2:
        title = l10n.psychosocialSupportAndProtection;
        subtitle = l10n.psychosocialSupportAndProtectionDesc;
        category = 'PSYCHOSOCIAL & SUPPORT';
        icon = Icons.favorite_rounded;
        themeColor = const Color(0xFFC2185B);
        keyTopics = [
          'Mental Health & Coping with Anxiety',
          'Emotional Resilience & Stress Reduction',
          'Confidential Support & Protection Services',
          'Safe Peer Counseling & Guidance',
        ];
        break;
      case 3:
      default:
        title = l10n.reproductiveHealthAndCare;
        subtitle = l10n.reproductiveHealthAndCareDesc;
        category = 'MATERNAL & REPRODUCTIVE';
        icon = Icons.child_care_rounded;
        themeColor = const Color(0xFF1565C0);
        keyTopics = [
          'Contraception & Informed Family Planning',
          'Antenatal Care (ANC) Health Milestones',
          'Pregnancy Warning Signs & Labor Prep',
          'Postnatal Recovery & Newborn Nutrition',
        ];
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24 + MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Category Badge & Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: themeColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.primaryGreen,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.sageGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Divider
              Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFE8ECEF), height: 1),
              const SizedBox(height: 16),

              // Key Topics Header
              Text(
                AppLocalizations.of(context)!.keyTopicsCovered,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),

              // Key Topics List
              ...keyTopics.map((topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2, right: 10),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded, size: 12, color: primaryColor),
                        ),
                        Expanded(
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(modalContext);
                        setState(() {
                          _currentIndex = 2; // Jump to Learning Center Tab
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.exploreInLearnCenter,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindMidwifeScreen(),
                        ),
                      );
                    },
                    tooltip: 'Ask Health Professional',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: primaryColor, size: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusAreaCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE8ECEF);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.primaryGreen,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.sageGrey,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpfulServiceChip({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE8ECEF);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? AppColors.darkPrimary : iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: CONSULT HUB
  Widget _buildConsultTab() {
    return ConsultHubScreen(
      onFindMidwifeTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FindMidwifeScreen(),
          ),
        );
      },
    );
  }


  // TAB 2: LEARNING CENTER
  Widget _buildLearnTab() {
    return const LearningCenterScreen(isMidwife: false);
  }

  // TAB 3: NEARBY FACILITY
  Widget _buildNearbyTab() {
    return NearbyHealthcareScreen(showBackButton: false);
  }

  Widget _buildBottomNav() {
    final items = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: AppLocalizations.of(context)!.home,
      ),
      FloatingNavBarItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: AppLocalizations.of(context)!.consult,
      ),
      FloatingNavBarItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: AppLocalizations.of(context)!.learn,
      ),
      FloatingNavBarItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: AppLocalizations.of(context)!.aiNearby,
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: AppLocalizations.of(context)!.profile,
      ),
    ];

    return FloatingGlassNavBar(
      selectedIndex: _currentIndex,
      items: items,
      onTabSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}