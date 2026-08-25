import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/notifications/data/services/notification_generator_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/find_midwife_screen.dart';
import 'package:cagh_frontend/features/nearby/presentation/screens/nearby_healthcare_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/user_profile_screen.dart';
import 'package:cagh_frontend/features/virtual_consultation/presentation/emergency_support_screen.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/widgets/ai_assistant_fab.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:cagh_frontend/shared/widgets/hotline_fab.dart';
import 'package:cagh_frontend/shared/widgets/learning_module_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/consultations/presentation/providers/chat_notification_provider.dart';

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
    GlobalCallService.initUserCallListener();
    _initGlobalCallListener();
  }

  Future<void> _loadProfile() async {
    // Left empty since _userProfile is no longer used, but kept for future use.
  }
  Future<void> _initGlobalCallListener() async {
    try {
      final api = AppointmentApiService();
      final raw = await api.getUserAppointments();
      final ids = raw.map((e) => (e['appointment_id'] ?? e['id'] ?? e['appointment_number'] ?? '').toString()).where((id) => id.isNotEmpty && id != 'null').toList();
      GlobalCallService.initMultiple(ids);
    } catch (e) {
      debugPrint('Failed to init global calls: $e');
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFF315E26)),
                      SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: NotificationGeneratorService.getUserNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF315E26)));
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No new notifications',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    final notifications = snapshot.data!;
                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return _NotificationTile(
                          title: notif['title'],
                          body: notif['body'],
                          time: notif['time'],
                          isUnread: notif['isUnread'],
                          type: notif['type'],
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== GREEN APP BAR (only on Home tab) =====
            if (_currentIndex == 0)
              Container(
                width: double.infinity,
                color: const Color(0xFF315E26),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _showNotificationsModal,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFFFFD22B),
                                size: 26,
                              ),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final unreadMap = ref.watch(chatNotificationProvider);
                                    int totalUnread = 0;
                                    unreadMap.forEach((k, v) {
                                      // only sum the raw room IDs to avoid double counting
                                      if (!k.startsWith('user_') && !k.startsWith('midwife_')) {
                                        totalUnread += v;
                                      }
                                    });
                                    
                                    if (totalUnread == 0) return const SizedBox.shrink();
                                    
                                    return Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          totalUnread > 9 ? '9+' : '$totalUnread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )

            else if (_currentIndex == 2)
              Container(
                width: double.infinity,
                color: const Color(0xFF315E26),
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
                        const SizedBox(width: 8),
                        const Text(
                          'Learning module',
                          style: TextStyle(
                            color: Colors.white,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Virtual Voice Consultation',
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
                    child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
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
              color: Colors.grey.shade700,
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

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Our Focus Areas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF315E26),
              ),
            ),
          ),
          Center(
            child: Container(
              height: 2,
              width: 50,
              margin: const EdgeInsets.only(top: 4, bottom: 20),
              color: const Color(0xFFFFD22B),
            ),
          ),

          LearningModuleCard(
            icon: Icons.menu_book_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Adolescent Girls Health & Nutrition',
            subtitle: 'Puberty, menstrual health, nutrition & healthy lifestyle, life skills & well-being.',
            arrowBgColor: const Color(0xFFA5D6A7),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LearningModuleCard(
            icon: Icons.shield_outlined,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Prevention and Awareness',
            subtitle: 'STI/HIV prevention, HPV & cervical cancer awareness, healthy relationships.',
            arrowBgColor: const Color(0xFFFFD22B),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LearningModuleCard(
            icon: Icons.favorite_border_rounded,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Psychosocial Support & Protection',
            subtitle: 'Mental health, GBV support, counseling services, and emergency help.',
            arrowBgColor: const Color(0xFFFFD22B),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LearningModuleCard(
            icon: Icons.female,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Reproductive Health & Care',
            subtitle: 'Pregnancy prevention, maternal care, ANC, newborn care, and checkups.',
            arrowBgColor: const Color(0xFFA5D6A7),
            onTap: () {},
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
            arrowBgColor: const Color(0xFFA5D6A7),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LearningModuleCard(
            icon: Icons.shield_outlined,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Prevention and Awareness',
            subtitle: 'STI/HIV prevention, HPV & cervical cancer awareness, healthy relationships.',
            arrowBgColor: const Color(0xFFFFD22B),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LearningModuleCard(
            icon: Icons.favorite_border_rounded,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFD22B),
            title: 'Psychosocial Support & Protection',
            subtitle: 'Mental health, GBV support, counseling services, and emergency help.',
            arrowBgColor: const Color(0xFFFFD22B),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          LearningModuleCard(
            icon: Icons.female,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF315E26),
            title: 'Reproductive Health & Care',
            subtitle: 'Pregnancy prevention, maternal care, ANC, newborn care, and checkups.',
            arrowBgColor: const Color(0xFFA5D6A7),
            onTap: () {},
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }


  // TAB 3: NEARBY FACILITY
  Widget _buildNearbyTab() {
    return const NearbyHealthcareScreen(showBackButton: false);
  }

  Widget _buildBottomNav() {
    final items = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: LanguageService.tr(context, 'home'),
      ),
      FloatingNavBarItem(
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services_rounded,
        label: LanguageService.tr(context, 'consult'),
      ),
      FloatingNavBarItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: LanguageService.tr(context, 'learn'),
      ),
      FloatingNavBarItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: LanguageService.tr(context, 'nearby'),
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: LanguageService.tr(context, 'profile'),
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
        color: isUnread ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}