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
import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';

class MidwifeConsultsScreen extends StatefulWidget {
  final bool showAppBar;
  final int initialTab;
  const MidwifeConsultsScreen({
    super.key,
    this.showAppBar = false,
    this.initialTab = 1,
  });

  @override
  State<MidwifeConsultsScreen> createState() => _MidwifeConsultsScreenState();
}

class _MidwifeConsultsScreenState extends State<MidwifeConsultsScreen> {
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

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'P';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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

  String _formatCardDateTime(Appointment apt) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isAm = currentLocale.startsWith('am');
    final dt = apt.scheduledDateTime;
    if (dt != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final aptDate = DateTime(dt.year, dt.month, dt.day);
      final diffDays = aptDate.difference(today).inDays;

      final timeStr = EthiopianDateHelper.formatEthiopianTime('${dt.hour}:${dt.minute}', locale: currentLocale);
      if (diffDays == 0) {
        return '${isAm ? 'ዛሬ' : 'Today'} · $timeStr';
      } else if (diffDays == -1) {
        return isAm ? 'ትናንት' : 'Yesterday';
      } else if (diffDays == 1) {
        return '${isAm ? 'ነገ' : 'Tomorrow'} · $timeStr';
      } else {
        return '${EthiopianDateHelper.formatEthiopianDate(dt, locale: currentLocale)} · $timeStr';
      }
    }
    return formatAppointmentDateTime(apt.date, apt.startTime, currentLocale);
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
                        Text(
                          AppLocalizations.of(context)?.consult ?? 'Consultations',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        const GlobeLanguagePicker(iconColor: Colors.white, iconSize: 22),
                        const SizedBox(width: 10),
                        const NotificationBell(iconColor: Colors.white),
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
    final isUpcoming = apt.status == AppointmentStatus.confirmed && !apt.isPast;
    final isPending = apt.status == AppointmentStatus.pending && !apt.isPast;
    final isExpiredPending = apt.status == AppointmentStatus.pending && apt.isPast;

    final String patientDisplayName = (apt.userFullName != null &&
            apt.userFullName!.trim().isNotEmpty &&
            apt.userFullName!.trim().toLowerCase() != 'recipient')
        ? apt.userFullName!.trim()
        : (AppLocalizations.of(context)?.patient ?? 'Patient');

    String topicSuffix = '';
    if (apt.reason != null && apt.reason!.trim().isNotEmpty && apt.reason!.trim().length <= 25) {
      topicSuffix = ' (${apt.reason!.trim()})';
    } else if (apt.appointmentType.trim().isNotEmpty) {
      topicSuffix = ' (${_formatConsultType(apt.appointmentType)})';
    }

    final dateTimeAndStatus = '${_formatCardDateTime(apt)} • ${_formatStatusLabel(apt.status, apt.isPast)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Title/Date + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF243326) : const Color(0xFFEFF3F8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(patientDisplayName),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$patientDisplayName$topicSuffix',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateTimeAndStatus,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(apt, isDark),
              ],
            ),

            // Action Buttons
            if (isExpiredPending) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF7C4A15) : const Color(0xFFFFEDD5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode.startsWith('am')
                            ? 'የቀጠሮው ቀንና ሰዓት ያለፈ በመሆኑ ምላሽ አልተሰጠበትም'
                            : 'Request expired: scheduled time passed without confirmation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showMidwifeDetailsModal(context, apt),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(
                    AppLocalizations.of(context)?.viewDetails ?? 'View Details',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ] else if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.confirmed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5927),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.accept ?? 'Accept',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.declined),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.decline ?? 'Decline',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showMidwifeDetailsModal(context, apt),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.details ?? 'Details',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ] else if (isUpcoming) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startConsultation(context, apt),
                    icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 16),
                    label: const Text(
                      'Call Patient (SIM)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5927),
                      elevation: 1,
                      shadowColor: const Color(0xFF2C5927).withOpacity(0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
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
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2C5927)),
                    tooltip: 'Chat',
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      size: 20,
                    ),
                    tooltip: AppLocalizations.of(context)?.moreOptions ?? 'More Options',
                    onSelected: (value) {
                      if (value == 'details') {
                        _showMidwifeDetailsModal(context, apt);
                      } else if (value == 'reschedule') {
                        showRescheduleModal(
                          context,
                          apt,
                          onSuccess: _fetchAppointments,
                        );
                      } else if (value == 'cancel') {
                        showCancelConfirmDialog(
                          context,
                          apt,
                          () async => _updateStatus(apt.appointmentId, AppointmentStatus.cancelled),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Color(0xFF2C5927)),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context)?.details ?? 'Details', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'reschedule',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_calendar_outlined, size: 18, color: Color(0xFF2C5927)),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context)?.reschedule ?? 'Reschedule', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'cancel',
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 18, color: AppColors.errorRed),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)?.cancel ?? 'Cancel',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.errorRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showMidwifeDetailsModal(context, apt),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.viewDetails ?? 'View Details',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(Appointment apt, bool isDark) {
    String label;
    Color bg;
    Color text;

    if (apt.status == AppointmentStatus.completed || (apt.status == AppointmentStatus.confirmed && apt.isPast)) {
      label = 'Finished';
      bg = isDark ? const Color(0xFF334155) : const Color(0xFFEFF3F8);
      text = isDark ? Colors.grey.shade300 : const Color(0xFF475569);
    } else if (apt.status == AppointmentStatus.confirmed) {
      label = 'Confirmed';
      bg = isDark ? const Color(0xFF1B3820) : const Color(0xFFE8F5E9);
      text = isDark ? const Color(0xFF86EFAC) : const Color(0xFF2E7D32);
    } else if (apt.status == AppointmentStatus.pending) {
      if (apt.isPast) {
        label = Localizations.localeOf(context).languageCode.startsWith('am') ? 'ያለፈበት' : 'Expired';
        bg = isDark ? const Color(0xFF332014) : const Color(0xFFFFF3E0);
        text = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      } else {
        label = 'Pending';
        bg = isDark ? const Color(0xFF3E2C10) : const Color(0xFFFFF8E1);
        text = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
      }
    } else if (apt.status == AppointmentStatus.cancelled) {
      label = 'Cancelled';
      bg = isDark ? const Color(0xFF3A1717) : const Color(0xFFFFEBEE);
      text = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    } else if (apt.status == AppointmentStatus.declined) {
      label = 'Declined';
      bg = isDark ? const Color(0xFF3A1717) : const Color(0xFFFFEBEE);
      text = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    } else {
      label = apt.status.name.toUpperCase();
      bg = isDark ? const Color(0xFF334155) : const Color(0xFFEFF3F8);
      text = isDark ? Colors.grey.shade300 : const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
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
