import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/notifications/data/services/notification_generator_service.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_profile_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_consults_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_schedule_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_manage_schedule_screen.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/widgets/learning_module_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/consultations/presentation/providers/chat_notification_provider.dart';

class MidwifeHomeScreen extends StatefulWidget {
  const MidwifeHomeScreen({super.key});

  @override
  State<MidwifeHomeScreen> createState() => _MidwifeHomeScreenState();
}

class _MidwifeHomeScreenState extends State<MidwifeHomeScreen> {
  String midwifeName = 'Sarah Jenkins';
  bool isLoadingProfile = true;
  int selectedIndex = 0;

  @override
  void initState() {
    _initGlobalCallListener();
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initGlobalCallListener() async {
    try {
      final api = AppointmentApiService();
      final apts = await api.getMidwifeAppointments();
      final ids = apts.map((e) => (e['id'] ?? e['appointment_id'] ?? e['appointment_number'] ?? '').toString()).where((id) => id.isNotEmpty && id != 'null').toList();
      GlobalCallService.initMultiple(ids);
    } catch (e) {
      debugPrint('Failed to init global calls: $e');
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final localData = await AuthService.getUserData();
      if (localData['full_name'] != null && localData['full_name'].toString().isNotEmpty && mounted) {
        setState(() {
          midwifeName = localData['full_name'].toString();
        });
      }

      final response = await AuthService.getProfile();
      if (response.success && response.data != null && mounted) {
        final profileData = response.data!;
        final fullName = profileData['full_name'] ?? profileData['email'] ?? '';
        if (fullName.toString().isNotEmpty) {
          setState(() {
            midwifeName = fullName.toString();
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => isLoadingProfile = false);
    }
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Midwife';
    // If it happens to be an email, take the part before @
    if (fullName.contains('@')) {
      fullName = fullName.split('@').first;
    }
    // Return just the first name
    return fullName.trim().split(' ').first;
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
                  future: NotificationGeneratorService.getMidwifeNotifications(),
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
                            Navigator.pop(context); // close modal
                            setState(() {
                              selectedIndex = 2; // Consults tab handles both chat and appointments
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

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == 1) {
      return Scaffold(
        extendBody: true,
        body: const MidwifeScheduleScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    if (selectedIndex == 2) {
      return Scaffold(
        extendBody: true,
        body: const MidwifeConsultsScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    if (selectedIndex == 4) {
      return Scaffold(
        extendBody: true,
        body: const MidwifeProfileScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315E26),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _getAppBarTitle(selectedIndex),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          const GlobeLanguagePicker(iconColor: Color(0xFFFFD22B), iconSize: 24),
          Consumer(
            builder: (context, ref, child) {
              final unreadMap = ref.watch(chatNotificationProvider);
              int totalUnread = 0;
              unreadMap.forEach((k, v) {
                if (!k.startsWith('user_') && !k.startsWith('midwife_')) {
                  totalUnread += v;
                }
              });
              
              Widget icon = IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: _showNotificationsModal,
              );
              
              if (totalUnread == 0) return icon;
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  Positioned(
                    right: 8,
                    top: 8,
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
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHomeDashboardTab(),
          const MidwifeScheduleScreen(),
          const MidwifeConsultsScreen(),
          _buildLearnTab(),
          const MidwifeProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return LanguageService.tr(context, 'home');
      case 1:
        return LanguageService.tr(context, 'schedule');
      case 2:
        return LanguageService.tr(context, 'consult');
      case 3:
        return LanguageService.tr(context, 'learn');
      case 4:
        return LanguageService.tr(context, 'profile');
      default:
        return LanguageService.tr(context, 'home');
    }
  }

  // TAB 0: HOME DASHBOARD
  Widget _buildHomeDashboardTab() {
    final appointmentRepo = AppointmentRepositoryImpl(AppointmentApiService());
    
    return FutureBuilder<List<Appointment>>(
      future: appointmentRepo.getMidwifeAppointments(),
      builder: (context, snapshot) {
        final aptList = snapshot.data ?? [];
        final upcomingApts = aptList.where((a) => a.status == AppointmentStatus.confirmed).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF315E26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageService.tr(context, 'welcome_back').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome ${_getFirstName(midwifeName)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            upcomingApts.isEmpty
                                ? 'Welcome to Digital Midwife! Your patient bookings will appear here.'
                                : 'You have ${upcomingApts.length} patient consultation bookings pending.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.87),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.medical_services_outlined, color: Colors.white, size: 48),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService.tr(context, 'todays_appointments'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (upcomingApts.isNotEmpty)
                    Text(
                      '${upcomingApts.length} Total',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Manage Schedule Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar, color: Color(0xFF315E26)),
                  label: const Text(
                    'Manage Availability',
                    style: TextStyle(color: Color(0xFF315E26), fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF315E26)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: Color(0xFF315E26)))
              else if (upcomingApts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 42, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        LanguageService.tr(context, 'no_appointments'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.tr(context, 'no_appointments_sub'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ],
                  ),
                )
              else
                ...upcomingApts.map((apt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildScheduleItem(
                      time: apt.startTime,
                      title: '${apt.userFullName ?? 'Patient'} - ${apt.appointmentType}',
                      subtitle: 'Date: ${apt.date}',
                      badgeLabel: 'BOOKED',
                      badgeColor: const Color(0xFFC8E6C9),
                      badgeTextColor: const Color(0xFF315E26),
                    ),
                  );
                }),

              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: CLINICAL LEARNING HUB FOR MIDWIVES
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
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({required String time, required String title, required String subtitle, required String badgeLabel, required Color badgeColor, required Color badgeTextColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF315E26), width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
            child: Text(badgeLabel, style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final items = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: LanguageService.tr(context, 'home'),
      ),
      FloatingNavBarItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: LanguageService.tr(context, 'schedule'),
      ),
      FloatingNavBarItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: LanguageService.tr(context, 'consult'),
      ),
      FloatingNavBarItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: LanguageService.tr(context, 'learn'),
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: LanguageService.tr(context, 'profile'),
      ),
    ];

    return FloatingGlassNavBar(
      selectedIndex: selectedIndex,
      items: items,
      onTabSelected: (index) {
        setState(() {
          selectedIndex = index;
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
              type == 'APPOINTMENT' ? Icons.calendar_today : type == 'CHAT' ? Icons.chat : Icons.info_outline,
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