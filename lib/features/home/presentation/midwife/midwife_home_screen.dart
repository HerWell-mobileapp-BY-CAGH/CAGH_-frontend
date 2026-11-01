import 'package:cagh_frontend/features/home/presentation/midwife/providers/midwife_dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
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
        if (resolvedName.isEmpty) {
          extractName(response.data!);
          if (resolvedName.isNotEmpty) {
            setState(() {
              midwifeName = resolvedName;
            });
          }
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
                child: SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getAppBarTitle(selectedIndex),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          GlobeLanguagePicker(iconColor: Colors.white),
                          SizedBox(width: 6),
                          NotificationBell(iconColor: Colors.white),
                          SizedBox(width: 4),
                        ],
                      ),
                    ],
                  ),
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

  // TAB 0: REDESIGNED PROFESSIONAL HOME DASHBOARD
  Widget _buildHomeDashboardTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAm = Localizations.localeOf(context).languageCode.startsWith('am');
    final dashboard = ref.watch(midwifeDashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(midwifeDashboardProvider.notifier).fetchDashboard(showLoading: false),
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. WELCOME & STATUS HERO CARD
            _buildWelcomeStatusCard(isDark, isAm, dashboard),

            const SizedBox(height: 16),

            // 2. REAL-TIME PENDING REQUESTS HERO BANNER
            _buildPendingRequestsBanner(isDark, isAm, dashboard),

            const SizedBox(height: 20),

            // 3. REAL-TIME PRACTICE STATS (3-card grid, 100% dynamic)
            _buildPracticeStatsGrid(isDark, isAm, dashboard),

            const SizedBox(height: 22),

            // 4. TODAY'S AGENDA
            _buildTodaysAgendaSection(isDark, isAm, dashboard),

            const SizedBox(height: 22),

            // 5. PRACTICE TOOLS & PROTOCOLS (Clean, no duplicate navigation)
            _buildPracticeToolsSection(isDark, isAm, dashboard),

            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStatusCard(bool isDark, bool isAm, MidwifeDashboardData dashboard) {
    final firstName = _getFirstName(midwifeName);
    final isAvailable = dashboard.hasActiveAvailability;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE4EDE3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.035),
            blurRadius: 14,
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
                      ).then((_) {
                        ref.read(midwifeDashboardProvider.notifier).refresh(isSilent: true);
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? (isDark ? const Color(0xFF1B3822) : const Color(0xFFE8F5E9))
                            : (isDark ? const Color(0xFF332A16) : const Color(0xFFFFF8E1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAvailable
                              ? (isDark ? const Color(0xFF2E6336) : const Color(0xFFC8E6C9))
                              : (isDark ? const Color(0xFF665426) : const Color(0xFFFFE082)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isAvailable ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable
                                ? (isAm ? 'አገልግሎት ለመስጠት ዝግጁ' : 'Active & Accepting Bookings')
                                : (isAm ? 'ሰዓት አልተዘጋጀም • ሰዓት ያቀናብሩ' : 'No Active Hours • Set Schedule'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isAvailable
                                  ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF1B5E20))
                                  : (isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.welcomeMidwife(firstName),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF182335),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.midwifeDailySupportSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF274323), const Color(0xFF1A3017)]
                    : [const Color(0xFFD8ECD5), const Color(0xFFC5E5C1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF3B6634) : const Color(0xFFA5D6A7),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.medical_services_rounded,
              size: 28,
              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2C5927),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsBanner(bool isDark, bool isAm, MidwifeDashboardData dashboard) {
    final count = dashboard.pendingCount;

    if (count > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF20481D), Color(0xFF2C5927)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFF5BD1A).withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C5927).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5BD1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        isAm ? 'እርምጃ ያስፈልጋል' : 'ACTION REQUIRED',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5BD1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count ${isAm ? "አዲስ" : "Pending"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count == 1
                  ? (isAm ? '1 በመጠባበቅ ላይ ያለ የምክክር ጥያቄ' : '1 Pending Consultation Request')
                  : (isAm ? '$count በመጠባበቅ ላይ ያሉ የምክክር ጥያቄዎች' : '$count Pending Consultation Requests'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAm
                  ? 'ሕመምተኞች የእርስዎን ማረጋገጫ በመጠባበቅ ላይ ናቸው። ለመቀበል ወይም ላለመቀበል ይመልከቱ።'
                  : 'Patients are awaiting your confirmation. Review details to accept or decline.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(midwifeConsultTabProvider.notifier).state = 0;
                  setState(() => selectedIndex = 2);
                },
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
                    const Icon(Icons.assignment_turned_in_rounded, size: 18, color: Color(0xFF2C5927)),
                    const SizedBox(width: 8),
                    Text(
                      isAm ? 'ጥያቄዎችን አሁን ይገምግሙ' : 'Review & Respond Now',
                      style: const TextStyle(
                        color: Color(0xFF2C5927),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2C5927)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2ECE0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B3822) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAm ? 'ሁሉም ተጠናቋል!' : 'All Caught Up!',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF182335),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAm
                      ? 'በአሁኑ ጊዜ በመጠባበቅ ላይ ያለ ጥያቄ የለም።'
                      : 'No pending consultation requests at this time.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ref.read(midwifeConsultTabProvider.notifier).state = 1;
              setState(() => selectedIndex = 2);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isAm ? 'ይመልከቱ →' : 'View →',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeStatsGrid(bool isDark, bool isAm, MidwifeDashboardData dashboard) {
    return Row(
      children: [
        // 1. Today's Sessions
        Expanded(
          child: _buildMetricTile(
            isDark: isDark,
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF1D4ED8),
            iconBgColor: isDark ? const Color(0xFF1E2E4A) : const Color(0xFFEFF6FF),
            value: '${dashboard.todayCount}',
            label: isAm ? 'የዛሬ' : "Today's",
            sublabel: isAm ? 'ቀጠሮዎች' : 'Sessions',
            onTap: () {
              ref.read(midwifeConsultTabProvider.notifier).state = 2; // Today tab
              setState(() => selectedIndex = 2);
            },
          ),
        ),
        const SizedBox(width: 10),

        // 2. Pending Requests
        Expanded(
          child: _buildMetricTile(
            isDark: isDark,
            icon: Icons.hourglass_top_rounded,
            iconColor: dashboard.pendingCount > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
            iconBgColor: isDark
                ? (dashboard.pendingCount > 0 ? const Color(0xFF382A14) : const Color(0xFF222830))
                : (dashboard.pendingCount > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9)),
            value: '${dashboard.pendingCount}',
            valueColor: dashboard.pendingCount > 0 ? const Color(0xFFD97706) : null,
            label: isAm ? 'በመጠባበቅ' : 'Pending',
            sublabel: isAm ? 'ያሉ ጥያቄዎች' : 'Review',
            onTap: () {
              ref.read(midwifeConsultTabProvider.notifier).state = 0; // Pending tab
              setState(() => selectedIndex = 2);
            },
          ),
        ),
        const SizedBox(width: 10),

        // 3. Completed Consultations
        Expanded(
          child: _buildMetricTile(
            isDark: isDark,
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF15803D),
            iconBgColor: isDark ? const Color(0xFF183020) : const Color(0xFFF0FDF4),
            value: '${dashboard.completedCount}',
            label: isAm ? 'የተጠናቀቁ' : 'Completed',
            sublabel: isAm ? 'ጠቅላላ' : 'Consults',
            onTap: () {
              ref.read(midwifeConsultTabProvider.notifier).state = 3; // Completed tab
              setState(() => selectedIndex = 2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    Color? valueColor,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE4EDE3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysAgendaSection(bool isDark, bool isAm, MidwifeDashboardData dashboard) {
    final todayList = dashboard.todayAppointments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(isAm ? 'የዛሬ ቀጠሮዎች' : "Today's Agenda"),
            if (todayList.isNotEmpty)
              TextButton(
                onPressed: () {
                  ref.read(midwifeConsultTabProvider.notifier).state = 2; // Today tab
                  setState(() => selectedIndex = 2);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isAm ? 'ሁሉንም ይመልከቱ (${todayList.length})' : 'See All (${todayList.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5EDE4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 22,
                    color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAm ? 'ዛሬ የተያዘ ቀጠሮ የለም' : 'No Consultations Scheduled Today',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAm
                            ? 'የዛሬ የተረጋገጡ የምክክር ቀጠሮዎች እዚህ ይታያሉ።'
                            : 'Your confirmed consultations for today will appear here.',
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
          )
        else
          ...todayList.take(2).map((apt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildConsultationCard(
                context,
                appointment: apt,
                onCompleted: () => ref.read(midwifeDashboardProvider.notifier).refresh(isSilent: true),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPracticeToolsSection(bool isDark, bool isAm, MidwifeDashboardData dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isAm ? 'የሙያ ሥራ መሣሪያዎች' : 'Practice Tools & Protocols'),
        const SizedBox(height: 12),

        // 1. Working Hours & Availability
        _buildPracticeActionCard(
          isDark: isDark,
          icon: Icons.schedule_rounded,
          iconBgColor: isDark ? const Color(0xFF1B3822) : const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          title: isAm ? 'የሥራ ሰዓት ማቀናበሪያ' : 'Working Hours & Availability',
          subtitle: isAm
              ? 'ደንበኞች ቀጠሮ የሚይዙባቸውን የሳምንቱ ሰዓቶች ያቀናብሩ'
              : 'Configure recurring daily consultation time slots',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
            ).then((_) {
              ref.read(midwifeDashboardProvider.notifier).refresh(isSilent: true);
            });
          },
        ),

        const SizedBox(height: 10),

        // 2. Client Messages
        _buildPracticeActionCard(
          isDark: isDark,
          icon: Icons.chat_bubble_outline_rounded,
          iconBgColor: isDark ? const Color(0xFF1E2E4A) : const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          title: isAm ? 'የደንበኞች መልዕክቶች' : 'Client Messages',
          subtitle: isAm
              ? 'ቀጥታ ሚስጥራዊ የጽሑፍ ውይይቶች'
              : 'Direct confidential messaging with clients',
          badgeText: dashboard.unreadMessagesCount > 0 ? '${dashboard.unreadMessagesCount} unread' : null,
          badgeColor: const Color(0xFFEF4444),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MidwifeInboxScreen()),
            ).then((_) {
              ref.read(midwifeDashboardProvider.notifier).refresh(isSilent: true);
            });
          },
        ),

        const SizedBox(height: 10),

        // 3. Clinical Guidelines & Protocol 2026
        _buildPracticeActionCard(
          isDark: isDark,
          icon: Icons.verified_user_outlined,
          iconBgColor: isDark ? const Color(0xFF2E2918) : const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFD97706),
          title: isAm ? 'የወጣቶች የጤና እንክብካቤ መመሪያ 2026' : 'Adolescent Care Protocol 2026',
          subtitle: isAm
              ? 'ክሊኒካዊ መመሪያዎች እና የምክር ደረጃዎች'
              : 'Official clinical standards for confidential care',
          onTap: () => _showProtocolDetailsModal(context),
        ),
      ],
    );
  }

  Widget _buildPracticeActionCard({
    required bool isDark,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE4EDE3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor ?? AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
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
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
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