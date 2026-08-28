import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_components.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class MidwifeConsultsScreen extends StatefulWidget {
  const MidwifeConsultsScreen({super.key});

  @override
  State<MidwifeConsultsScreen> createState() => _MidwifeConsultsScreenState();
}

class _MidwifeConsultsScreenState extends State<MidwifeConsultsScreen> {
  int _selectedTab = 0; // 0=Requests(PENDING), 1=Upcoming(CONFIRMED), 2=Past
  
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      _appointments = await _appointmentRepository.getMidwifeAppointments();
      AppLogger.d('[BOOKING FETCH] Midwife fetched ${_appointments.length} bookings');
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
      } else if (newStatus == AppointmentStatus.confirmed) {
         await _appointmentRepository.acceptAppointment(id);
      } else if (newStatus == AppointmentStatus.declined) {
         await _appointmentRepository.declineAppointment(id);
      }
      _fetchAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startConsultation(BuildContext context, Appointment apt) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );

      final consultationApiService = ConsultationApiService();
      Map<String, dynamic>? sessionData;
      
      try {
        final existing = await consultationApiService.getConsultationsForAppointment(apt.appointmentId);
        if (existing.isNotEmpty) {
          sessionData = existing.first;
        }
      } catch (e) {
        AppLogger.d('Error checking existing consultations: $e');
      }

      sessionData ??= await consultationApiService.createConsultation(apt.appointmentId);
      
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
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start consultation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMidwifeDetailsModal(BuildContext context, Appointment apt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String consultType = apt.appointmentType;
        if (consultType == 'VIRTUAL_VOICE') consultType = 'Voice Call';
        if (consultType == 'IN_PERSON') consultType = 'In-person';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Consultation Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              detailRow('Consultation Type', consultType),
              detailRow('Patient Name', apt.userFullName ?? 'Patient'),
              detailRow('Date & Time', formatAppointmentDateTime(apt.date, apt.startTime)),
              detailRow('Status', apt.status.name.toUpperCase()),
              if (apt.reason != null && apt.reason!.isNotEmpty)
                detailRow('Reason', apt.reason!),
              const SizedBox(height: 20),
            ],
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Consultations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchAppointments,
              color: AppColors.primaryGreen,
              child: Column(
                children: [
                  buildMinimalTabBar(
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
        : 'Patient';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
            // 1. Status Indicator
            buildStatusIndicator(apt.status),
            const SizedBox(height: 14),

            // 2. Person Info (Patient Name & Role)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF1F8E9),
                  child: Text(
                    patientDisplayName.isNotEmpty ? patientDisplayName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Patient',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
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
                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.declined),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ] else if (isUpcoming) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startConsultation(context, apt),
                    icon: const Icon(Icons.call_outlined, color: Colors.white, size: 15),
                    label: const Text('Start Call', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _showMidwifeDetailsModal(context, apt),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
