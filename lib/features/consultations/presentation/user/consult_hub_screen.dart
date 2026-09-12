import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_components.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class ConsultHubScreen extends StatefulWidget {
  final VoidCallback? onFindMidwifeTap;
  final bool isActive;

  const ConsultHubScreen({
    super.key,
    this.onFindMidwifeTap,
    this.isActive = false,
  });

  @override
  State<ConsultHubScreen> createState() => ConsultHubScreenState();
}

class ConsultHubScreenState extends State<ConsultHubScreen> {
  int _selectedTab = 1; // 0=Requests(PENDING), 1=Upcoming(CONFIRMED), 2=Past


  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  void didUpdateWidget(covariant ConsultHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      refreshAppointments();
    }
  }

  Future<void> refreshAppointments() async {
    await _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      _appointments = await _appointmentRepository.getUserAppointments();
      AppLogger.d('[BOOKING FETCH] Patient fetched ${_appointments.length} bookings');
      for (var apt in _appointments) {
        if (apt.status == AppointmentStatus.confirmed || apt.status == AppointmentStatus.pending) {
          GlobalCallService.init(apt.appointmentId);
          break;
        }
      }

      final missingNameIds = _appointments.where((a) => a.midwifeName == null).map((a) => a.midwifeId).toSet().toList();
      if (missingNameIds.isNotEmpty) {
        final allMidwives = await MidwifeApiService().getMidwives();
        for (var apt in _appointments) {
          if (apt.midwifeName == null) {
            final match = allMidwives.firstWhere(
              (m) => (m['id']?.toString() ?? '') == apt.midwifeId || (m['user']?['id']?.toString() ?? '') == apt.midwifeId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              apt.midwifeName = match['full_name'] ?? match['user']?['full_name'] ?? match['name'] ?? match['user']?['name'];
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

  bool _isJoiningCall = false;

  Future<void> _startPatientConsultation(BuildContext context, Appointment apt) async {
    if (_isJoiningCall) return;
    _isJoiningCall = true;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );

      final consultationApiService = ConsultationApiService();
      final sessionData = await consultationApiService.getConsultationByAppointment(apt.appointmentId);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        final consultId = sessionData['id']?.toString() ?? apt.appointmentId.toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceConsultationScreen(
              consultationId: consultId,
              midwifeName: apt.midwifeName ?? 'Midwife',
              phoneNumber: apt.midwifePhone ?? '',
              appointment: apt,
              isCaller: true,
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.d('Error starting consultation: $e');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unableToConnectConsultation),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isJoiningCall = false;
    }
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
          message: errorMsg.isNotEmpty ? errorMsg : AppLocalizations.of(context)!.failedToUpdateStatus,
          isError: true,
        );
      }
    }
  }

  Future<void> _fetchAndShowDetails(Appointment apt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _appointments.where((a) {
      if (_selectedTab == 0) {
        return a.status == AppointmentStatus.pending;
      } else if (_selectedTab == 1) {
        return a.status == AppointmentStatus.confirmed && !a.isPast;
      } else {
        return a.status == AppointmentStatus.completed ||
               a.status == AppointmentStatus.cancelled ||
               a.status == AppointmentStatus.declined ||
               a.status == AppointmentStatus.missed ||
               (a.status == AppointmentStatus.confirmed && a.isPast);
      }
    }).toList();

    String emptyMessage;
    if (_selectedTab == 0) {
      emptyMessage = AppLocalizations.of(context)!.noConsultationRequestsYet;
    } else if (_selectedTab == 1) {
      emptyMessage = AppLocalizations.of(context)!.noUpcomingConsultations;
    } else {
      emptyMessage = AppLocalizations.of(context)!.noPastConsultations;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Removed AppBar because it is now handled by the parent UserHomeScreen
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchAppointments,
              color: AppColors.primaryGreen,
              child: Column(
                children: [
                  if (widget.onFindMidwifeTap != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: GestureDetector(
                        onTap: widget.onFindMidwifeTap,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : AppColors.backgroundMintWhiteAlt,
                            gradient: isDark ? null : const LinearGradient(
                              colors: [AppColors.backgroundMintWhiteAlt, AppColors.backgroundMintWhite],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : AppColors.borderGreenGray,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_search_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentYellow,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.findAMidwife,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.primaryGreenDarker,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      AppLocalizations.of(context)!.connectWithCertifiedMidwife,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.grey.shade400 : AppColors.sageGrey,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  buildMinimalTabBar(
                    context: context,
                    selectedIndex: _selectedTab,
                    onTabSelected: (index) => setState(() => _selectedTab = index),
                  ),
                  Expanded(
                    child: filteredList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 80),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        emptyMessage,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
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
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final apt = filteredList[index];
                              return buildAppointmentCard(
                                context,
                                apt,
                                onCardTap: () => _fetchAndShowDetails(apt),
                                onJoinCall: () => _startPatientConsultation(context, apt),
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
                                onViewDetails: () => _fetchAndShowDetails(apt),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
