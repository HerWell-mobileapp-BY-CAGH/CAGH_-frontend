import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/find_midwife_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/voice_consultation_screen.dart';
import 'package:cagh_frontend/features/appointments/presentation/screens/appointment_details_screen.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'chat_screen.dart';

class ConsultHubScreen extends StatefulWidget {
  final VoidCallback? onFindMidwifeTap;

  const ConsultHubScreen({
    super.key,
    this.onFindMidwifeTap,
  });

  @override
  State<ConsultHubScreen> createState() => _ConsultHubScreenState();
}

class _ConsultHubScreenState extends State<ConsultHubScreen> {
  int _selectedTab = 1; // 0=Requests(PENDING), 1=Upcoming(CONFIRMED), 2=Past

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
      final rawAppointments = await AppointmentApiService().getUserAppointments();
      _appointments = rawAppointments.map((json) => Appointment.fromJson(json)).toList();
      
      // Workaround: Resolve missing midwife names
      final missingNameIds = _appointments.where((a) => a.midwifeName == null).map((a) => a.midwifeId).toSet().toList();
      if (missingNameIds.isNotEmpty) {
        final allMidwives = await MidwifeApiService().getMidwives();
        for (var apt in _appointments) {
          if (apt.midwifeName == null) {
            final match = allMidwives.firstWhere(
              (m) => (m['id']?.toString() ?? '') == apt.midwifeId || (m['user']?['id']?.toString() ?? '') == apt.midwifeId,
              orElse: () => null,
            );
            if (match != null) {
              apt.midwifeName = match['full_name'] ?? match['user']?['full_name'] ?? match['name'] ?? match['user']?['name'];
            }
          }
        }
      }
    } catch (e) {
      print('Error loading appointments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, AppointmentStatus newStatus) async {
    try {
      if (newStatus == AppointmentStatus.cancelled) {
        await _appointmentRepository.cancelAppointment(id);
      }
      _fetchAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRescheduleModal(Appointment apt) {
    String selectedDate = apt.date;
    String selectedTime = apt.startTime;
    final timeSlots = ['09:00 AM', '10:30 AM', '02:00 PM', '04:00 PM'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reschedule Appointment',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF315E26),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'With Midwife (ID: ${apt.midwifeId})',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Select New Date
                  const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        final months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                        ];
                        setModalState(() {
                          selectedDate = '${months[picked.month - 1]} ${picked.day}, ${picked.year}';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8F3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF315E26), size: 20),
                          const SizedBox(width: 12),
                          Text(selectedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Select Time Slot
                  const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: timeSlots.map((slot) {
                      final isSel = selectedTime == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSel,
                        selectedColor: const Color(0xFF315E26),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF315E26),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (sel) {
                          if (sel) {
                            setModalState(() {
                              selectedTime = slot;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Confirm Reschedule Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Stub out actual logic
                        // AppointmentService.rescheduleBooking(apt.id, selectedDate, selectedTime);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Rescheduled to $selectedDate $selectedTime'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315E26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text('Confirm Reschedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Future<void> _fetchAndShowDetails(Appointment apt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF315E26))),
    );
    try {
      final detailedApt = await _appointmentRepository.getAppointmentDetails(apt.appointmentId);
      if (mounted) {
        Navigator.pop(context); // Close loader
        _showDetailsModal(detailedApt);
      }
    } catch (e) {
      print('DEBUG: getAppointmentDetails failed: $e');
      if (mounted) {
        Navigator.pop(context); // Close loader
        _showDetailsModal(apt); // Fallback to basic details if fetch fails
      }
    }
  }

  void _showDetailsModal(Appointment apt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Consultation Details', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _detailRow('Consultation Type', apt.appointmentType),
              _detailRow('Midwife', apt.midwifeName ?? apt.midwifeId),
              _detailRow('Date & Time', '${apt.date} ${apt.startTime}'),
              _detailRow('Status', apt.status.name),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCancelConfirmDialog(Appointment apt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
              SizedBox(width: 10),
              Text('Cancel Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Appointment', style: TextStyle(color: Color(0xFF315E26))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _updateStatus(apt.appointmentId, AppointmentStatus.cancelled);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
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

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending: return Colors.orange;
      case AppointmentStatus.confirmed: return Colors.green;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _appointments.where((a) {
      if (_selectedTab == 0) return a.status == AppointmentStatus.pending;
      if (_selectedTab == 1) return a.status == AppointmentStatus.confirmed;
      return a.status == AppointmentStatus.cancelled || a.status == AppointmentStatus.completed;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
      backgroundColor: const Color(0xFF315E26),
        title: const Text('Consult', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search appointments...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // START NEW CONSULTATION Header
                Text(
                  'START NEW CONSULTATION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Find a Midwife Card
                GestureDetector(
                  onTap: widget.onFindMidwifeTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B6B2B), Color(0xFF4C7B38)], 
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_search, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Find a Midwife',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect with professional caregivers\ninstantly for guidance and support.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        // Yellow dot at the bottom right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD22B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // APPOINTMENTS Header
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
    final isUpcoming = apt.status == AppointmentStatus.confirmed;

    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointment: apt,
            ),
          ),
        );
        if (shouldRefresh == true) {
          _fetchAppointments();
        }
      },
      child: Container(
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
              // Left Accent Line (Color based on status)
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
                      // Badge + Phone Icon Row
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
                                      builder: (context) => ChatScreen(
                                        midwife: MidwifeProfile(
                                          id: apt.midwifeId,
                                          userId: apt.midwifeId,
                                          username: apt.midwifeName ?? 'Midwife',
                                          firstName: apt.midwifeName ?? 'Midwife',
                                          lastName: '',
                                          email: '',
                                          hospitalId: '',
                                          hospitalName: '',
                                          hospitalAddress: '',
                                          specialty: '',
                                          experienceYears: 0,
                                          languages: [],
                                          bio: '',
                                          offeredConsultationTypes: [],
                                          ratingAverage: 0,
                                          ratingCount: 0,
                                          isFavorite: false,
                                          isAcceptingBookings: false,
                                          consultationFee: '',
                                          verificationStatus: '',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.phone_outlined,
                                size: 20,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        'General Checkup', // Or map from apt if available
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF315E26),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Midwife Info Row
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFE8F5E9),
                            backgroundImage: AssetImage('assets/images/home_illustration.png'),
                            child: Icon(Icons.person, color: Color(0xFF315E26), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apt.midwifeName ?? 'Midwife',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Certified Midwife',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Date & Time Box (Matching Screenshot Box Design)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8F3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF315E26)),
                            const SizedBox(width: 6),
                            Text(
                              apt.date,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF315E26),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF315E26)),
                            const SizedBox(width: 6),
                            Text(
                              apt.startTime,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF315E26),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons (Join Call / Reschedule / Cancel)
                      if (isUpcoming)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VoiceConsultationScreen(
                                              consultationId: apt.appointmentId,
                                              midwifeName: apt.midwifeName ?? 'Midwife',
                                              phoneNumber: apt.midwifePhone ?? '', 
                                              isCaller: true,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.call, color: Colors.white, size: 16),
                                      label: const Text(
                                        'Join Call',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF315E26),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () => _showRescheduleModal(apt),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEAEFE9),
                                        foregroundColor: const Color(0xFF333333),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reschedule',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () => _showCancelConfirmDialog(apt),
                                icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFD32F2F)),
                                label: const Text(
                                  'Cancel Appointment',
                                  style: TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD32F2F), width: 1.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => _fetchAndShowDetails(apt),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }
}
