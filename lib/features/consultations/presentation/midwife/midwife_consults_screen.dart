import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/consultations/presentation/providers/chat_notification_provider.dart';

class MidwifeConsultsScreen extends StatefulWidget {
  const MidwifeConsultsScreen({super.key});

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

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      _appointments = await _appointmentRepository.getMidwifeAppointments();
      _chatRooms = await ChatApiService.getChatRooms();
    } catch (e) {
      print('Error loading consults: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startConsultation(BuildContext context, Appointment apt) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF315E26))),
      );

      final consultationApiService = ConsultationApiService();
      Map<String, dynamic>? sessionData;
      
      try {
        final existing = await consultationApiService.getConsultationsForAppointment(apt.appointmentId);
        if (existing.isNotEmpty) {
          sessionData = existing.first as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error checking existing consultations: $e');
      }

      sessionData ??= await consultationApiService.createConsultation(apt.appointmentId);
      
      if (context.mounted) Navigator.pop(context); // Close dialog

      if (context.mounted) {
        final consultId = sessionData?['id']?.toString() ?? apt.appointmentId.toString();
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
      if (context.mounted) Navigator.pop(context); // Close dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start consultation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending: return Colors.orange;
      case AppointmentStatus.confirmed: return Colors.green;
      default: return Colors.red;
    }
  }

  Widget _buildTabItem(int index, String label) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF315E26) : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAF8),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF315E26))),
      );
    }

    final filteredList = _appointments.where((a) {
      if (_selectedTab == 0) return a.status == AppointmentStatus.pending;
      if (_selectedTab == 1) return a.status == AppointmentStatus.confirmed;
      return a.status == AppointmentStatus.cancelled || a.status == AppointmentStatus.completed || a.status == AppointmentStatus.declined;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315E26),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Digital Midwife',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFFFFD22B), size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'APPOINTMENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                letterSpacing: 1.2,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabItem(0, 'Requests'),
                _buildTabItem(1, 'Upcoming'),
                _buildTabItem(2, 'Past'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (filteredList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No appointments found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredList.map((apt) => _buildAppointmentCard(apt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment apt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Line
              Container(
                width: 5,
                color: _getStatusColor(apt.status),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(apt.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              apt.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(apt.status),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MidwifeChatScreen(appointment: apt),
                                    ),
                                  );
                                },
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final unreadMap = ref.watch(chatNotificationProvider);
                                    // Use the patient's ID to check for unread messages with this specific patient
                                    final unreadCount = unreadMap['user_${apt.userId}'] ?? 0;
                                    
                                    Widget icon = Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 20,
                                      color: Colors.grey.shade700,
                                    );
                                    
                                    if (unreadCount > 0) {
                                      return Badge(
                                        label: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount', 
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                                        ),
                                        backgroundColor: Colors.red,
                                        child: icon,
                                      );
                                    }
                                    return icon;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _startConsultation(context, apt),
                                child: Icon(Icons.phone_outlined, size: 20, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title & Patient Info
                      Text(
                        (apt.reason != null && apt.reason!.trim().isNotEmpty) 
                            ? apt.reason! 
                            : 'General Checkup',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF315E26),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              apt.userFullName ?? 'Patient',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),

                      // Date and Time Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                apt.date,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                apt.startTime,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Action Buttons
                      if (_selectedTab == 0) // Requests
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.declined),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD32F2F)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text('Decline', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(apt.appointmentId, AppointmentStatus.confirmed),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF315E26),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      else if (_selectedTab == 1) // Upcoming
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _startConsultation(context, apt),
                                icon: const Icon(Icons.videocam, color: Colors.white, size: 18),
                                label: const Text('Join Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF315E26),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Reschedule logic placeholder
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEAEFE9),
                                  foregroundColor: const Color(0xFF333333),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                child: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      else // Past
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('View Summary', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        if (room['unread_count'] != null && (room['unread_count'] as num) > 0) return true;
      }
    }
    return false;
  }
}
