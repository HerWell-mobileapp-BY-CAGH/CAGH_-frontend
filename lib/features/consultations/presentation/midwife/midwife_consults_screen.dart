import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_components.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class MidwifeConsultsScreen extends StatefulWidget {
  final bool showAppBar;
  const MidwifeConsultsScreen({super.key, this.showAppBar = false});

  @override
  State<MidwifeConsultsScreen> createState() => _MidwifeConsultsScreenState();
}

class _MidwifeConsultsScreenState extends State<MidwifeConsultsScreen> {
  int _selectedTab = 1; // 0=Requests(PENDING), 1=Upcoming(CONFIRMED), 2=Past

  
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());
  List<Appointment> _appointments = [];
  List<dynamic> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments({bool showLoading = true}) async {
    if (showLoading && _appointments.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await _appointmentRepository.getMidwifeAppointments();
      AppLogger.d('[BOOKING FETCH] Midwife fetched ${list.length} bookings');
      if (mounted) {
        setState(() {
          _appointments = list;
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
      if (newStatus == AppointmentStatus.completed) {
         // Completed logic
      } else if (newStatus == AppointmentStatus.cancelled) {
         await _appointmentRepository.cancelAppointment(id);
         if (mounted) CustomSnackBar.show(context, message: 'Appointment cancelled', type: SnackBarType.info);
      } else if (newStatus == AppointmentStatus.confirmed) {
         await _appointmentRepository.acceptAppointment(id);
         if (mounted) {
           CustomSnackBar.show(context, message: 'Appointment confirmed', isSuccess: true);
           // Switch to Upcoming tab so confirmed appointment is shown immediately
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
          message: errorMsg.isNotEmpty ? errorMsg : AppLocalizations.of(context)!.failedToUpdateStatus,
          isError: true,
        );
      }
    }
  }

  bool _isJoiningCall = false;

  Future<void> _startConsultation(BuildContext context, Appointment apt) async {
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
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              appointment: apt,
              consultationId: consultId,
              isCaller: true,
            ),
          ),
        );
        if (result == true) {
          _fetchAppointments();
        }
      }
    } catch (e) {
      AppLogger.d('Error starting midwife consultation: $e');
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

  void _showMidwifeDetailsModal(BuildContext context, Appointment apt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String consultType = apt.appointmentType;
        if (consultType == 'VIRTUAL_VOICE' || consultType == 'VIRTUAL_VIDEO') consultType = 'Voice Call';
        if (consultType == 'IN_PERSON') consultType = AppLocalizations.of(context)!.inPerson;

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
                  Text(AppLocalizations.of(context)!.consultationDetails, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  IconButton(icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              SizedBox(height: 10),
              detailRow('Consultation Type', consultType),
              detailRow('Patient Name', apt.userFullName ?? AppLocalizations.of(context)!.patient),
              detailRow('Date & Time', formatAppointmentDateTime(apt.date, apt.startTime)),
              detailRow('Status', apt.status.name.toUpperCase()),
              if (apt.reason != null && apt.reason!.isNotEmpty)
                detailRow('Reason', apt.reason!),
              const SizedBox(height: 20),
            ],
          ),
          ),
        );
      },
    );
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
      emptyMessage = 'No consultation requests yet';
    } else if (_selectedTab == 1) {
      emptyMessage = 'No upcoming consultations';
    } else {
      emptyMessage = 'No past consultations';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Consultations',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchAppointments,
              color: AppColors.primaryGreen,
              child: Column(
                children: [
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
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final apt = filteredList[index];
                              return _buildAppointmentCard(apt);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentCard(Appointment apt) {
    final isUpcoming = apt.status == AppointmentStatus.confirmed && !apt.isPast;
    final isPending = apt.status == AppointmentStatus.pending;
    final formattedDateTime = formatAppointmentDateTime(apt.date, apt.startTime);

    final String patientDisplayName = (apt.userFullName != null &&
            apt.userFullName!.trim().isNotEmpty &&
            apt.userFullName!.trim().toLowerCase() != 'recipient')
        ? apt.userFullName!.trim()
        : AppLocalizations.of(context)!.patient;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Status Indicator & More Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildStatusIndicator(context, apt.status),
                if (isUpcoming)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color ?? const Color(0xFF64748B), size: 20),
                    tooltip: AppLocalizations.of(context)!.moreOptions,
                    onSelected: (value) {
                      if (value == 'reschedule') {
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
                        value: 'reschedule',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.primaryGreen),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context)!.reschedule, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'cancel',
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 18, color: AppColors.errorRed),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.errorRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Person Info (Patient Name & Role)
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF385A2E),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          patientDisplayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.seekHealthcare,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Date & Time Row
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  formattedDateTime,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Action Buttons (Max 2 visible actions)
            if (isPending) ...[
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.confirmed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(AppLocalizations.of(context)!.accept, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.declined),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(AppLocalizations.of(context)!.decline, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ] else if (isUpcoming) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startConsultation(context, apt),
                    icon: const Icon(Icons.call_outlined, color: Colors.white, size: 15),
                    label: Text(AppLocalizations.of(context)!.startCall, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                            patientName: apt.userFullName ?? AppLocalizations.of(context)!.patient,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGreen),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showMidwifeDetailsModal(context, apt),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(AppLocalizations.of(context)!.details, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ] else ...[
              TextButton(
                onPressed: () => _showMidwifeDetailsModal(context, apt),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(AppLocalizations.of(context)!.viewDetails, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasUnreadChat(Appointment apt) {
    for (var room in _chatRooms) {
      String? userId = room['user'] is Map ? room['user']['id']?.toString() : room['user']?.toString();
      String? patientId = room['patient'] is Map ? room['patient']['id']?.toString() : room['patient']?.toString();

      if (userId == apt.userId.toString() || patientId == apt.userId.toString() || room.toString().contains(apt.userId.toString())) {
        if (room['status'] == 'REQUESTED') return true;
        if (room['unread_count'] != null && (int.tryParse(room['unread_count'].toString()) ?? 0) > 0) return true;
      }
    }
    return false;
  }
}
