import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_profile_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_consults_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_schedule_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_manage_schedule_screen.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/features/learning/presentation/screens/learning_center_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

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
      
      String resolvedName = '';
      
      void extractName(Map<String, dynamic> data) {
        final u = data['user'] is Map ? data['user'] : data;
        final p = u['profile'] is Map ? u['profile'] : (data['profile'] is Map ? data['profile'] : {});
        
        final fName = p['first_name']?.toString() ?? u['first_name']?.toString() ?? data['first_name']?.toString() ?? '';
        final lName = p['last_name']?.toString() ?? u['last_name']?.toString() ?? data['last_name']?.toString() ?? '';
        final full = p['full_name']?.toString() ?? u['full_name']?.toString() ?? data['full_name']?.toString() ?? '';
        
        if (full.isNotEmpty) {
          resolvedName = full;
        } else if (fName.isNotEmpty) {
          resolvedName = '$fName $lName'.trim();
        }
        
        if (resolvedName.isEmpty) {
          resolvedName = p['email']?.toString() ?? u['email']?.toString() ?? data['email']?.toString() ?? '';
        }
      }
      
      extractName(localData);
      
      if (resolvedName.isNotEmpty && mounted) {
        setState(() {
          midwifeName = resolvedName;
        });
      }

      final response = await AuthService.getProfile();
      if (response.success && response.data != null && mounted) {
        extractName(response.data!);
        if (resolvedName.isNotEmpty) {
          setState(() {
            midwifeName = resolvedName;
          });
        }
      }
      
      // Final reliable fallback using Midwife specific profile
      final midwifeRepo = MidwifeRepositoryImpl(MidwifeApiService());
      final midwifeProfile = await midwifeRepo.getMyProfile();
      if (midwifeProfile != null && midwifeProfile.fullName.isNotEmpty && mounted) {
        setState(() {
          midwifeName = midwifeProfile.fullName;
        });
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
                        _getAppBarTitle(selectedIndex),
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
          
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _buildHomeDashboardTab(),
                const MidwifeScheduleScreen(),
                const MidwifeConsultsScreen(),
                _buildLearnTab(),
                const MidwifeProfileScreen(),
              ],
            ),
          ),
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

  bool _isToday(String dateStr) {
    if (dateStr.trim().isEmpty) return false;
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final cleanDateStr = dateStr.trim();
      if (cleanDateStr.startsWith(todayStr)) return true;

      final parsed = DateTime.parse(cleanDateStr).toLocal();
      return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
    } catch (_) {
      return false;
    }
  }

  // TAB 0: HOME DASHBOARD
  Widget _buildHomeDashboardTab() {
    final appointmentRepo = AppointmentRepositoryImpl(AppointmentApiService());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<List<Appointment>>(
      future: appointmentRepo.getMidwifeAppointments(),
      builder: (context, snapshot) {
        final aptList = snapshot.data ?? [];
        final upcomingApts = aptList.where((a) {
          final isConfirmed = a.status == AppointmentStatus.confirmed;
          return isConfirmed && _isToday(a.date);
        }).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.primaryGreen,
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
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            upcomingApts.isEmpty
                                ? AppLocalizations.of(context)!.midwifeBookingsAppearHere
                                : AppLocalizations.of(context)!.patientConsultationBookingsPending(upcomingApts.length),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : Colors.white.withValues(alpha: 0.87),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.volunteer_activism_outlined, color: isDark ? AppColors.darkPrimary : Colors.white, size: 48),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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

              // Manage Availability Action Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : AppColors.primaryGreen.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_calendar_rounded,
                          color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.manageAvailability,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF182335),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppLocalizations.of(context)!.setDaysAndTimesPrompt,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : Colors.black54,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.primaryGreen,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (snapshot.connectionState == ConnectionState.waiting)
                Center(child: CircularProgressIndicator(color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen))
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
                      Icon(Icons.event_available_outlined, size: 48, color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.noUpcomingConsultations,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Any confirmed appointments scheduled for today will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...upcomingApts.map((apt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConsultationCard(
                      context,
                      appointment: apt,
                      onCompleted: () => setState(() {}),
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

  Widget _buildConsultationCard(
    BuildContext context, {
    required Appointment appointment,
    required VoidCallback onCompleted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patientName = appointment.userFullName ?? 'Patient';
    final type = appointment.appointmentType == 'VIRTUAL_VOICE' ? 'Voice Call' : 'Video Call';
    final dateStr = '${appointment.date} • ${appointment.startTime}';
    return _buildScheduleItem(
      time: appointment.startTime.isNotEmpty ? appointment.startTime : 'Scheduled',
      title: patientName,
      subtitle: '$type • $dateStr',
      badgeLabel: appointment.status.name.toUpperCase(),
      badgeColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F5E9),
      badgeTextColor: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
    );
  }

  // TAB 3: LEARNING CENTER
  Widget _buildLearnTab() {
    return const LearningCenterScreen(isMidwife: true);
  }

  Widget _buildScheduleItem({required String time, required String title, required String subtitle, required String badgeLabel, required Color badgeColor, required Color badgeTextColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Theme.of(context).textTheme.bodyLarge?.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
        if (index == 0) {
          _fetchProfile();
        }
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}