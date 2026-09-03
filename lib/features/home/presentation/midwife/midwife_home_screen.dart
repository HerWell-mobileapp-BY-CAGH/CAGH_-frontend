import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_profile_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_consults_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_inbox_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_schedule_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_manage_schedule_screen.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class MidwifeHomeScreen extends ConsumerStatefulWidget {
  const MidwifeHomeScreen({super.key});

  @override
  ConsumerState<MidwifeHomeScreen> createState() => _MidwifeHomeScreenState();
}

class _MidwifeHomeScreenState extends ConsumerState<MidwifeHomeScreen> {
  String midwifeName = '';
  bool isLoadingProfile = true;
  int selectedIndex = 0;

  final TextEditingController _learnSearchController = TextEditingController();

  String _selectedLearnCategory = 'All';
  final Set<String> _bookmarkedArticles = {};

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _learnSearchController.dispose();
    super.dispose();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _getAppBarTitle(selectedIndex),
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          const GlobeLanguagePicker(iconColor: Color(0xFFFFD22B), iconSize: 24),
          NotificationBell(iconColor: Theme.of(context).appBarTheme.foregroundColor),
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
          MidwifeProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return AppLocalizations.of(context)!.home;
      case 1:
        return AppLocalizations.of(context)!.schedule;
      case 2:
        return AppLocalizations.of(context)!.consult;
      case 3:
        return AppLocalizations.of(context)!.learn;
      case 4:
        return AppLocalizations.of(context)!.profile;
      default:
        return AppLocalizations.of(context)!.home;
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
                            _getFirstName(midwifeName).isEmpty
                                ? AppLocalizations.of(context)!.welcome
                                : AppLocalizations.of(context)!.welcomeUser(_getFirstName(midwifeName)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            upcomingApts.isEmpty
                                ? AppLocalizations.of(context)!.patientBookingsWillAppearHere
                                : AppLocalizations.of(context)!.patientConsultationBookingsPending(upcomingApts.length),
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

              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.todaysAppointments,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (upcomingApts.isNotEmpty)
                    Text(
                      AppLocalizations.of(context)!.totalCount(upcomingApts.length),
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12.5),
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
                  icon: Icon(Icons.edit_calendar, color: Color(0xFF315E26)),
                  label: Text(
                    AppLocalizations.of(context)!.manageAvailability,
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 42, color: Theme.of(context).iconTheme.color?.withOpacity(0.4)),
                      SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.noAppointments,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.noAppointmentsSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12.5),
                      ),
                    ],
                  ),
                )
              else
                ...upcomingApts.map((apt) {
                  String displayType = apt.appointmentType;
                  if (displayType == 'VIRTUAL_VIDEO' || displayType == 'VIRTUAL_VOICE') {
                    displayType = AppLocalizations.of(context)!.voiceCall;
                  } else if (displayType == 'IN_PERSON') {
                    displayType = AppLocalizations.of(context)!.inPerson;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildScheduleItem(
                      time: apt.startTime,
                      title: '${apt.userFullName ?? AppLocalizations.of(context)!.patient} - $displayType',
                      subtitle: AppLocalizations.of(context)!.dateLabel(apt.date),
                      badgeLabel: AppLocalizations.of(context)!.booked,
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

  // TAB 3: LEARNING CENTER
  Widget _buildLearnTab() {
    return SingleChildScrollView(
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
              color: Colors.black.withOpacity(0.03),
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
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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

  Widget _buildScheduleItem({required String time, required String title, required String subtitle, required String badgeLabel, required Color badgeColor, required Color badgeTextColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF315E26), width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
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
        label: AppLocalizations.of(context)!.home,
      ),
      FloatingNavBarItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: AppLocalizations.of(context)!.schedule,
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
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: AppLocalizations.of(context)!.profile,
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