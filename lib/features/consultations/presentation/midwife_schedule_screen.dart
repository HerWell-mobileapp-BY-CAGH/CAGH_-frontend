import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/appointment_service.dart';

class MidwifeScheduleScreen extends StatefulWidget {
  const MidwifeScheduleScreen({super.key});

  @override
  State<MidwifeScheduleScreen> createState() => _MidwifeScheduleScreenState();
}

class _MidwifeScheduleScreenState extends State<MidwifeScheduleScreen> {
  void _openStartSessionModal(BuildContext context, String patientName, String consultType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF1B5E20),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 28),
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.person, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 16),
              Text(
                patientName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$consultType • Live Video Stream',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 12),
                    SizedBox(width: 6),
                    Text(
                      '00:04:12 • HD Encrypted',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCallActionBtn(Icons.mic_off_outlined, 'Mute', () {}),
                    _buildCallActionBtn(Icons.volume_up_outlined, 'Speaker', () {}),
                    _buildCallActionBtn(Icons.switch_camera_outlined, 'Flip', () {}),
                    _buildCallActionBtn(
                      Icons.call_end,
                      'End Session',
                      () => Navigator.pop(context),
                      bgColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallActionBtn(IconData icon, String label, VoidCallback onTap, {Color? bgColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: bgColor ?? Colors.white24,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showHealthRecordsModal(BuildContext context, String patientName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, color: Color(0xFF1B5E20), size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$patientName\'s Health Records',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Verified EHR & Vitals Sync',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _recordTile('Blood Pressure History', '118/76 mmHg (Today, 09:15 AM) • Normal Range', Icons.favorite_outline),
                  _recordTile('Weight Tracker', '62.4 kg (+4.2 kg overall since Week 12)', Icons.monitor_weight_outlined),
                  _recordTile('Fetal Heart Rate Log', '144 bpm • Regular Rhythm (Ultrasonic Doppler)', Icons.healing_outlined),
                  _recordTile('Glucose Screening Prep', 'Scheduled for Next Week (Week 25 Routine)', Icons.bloodtype_outlined),
                  _recordTile('Past Ultrasound Scans', '20-Week Anomaly Scan • Normal Fetal Growth & Placenta', Icons.image_outlined),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Close Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _recordTile(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1B5E20), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleModal(BuildContext context, AppointmentItem apt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reschedule Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Select a new date and time for ${apt.userFullName}\'s consultation.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                title: const Text('Tomorrow, 10:30 AM'),
                onTap: () {
                  AppointmentService.rescheduleBooking(apt.id, 'Tomorrow', '10:30 AM');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment rescheduled to Tomorrow, 10:30 AM'), backgroundColor: Colors.green),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Color(0xFF1B5E20)),
                title: const Text('Friday, 02:00 PM'),
                onTap: () {
                  AppointmentService.rescheduleBooking(apt.id, 'Friday', '02:00 PM');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment rescheduled to Friday, 02:00 PM'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppointmentItem>>(
      valueListenable: AppointmentService.appointments,
      builder: (context, aptList, _) {
        final upcomingApts = aptList.where((a) => a.status == 'UPCOMING').toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAF8),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Appointment Detail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFFFFC107), size: 26),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: upcomingApts.isEmpty
              ? _buildEmptyScheduleState()
              : _buildAppointmentDetailView(upcomingApts.first),
          floatingActionButton: upcomingApts.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 70),
                  child: FloatingActionButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Clinical AI Prep Assistant...')),
                      );
                    },
                    backgroundColor: const Color(0xFF5B3E7A),
                    elevation: 4,
                    child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyScheduleState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F6F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 40,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Scheduled Appointments Today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'When patients book consultations, their pre-consultation notes, gestation details, and session actions will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    AppointmentService.loadDemoData();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Load Demo Appointment (Maya Chen)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetailView(AppointmentItem apt) {
    final patientName = apt.userFullName;
    final patientNote = apt.note ??
        "I've been experiencing some mild cramping in the evenings and wanted to discuss if this is normal for 24 weeks. Also, I'm feeling a bit anxious about the upcoming glucose test next week.";
    final consultType = apt.consultationType;
    final timeStr = apt.time;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Patient Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Box
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF1A1A1A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFC8E6C9)),
                                ),
                                child: const Text(
                                  'Confirmed',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '19 years old • 24 Weeks Gestation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 18),

                // Details Row: TIME & TYPE
                Row(
                  children: [
                    // TIME Column
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: Color(0xFF1B5E20),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TIME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // TYPE Column
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.videocam_outlined,
                              color: Color(0xFF1B5E20),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TYPE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                consultType,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Link: View User Health Records
                GestureDetector(
                  onTap: () => _showHealthRecordsModal(context, patientName),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: Color(0xFF1B5E20),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'View User Health Records',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pre-Consultation Prep Title
          const Text(
            'Pre-Consultation Prep',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 12),

          // Patient-Provided Notes Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Color(0xFF5B3E7A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Patient-Provided Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B3E7A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"$patientNote"',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Status Badges / Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Low Risk Pregnancy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Low Risk Pregnancy',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Vitals Logged (Today)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Vitals Logged (Today)',
                  style: TextStyle(
                    color: Color(0xFF6B21A8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Mental Health: Good
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mental Health: Good',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Action 1: Start Session Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openStartSessionModal(context, patientName, consultType),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
              label: const Text(
                'Start Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action 2: Reschedule & Cancel Row
          Row(
            children: [
              // Reschedule Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRescheduleModal(context, apt),
                    icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1A1A1A), size: 18),
                    label: const Text(
                      'Reschedule',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Cancel Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppointmentService.updateStatus(apt.id, 'CANCELLED');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment cancelled')),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 90), // Bottom bar padding
        ],
      ),
    );
  }
}
