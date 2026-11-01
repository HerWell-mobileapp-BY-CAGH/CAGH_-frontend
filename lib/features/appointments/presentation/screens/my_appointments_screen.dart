import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/appointments/presentation/widgets/sim_call_bottom_sheet.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_components.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final int initialTab;

  const MyAppointmentsScreen({
    super.key,
    this.initialTab = 1, // Default to Upcoming
  });

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late int _selectedTab;
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      _appointments = await _appointmentRepository.getUserAppointments();
      AppLogger.d('[MY APPOINTMENTS] Fetched ${_appointments.length} appointments');

      final missingNameIds = _appointments
          .where((a) => a.midwifeName == null)
          .map((a) => a.midwifeId)
          .toSet()
          .toList();

      if (missingNameIds.isNotEmpty) {
        final allMidwives = await MidwifeRepositoryImpl(MidwifeApiService()).getMidwives();
        for (var apt in _appointments) {
          if (apt.midwifeName == null) {
            final matches = allMidwives.where(
              (m) => m.id == apt.midwifeId || m.userId == apt.midwifeId,
            );
            if (matches.isNotEmpty) {
              apt.midwifeName = matches.first.fullName;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.d('Error loading appointments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPatientConsultation(BuildContext context, Appointment apt) {
    SimCallBottomSheet.show(context, apt);
  }

  Future<void> _updateStatus(String id, AppointmentStatus newStatus) async {
    try {
      if (newStatus == AppointmentStatus.cancelled) {
        await _appointmentRepository.cancelAppointment(id);
        if (mounted) CustomSnackBar.show(context, message: 'Appointment cancelled');
      }
      if (mounted) _fetchAppointments();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
        CustomSnackBar.show(
          context,
          message: errorMsg.isNotEmpty
              ? errorMsg
              : AppLocalizations.of(context)!.failedToUpdateStatus,
          isError: true,
        );
      }
    }
  }

  Future<void> _fetchAndShowDetails(Appointment apt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
    try {
      final detailedApt = await _appointmentRepository.getAppointmentDetails(apt.appointmentId);
      if (mounted) {
        Navigator.pop(context);
        showDetailsModal(context, detailedApt);
      }
    } catch (e) {
      AppLogger.d('DEBUG: getAppointmentDetails failed: $e');
      if (mounted) {
        Navigator.pop(context);
        showDetailsModal(context, apt);
      }
    }
  }

  List<Appointment> get _pendingList =>
      _appointments.where((a) => a.status == AppointmentStatus.pending && !a.isPast).toList();

  List<Appointment> get _upcomingList =>
      _appointments.where((a) => a.status == AppointmentStatus.confirmed && !a.isPast).toList();

  List<Appointment> get _pastList => _appointments.where((a) {
        return a.status == AppointmentStatus.completed ||
            (a.status == AppointmentStatus.confirmed && a.isPast);
      }).toList();

  List<Appointment> get _expiredList => _appointments.where((a) {
        return (a.status == AppointmentStatus.pending && a.isPast) ||
            a.status == AppointmentStatus.cancelled ||
            a.status == AppointmentStatus.declined ||
            a.status == AppointmentStatus.missed;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode.startsWith('am');

    final List<Appointment> currentList;
    final String emptyTitle;
    final String emptySubtitle;
    final IconData emptyIcon;

    if (_selectedTab == 0) {
      currentList = _pendingList;
      emptyTitle = l10n.noConsultationRequestsYet;
      emptySubtitle = l10n.emptyPendingAppointmentsSubtitle;
      emptyIcon = Icons.hourglass_empty_rounded;
    } else if (_selectedTab == 1) {
      currentList = _upcomingList;
      emptyTitle = l10n.noUpcomingConsultations;
      emptySubtitle = l10n.emptyUpcomingAppointmentsSubtitle;
      emptyIcon = Icons.calendar_today_outlined;
    } else if (_selectedTab == 2) {
      currentList = _pastList;
      emptyTitle = l10n.noPastConsultations;
      emptySubtitle = l10n.emptyPastAppointmentsSubtitle;
      emptyIcon = Icons.history_rounded;
    } else {
      currentList = _expiredList;
      emptyTitle = isAm ? 'ያለፈበት ቀጠሮ የለም' : 'No Expired Consultations';
      emptySubtitle = isAm
          ? 'ያለፉ ወይም ምላሽ ያልተሰጠባቸው የቀጠሮ ጥያቄዎች እዚህ ይታያሉ።'
          : 'Expired or unanswered consultation requests will appear here.';
      emptyIcon = Icons.history_toggle_off_rounded;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildInnerPageAppBar(
        context,
        title: l10n.myAppointments,
        showLanguage: true,
      ),
      body: Column(
        children: [
          // Segmented Tabs Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabItem(
                  context,
                  index: 0,
                  title: l10n.pendingRequests,
                  count: _pendingList.length,
                ),
                _buildTabItem(
                  context,
                  index: 1,
                  title: l10n.upcoming,
                  count: _upcomingList.length,
                ),
                _buildTabItem(
                  context,
                  index: 2,
                  title: l10n.past,
                  count: _pastList.length,
                ),
                _buildTabItem(
                  context,
                  index: 3,
                  title: isAm ? 'ያለፈባቸው' : 'Expired',
                  count: _expiredList.length,
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAppointments,
                    color: AppColors.primaryGreen,
                    child: currentList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSurfaceVariant
                                              : const Color(0xFFF0FDF4),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : const Color(0xFFDCFCE7),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          emptyIcon,
                                          size: 44,
                                          color: isDark
                                              ? AppColors.darkPrimary
                                              : AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        emptyTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        emptySubtitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : const Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: currentList.length,
                            itemBuilder: (context, index) {
                              final apt = currentList[index];
                              return buildAppointmentCard(
                                context,
                                apt,
                                onCardTap: () => _fetchAndShowDetails(apt),
                                onJoinCall: () => _startPatientConsultation(context, apt),
                                onChat: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        midwifeId: apt.midwifeId,
                                        midwifeName: apt.midwifeName ?? 'Midwife',
                                      ),
                                    ),
                                  );
                                },
                                onReschedule: () => showRescheduleModal(
                                  context,
                                  apt,
                                  onSuccess: _fetchAppointments,
                                ),
                                onCancel: () => showCancelConfirmDialog(
                                  context,
                                  apt,
                                  () async => _updateStatus(
                                      apt.appointmentId, AppointmentStatus.cancelled),
                                ),
                                onViewDetails: () => _fetchAndShowDetails(apt),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required String title,
    required int count,
  }) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? primaryColor
                            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkAccentYellow : AppColors.accentYellow)
                            : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (isDark ? Colors.black87 : AppColors.primaryGreen)
                              : (isDark ? AppColors.darkTextPrimary : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
