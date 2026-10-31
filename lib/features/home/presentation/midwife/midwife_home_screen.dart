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
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_inbox_screen.dart';
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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
    final defaultTitle = AppLocalizations.of(context)?.midwifeTitle ?? 'Health Professional';
    if (fullName.isEmpty) return defaultTitle;
    // If it happens to be an email, take the part before @
    if (fullName.contains('@')) {
      fullName = fullName.split('@').first;
    }
    // Return just the first name
    final name = fullName.trim().split(' ').first;
    return name.isEmpty ? defaultTitle : name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF7F9F7),
      body: Column(
        children: [
          // ===== GREEN APP BAR (Applied to all tabs) =====
          Container(
            width: double.infinity,
            color: const Color(0xFF2C5927),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      _getAppBarTitle(selectedIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        GlobeLanguagePicker(iconColor: Colors.white, iconSize: 22),
                        SizedBox(width: 8),
                        NotificationBell(iconColor: Colors.white),
                      ],
                    ),
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
        final pendingRequests = aptList.where((a) => a.status == AppointmentStatus.pending).toList();
        final pendingCount = pendingRequests.length;

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
              // 1. WELCOME CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.black.withValues(alpha: 0.04),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.welcomeMidwife(_getFirstName(midwifeName)),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF182335),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.midwifeDailySupportSubtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F2E6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.how_to_reg_rounded,
                        size: 32,
                        color: isDark ? AppColors.darkPrimary : const Color(0xFF3B6E32),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. PENDING REQUESTS HERO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C5927),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2C5927).withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B814C),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.pendingRequests,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pendingCount > 0
                                    ? l10n.actionRequiredForConsultations
                                    : l10n.noPendingRequestsAtThisTime,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5BD1A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.badgeNew,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _openPendingRequestsAndSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2C5927),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 19, color: Color(0xFF2C5927)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.reviewRequestsAndSchedule,
                              style: const TextStyle(
                                color: Color(0xFF2C5927),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3. MIDWIFE WORKFLOWS & TOOLS
              _buildSectionHeader(l10n.midwifeWorkflowsAndTools),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildWorkflowCard(
                      title: l10n.manageHours,
                      subtitle: l10n.manageHoursSubtitle,
                      icon: Icons.access_time_rounded,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildWorkflowCard(
                      title: l10n.clientMessages,
                      subtitle: l10n.clientMessagesSubtitle,
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBgColor: const Color(0xFFE8F0FE),
                      iconColor: const Color(0xFF1976D2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MidwifeInboxScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildWideWorkflowCard(
                title: l10n.consultCalendar,
                subtitle: l10n.consultCalendarSubtitle,
                icon: Icons.calendar_month_outlined,
                iconBgColor: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MidwifeConsultsScreen(showAppBar: true, initialTab: 1),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),

              const SizedBox(height: 22),

              // 4. CLINICAL PROTOCOLS
              _buildSectionHeader(l10n.clinicalProtocols),
              const SizedBox(height: 12),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showProtocolDetailsModal(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.black.withValues(alpha: 0.04),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F3E6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: isDark ? AppColors.darkPrimary : const Color(0xFF2E7D32),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.adolescentCareProtocolTitle,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.adolescentCareProtocolDesc,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. TODAY'S CONFIRMED CONSULTATIONS (if any)
              if (upcomingApts.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.todaysConfirmedConsultations),
                const SizedBox(height: 12),
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
              ],

              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }

  void _openPendingRequestsAndSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MidwifeConsultsScreen(showAppBar: true, initialTab: 0),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFE59828),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.darkPrimary : iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideWorkflowCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.darkPrimary : iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : iconBgColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? AppColors.darkPrimary : iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProtocolDetailsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F3E6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Adolescent Care Protocol',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE59828).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '2026',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB46E08),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'MOH & WHO Clinical Standard for Youth Consultations',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                _buildProtocolItem(
                  icon: Icons.lock_outline_rounded,
                  title: '1. Strict Confidentiality & Safe Environment',
                  desc: 'Adolescent health queries and consultations must remain completely confidential without stigmatization.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildProtocolItem(
                  icon: Icons.water_drop_outlined,
                  title: '2. Menstrual Health Education & Pain Management',
                  desc: 'Educate on normal cycle variation, hygiene management, and non-pharmacological & safe pharmacological pain relief.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildProtocolItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '3. Empathetic, Non-Judgmental Counseling',
                  desc: 'Use active listening, open-ended questions, and affirm bodily autonomy and emotional well-being.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildProtocolItem(
                  icon: Icons.emergency_outlined,
                  title: '4. Red Flag Identification & Referral Escalation',
                  desc: 'Immediate clinical triage and referral for severe acute abdominal pain, abnormal heavy bleeding, or distress.',
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      setState(() => selectedIndex = 3);
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: const Text('Open Full Learning & Protocols Center', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5927),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProtocolItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F6F0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF2E7D32)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationCard(
    BuildContext context, {
    required Appointment appointment,
    required VoidCallback onCompleted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patientName = appointment.userFullName ?? (AppLocalizations.of(context)?.patient ?? 'Patient');
    String type;
    switch (appointment.appointmentType.toUpperCase().trim()) {
      case 'VIRTUAL_VOICE':
        type = 'Voice Call';
        break;
      case 'VIRTUAL_VIDEO':
        type = 'Video Call';
        break;
      case 'IN_PERSON':
        type = 'In Person';
        break;
      case 'CHAT':
        type = 'Chat';
        break;
      default:
        type = appointment.appointmentType.isNotEmpty ? appointment.appointmentType : 'Consultation';
    }
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