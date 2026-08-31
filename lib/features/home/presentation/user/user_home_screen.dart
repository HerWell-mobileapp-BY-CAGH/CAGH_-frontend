import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/find_midwife_screen.dart';
import 'package:cagh_frontend/features/nearby/presentation/screens/nearby_healthcare_screen.dart';
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
    if (_currentIndex == 4) {
      return Scaffold(
        extendBody: true,
        body: UserProfileScreen(
          onBackTap: () => setState(() => _currentIndex = 0),
        ),
        floatingActionButton: _buildFloatingButtons(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ===== GREEN APP BAR (only on Home tab) =====
            if (_currentIndex == 0)
              Container(
                width: double.infinity,
                color: Theme.of(context).appBarTheme.backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        color: Theme.of(context).appBarTheme.foregroundColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const NotificationBell(iconColor: Color(0xFFFFD22B)),
                  ],
                ),
              )

            else if (_currentIndex == 2)
              Container(
                width: double.infinity,
                color: Theme.of(context).appBarTheme.backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD22B)),
                          onPressed: () => setState(() => _currentIndex = 0),
                        ),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.learningModule,
                          style: TextStyle(
                            color: Theme.of(context).appBarTheme.foregroundColor,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFFFFD22B)),
                      onPressed: () {},
                    ),
                  ],
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
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButtons(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // TAB 0: HOME DASHBOARD
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Upcoming Appointment Alert Card (Hidden by default for new users)
          if (_hasUpcomingAppointment) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF315E26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.virtualVoiceConsultation,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF315E26),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tomorrow at 10:00 AM • Sr. Martha T.',
                          style: TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(AppLocalizations.of(context)!.join, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'ABOUT US',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Color(0xFF315E26),
            ),
          ),
          Container(
            height: 2,
            width: 50,
            margin: const EdgeInsets.only(top: 4, bottom: 16),
            color: const Color(0xFFFFD22B),
          ),
          Text(
            'We provide confidential consultation, education and care to help women and adolescent girls make informed choices and live healthier lives.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Image.asset(
              'assets/images/home_illustration.png',
              fit: BoxFit.contain,
              height: 220,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.health_and_safety,
                  size: 70,
                  color: Color(0xFF315E26),
                );
              },
            ),
          ),

          SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)!.ourFocusAreas,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF315E26),
            ),
          ),
          Container(
            height: 2,
            width: 40,
            margin: const EdgeInsets.only(top: 4, bottom: 16),
            color: const Color(0xFFFFD22B),
          ),

          LearningModuleCard(
            icon: Icons.menu_book_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Adolescent Girls Health & Nutrition',
            subtitle: 'Puberty, menstrual health, nutrition & healthy lifestyle, life skills & well-being.',
            arrowBgColor: const Color(0xFFF1F8E9),
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.shield_outlined,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Prevention and Awareness',
            subtitle: 'STI/HIV prevention, HPV & cervical cancer awareness, healthy relationships.',
            arrowBgColor: const Color(0xFFFFF8E1),
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.favorite_border_rounded,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Psychosocial Support & Protection',
            subtitle: 'Mental health, GBV support, counseling services, and emergency help.',
            arrowBgColor: const Color(0xFFFFF8E1),
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.female,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Reproductive Health & Care',
            subtitle: 'Pregnancy prevention, maternal care, ANC, newborn care, and checkups.',
            arrowBgColor: const Color(0xFFF1F8E9),
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(height: 30),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LearningModuleCard(
            icon: Icons.menu_book_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Adolescent Girls Health & Nutrition',
            subtitle: 'Puberty, menstrual health, nutrition & healthy lifestyle, life skills & well-being.',
            arrowBgColor: const Color(0xFFF1F8E9),
            onTap: () {},
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.shield_outlined,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Prevention and Awareness',
            subtitle: 'STI/HIV prevention, HPV & cervical cancer awareness, healthy relationships.',
            arrowBgColor: const Color(0xFFFFF8E1),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.favorite_border_rounded,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Psychosocial Support & Protection',
            subtitle: 'Mental health, GBV support, counseling services, and emergency help.',
            arrowBgColor: const Color(0xFFFFF8E1),
          ),
          const SizedBox(height: 14),
          _buildLearningModuleCard(
            icon: Icons.female,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Reproductive Health & Care',
            subtitle: 'Pregnancy prevention, maternal care, ANC, newborn care, and checkups.',
            arrowBgColor: const Color(0xFFF1F8E9),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLearningModuleCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color arrowBgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: arrowBgColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF315E26), size: 16),
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