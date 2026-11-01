import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/providers/midwife_dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';
import 'package:cagh_frontend/features/appointments/presentation/widgets/sim_call_bottom_sheet.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_components.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_manage_schedule_screen.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class MidwifeConsultsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final int initialTab;
  const MidwifeConsultsScreen({
    super.key,
    this.showAppBar = false,
    this.initialTab = 1,
  });

  @override
  ConsumerState<MidwifeConsultsScreen> createState() => _MidwifeConsultsScreenState();
}

class _MidwifeConsultsScreenState extends ConsumerState<MidwifeConsultsScreen> {
  // 0 = Pending Requests, 1 = Confirmed, 2 = Today, 3 = Completed
  late int _selectedTab;

  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  bool _hasActiveHours = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchAppointments();
  }

  Future<void> _fetchAppointments({bool showLoading = true}) async {
    if (showLoading && _appointments.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        _appointmentRepository.getMidwifeAppointments(),
        _appointmentRepository.getAvailabilities().catchError((_) => <WorkingHours>[]),
      ]);
      final list = results[0] as List<Appointment>;
      final availList = results[1] as List<WorkingHours>;

      AppLogger.d('[BOOKING FETCH] Midwife fetched ${list.length} bookings, ${availList.length} availabilities');
      try { ref.read(midwifeDashboardProvider.notifier).refresh(isSilent: true); } catch (_) {}
      if (mounted) {
        setState(() {
          _appointments = list;
          _hasActiveHours = availList.any((a) => a.isActive);
        });
      }
    } catch (e) {
      AppLogger.d('Error loading consults: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, AppointmentStatus newStatus) async {
    try {
      if (newStatus == AppointmentStatus.cancelled) {
        await _appointmentRepository.cancelAppointment(id);
        if (mounted) CustomSnackBar.show(context, message: 'Appointment cancelled', type: SnackBarType.info);
      } else if (newStatus == AppointmentStatus.confirmed) {
        await _appointmentRepository.acceptAppointment(id);
        if (mounted) {
          CustomSnackBar.show(context, message: 'Appointment confirmed', isSuccess: true);
          setState(() => _selectedTab = 1);
        }
      } else if (newStatus == AppointmentStatus.declined) {
        await _appointmentRepository.declineAppointment(id);
        if (mounted) CustomSnackBar.show(context, message: 'Appointment declined', type: SnackBarType.warning);
      }
      _fetchAppointments(showLoading: false);
      try { ref.read(midwifeDashboardProvider.notifier).refresh(isSilent: true); } catch (_) {}
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
        CustomSnackBar.show(
          context,
          message: errorMsg.isNotEmpty ? errorMsg : (AppLocalizations.of(context)?.failedToUpdateStatus ?? 'Failed to update status'),
          isError: true,
        );
      }
    }
  }

  void _startConsultation(BuildContext context, Appointment apt) {
    SimCallBottomSheet.show(context, apt, isMidwifeCalling: true);
  }

  void _showMidwifeDetailsModal(BuildContext context, Appointment apt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final consultType = _formatConsultType(apt.appointmentType);

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.consultationDetails ?? 'Consultation Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                detailRow('Patient Name', apt.userFullName ?? AppLocalizations.of(context)?.patient ?? 'Patient'),
                detailRow('Consultation Type', consultType),
                detailRow('Date & Time', formatAppointmentDateTime(apt.date, apt.startTime, Localizations.localeOf(context).languageCode)),
                detailRow('Status', _formatStatusLabel(apt.status, apt.isPast)),
                if (apt.patientPhone != null && apt.patientPhone!.isNotEmpty)
                  detailRow('Phone Number', apt.patientPhone!),
                if (apt.reason != null && apt.reason!.isNotEmpty)
                  detailRow('Reason / Notes', apt.reason!),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatConsultType(String type) {
    switch (type.toUpperCase().trim()) {
      case 'VIRTUAL_VOICE':
        return 'Voice Call';
      case 'VIRTUAL_VIDEO':
        return 'Video Call';
      case 'IN_PERSON':
        return 'In Person';
      case 'CHAT':
        return 'Chat';
      default:
        if (type.isEmpty) return 'Consultation';
        return type
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  String _formatStatusLabel(AppointmentStatus status, bool isPast) {
    switch (status) {
      case AppointmentStatus.pending:
        return isPast ? 'Expired' : 'Pending';
      case AppointmentStatus.confirmed:
        return isPast ? 'Past' : 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.declined:
        return 'Declined';
      case AppointmentStatus.missed:
        return 'Missed';
      default:
        return status.name.toUpperCase();
    }
  }

  String _getSectionTitle(int tab) {
    switch (tab) {
      case 0:
        return 'Pending Requests';
      case 1:
        return 'Confirmed Schedule';
      case 2:
        return "Today's Schedule";
      case 3:
        return 'Completed Schedule';
      case 4:
      default:
        return 'Expired & Past Requests';
    }
  }

  List<Appointment> _getFilteredList() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final list = _appointments.where((a) {
      if (_selectedTab == 0) {
        // Active pending requests only (future dates)
        return a.status == AppointmentStatus.pending && !a.isPast;
      } else if (_selectedTab == 1) {
        return a.status == AppointmentStatus.confirmed && !a.isPast;
      } else if (_selectedTab == 2) {
        if (a.status == AppointmentStatus.cancelled || a.status == AppointmentStatus.declined) {
          return false;
        }
        if (a.date == todayStr) return true;
        final sdt = a.scheduledDateTime;
        if (sdt != null && sdt.year == now.year && sdt.month == now.month && sdt.day == now.day) {
          return true;
        }
        return false;
      } else if (_selectedTab == 3) {
        return a.status == AppointmentStatus.completed;
      } else {
        // Tab 4: Expired / Missed requests (past pending, missed, cancelled, declined, or past confirmed)
        return (a.status == AppointmentStatus.pending && a.isPast) ||
            a.status == AppointmentStatus.missed ||
            a.status == AppointmentStatus.cancelled ||
            a.status == AppointmentStatus.declined ||
            (a.status == AppointmentStatus.confirmed && a.isPast);
      }
    }).toList();

    list.sort((a, b) {
      final dtA = a.scheduledDateTime;
      final dtB = b.scheduledDateTime;
      if (dtA != null && dtB != null) {
        if (_selectedTab == 3 || _selectedTab == 4) {
          return dtB.compareTo(dtA);
        }
        return dtA.compareTo(dtB);
      }
      return 0;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(midwifeConsultTabProvider, (prev, next) {
      if (mounted && _selectedTab != next) {
        setState(() => _selectedTab = next);
      }
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAm = Localizations.localeOf(context).languageCode.startsWith('am');
    final filteredList = _getFilteredList();
    final pendingCount = _appointments.where((a) => a.status == AppointmentStatus.pending && !a.isPast).length;
    final expiredCount = _appointments.where((a) => (a.status == AppointmentStatus.pending && a.isPast) || a.status == AppointmentStatus.missed).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF7F9F7),
      appBar: widget.showAppBar
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF2C5927),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)?.consult ?? 'Consultations',
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
                        const GlobeLanguagePicker(iconColor: Colors.white),
                        const SizedBox(width: 6),
                        const NotificationBell(iconColor: Colors.white),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchAppointments,
              color: AppColors.primaryGreen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // 1. Status Card: Active & Available + Manage Hours
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: _buildActiveStatusCard(isDark),
                  ),

                  // 2. Filter Chips Row: Pending Requests, Confirmed, Today, Completed, Expired
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          tabIndex: 0,
                          label: isAm ? 'በመጠባበቅ ላይ' : 'Pending Requests',
                          badgeCount: pendingCount,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          tabIndex: 1,
                          label: isAm ? 'የተረጋገጡ' : 'Confirmed',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          tabIndex: 2,
                          label: isAm ? 'የዛሬ' : 'Today',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          tabIndex: 3,
                          label: isAm ? 'የተጠናቀቁ' : 'Completed',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          tabIndex: 4,
                          label: isAm ? 'ያለፈባቸው' : 'Expired',
                          badgeCount: expiredCount > 0 ? expiredCount : null,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // 3. Section Header: Accent bar + Title + Sorted by Time
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9822B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSectionTitle(_selectedTab),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Sorted by Time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Appointments List or Empty State
                  if (filteredList.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: filteredList.map((apt) => _buildAppointmentCard(apt, isDark)).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFEEF2F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Green / Amber Indicator Dot
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: _hasActiveHours ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_hasActiveHours ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hasActiveHours ? 'Active & Available' : 'Set Your Hours',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasActiveHours ? 'Ready for direct bookings' : 'Configure hours to receive bookings',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Manage Hours Pill Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MidwifeManageScheduleScreen(),
                  ),
                ).then((_) => _fetchAppointments(showLoading: false));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B3820) : const Color(0xFFEAF5EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2C5927),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Manage Hours',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2C5927),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required int tabIndex,
    required String label,
    int? badgeCount,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == tabIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedTab != tabIndex) {
            setState(() => _selectedTab = tabIndex);
            try { ref.read(midwifeConsultTabProvider.notifier).state = tabIndex; } catch (_) {}
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2C5927)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2C5927)
                  : (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2C5927).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade300 : const Color(0xFF334155)),
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5A93C),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment apt, bool isDark) {
    return buildAppointmentCard(
      context,
      apt,
      isProfessional: true,
      onCardTap: () => _showMidwifeDetailsModal(context, apt),
      onJoinCall: () => _startConsultation(context, apt),
      onReschedule: () => showRescheduleModal(
        context,
        apt,
        onSuccess: _fetchAppointments,
      ),
      onCancel: () => showCancelConfirmDialog(
        context,
        apt,
        () async => _updateStatus(apt.appointmentId, AppointmentStatus.cancelled),
      ),
      onViewDetails: () => _showMidwifeDetailsModal(context, apt),
      onChat: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MidwifeChatScreen(
              patientId: apt.userId,
              patientName: apt.userFullName ?? (AppLocalizations.of(context)?.patient ?? 'Patient'),
            ),
          ),
        );
      },
      onAccept: () => _updateStatus(apt.appointmentId, AppointmentStatus.confirmed),
      onDecline: () => _updateStatus(apt.appointmentId, AppointmentStatus.declined),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String emptyTitle;
    String emptySubtitle;
    IconData emptyIcon;

    switch (_selectedTab) {
      case 0:
        emptyTitle = 'No Pending Requests';
        emptySubtitle = 'New consultation requests from patients will appear here';
        emptyIcon = Icons.inbox_outlined;
        break;
      case 1:
        emptyTitle = 'No Confirmed Consultations';
        emptySubtitle = 'Your upcoming scheduled consultations will show up here';
        emptyIcon = Icons.event_available_outlined;
        break;
      case 2:
        emptyTitle = 'No Consultations Today';
        emptySubtitle = 'You have no consultations scheduled for today';
        emptyIcon = Icons.today_outlined;
        break;
      case 3:
        emptyTitle = 'No Completed Consultations';
        emptySubtitle = 'Past completed consultations will appear here';
        emptyIcon = Icons.history_outlined;
        break;
      case 4:
      default:
        emptyTitle = 'No Expired Requests';
        emptySubtitle = 'Expired or unanswered past requests will appear here';
        emptyIcon = Icons.history_toggle_off_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 34,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
