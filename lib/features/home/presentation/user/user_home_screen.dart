import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/find_midwife_screen.dart';
import 'package:cagh_frontend/features/nearby/presentation/screens/nearby_healthcare_screen.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/user_profile_screen.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/widgets/ai_assistant_fab.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:cagh_frontend/shared/widgets/hotline_fab.dart';
import 'package:cagh_frontend/shared/widgets/learning_module_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final bool _hasUpcomingAppointment = false;
  
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
                    onAppointmentsTap: () => setState(() => _currentIndex = 1),
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
    final primaryDarkGreen = const Color(0xFF385A2E);
    
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
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.welcome,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF385A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.favorite, color: primaryDarkGreen, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.welcomeSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black87,
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
                    errorBuilder: (_, __, ___) => const SizedBox(height: 100),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 2. Need urgent help? Card
          Container(
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
                              color: Colors.white.withOpacity(0.9),
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
                    onPressed: () {},
                    icon: Icon(Icons.chat, color: primaryDarkGreen, size: 18),
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
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
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
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.preventionAndAwareness,
                    subtitle: AppLocalizations.of(context)!.preventionAndAwarenessDesc,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.psychosocialSupportAndProtection,
                    subtitle: AppLocalizations.of(context)!.psychosocialSupportAndProtectionDesc,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: _buildFocusAreaCard(
                    title: AppLocalizations.of(context)!.reproductiveHealthAndCare,
                    subtitle: AppLocalizations.of(context)!.reproductiveHealthAndCareDesc,
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
                  icon: Icons.calendar_today,
                  iconColor: primaryDarkGreen,
                  iconBg: const Color(0xFFD6E5D0),
                  title: AppLocalizations.of(context)!.bookAppointment,
                ),
                const SizedBox(width: 12),
                _buildHelpfulServiceChip(
                  icon: Icons.description,
                  iconColor: const Color(0xFF6B4C9A),
                  iconBg: const Color(0xFFEBE6F3),
                  title: AppLocalizations.of(context)!.healthResources,
                ),
                const SizedBox(width: 12),
                _buildHelpfulServiceChip(
                  icon: Icons.location_on,
                  iconColor: primaryDarkGreen,
                  iconBg: const Color(0xFFD6E5D0),
                  title: AppLocalizations.of(context)!.findNearbyServices,
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

  Widget _buildFocusAreaCard({required String title, required String subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF385A2E),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white70 : const Color(0xFF385A2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpfulServiceChip({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E4823).withOpacity(0.3) : iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isDark ? const Color(0xFF81C784) : iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white60 : Colors.black54),
        ],
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
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLearningModuleCard(
            icon: Icons.menu_book_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: AppLocalizations.of(context)!.adolescentGirlsHealthAndNutrition,
            subtitle: AppLocalizations.of(context)!.adolescentGirlsHealthAndNutritionDesc,
            arrowBgColor: const Color(0xFFF1F8E9),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.shield_outlined,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: AppLocalizations.of(context)!.preventionAndAwareness,
            subtitle: AppLocalizations.of(context)!.preventionAndAwarenessDesc,
            arrowBgColor: const Color(0xFFFFF8E1),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.favorite_border_rounded,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: AppLocalizations.of(context)!.psychosocialSupportAndProtection,
            subtitle: AppLocalizations.of(context)!.psychosocialSupportAndProtectionDesc,
            arrowBgColor: const Color(0xFFFFF8E1),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.female,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: AppLocalizations.of(context)!.reproductiveHealthAndCare,
            subtitle: AppLocalizations.of(context)!.reproductiveHealthAndCareDesc,
            arrowBgColor: const Color(0xFFF1F8E9),
          ),
          const SizedBox(height: 80),
        ],
      ),
    ),
  );
}

  Widget _buildLearningModuleCard({
    required IconData icon, // Kept for backwards compatibility but not used
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color arrowBgColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2E4823),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E4823) : const Color(0xFFE8F2E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? Colors.white : const Color(0xFF385A2E),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
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

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isUnread;
  final String type;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF315E26),
            child: Icon(
              type == 'APPOINTMENT' ? Icons.calendar_today : Icons.chat,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}