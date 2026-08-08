import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/appointment_service.dart';
import 'package:cagh_frontend/core/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/consultations/presentation/find_midwife_screen.dart';
import 'package:cagh_frontend/features/virtual_consultation/presentation/emergency_support_screen.dart';

class ConsultHubScreen extends StatefulWidget {
  final Function(String midwifeName)? onChatSelected;
  final VoidCallback? onFindMidwifeTap;

  const ConsultHubScreen({
    super.key,
    this.onChatSelected,
    this.onFindMidwifeTap,
  });

  @override
  State<ConsultHubScreen> createState() => _ConsultHubScreenState();
}

class _ConsultHubScreenState extends State<ConsultHubScreen> {
  bool _showUpcoming = true;

  void _showRescheduleModal(AppointmentItem apt) {
    String selectedDate = apt.date;
    String selectedTime = apt.time;
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
                          color: Color(0xFF274E13),
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
                    'With ${apt.midwifeName} (${apt.consultationType})',
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
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF274E13), size: 20),
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
                        selectedColor: const Color(0xFF274E13),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF274E13),
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
                        AppointmentService.rescheduleBooking(apt.id, selectedDate, selectedTime);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Appointment rescheduled to $selectedDate at $selectedTime'),
                            backgroundColor: const Color(0xFF274E13),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF274E13),
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

  void _showDetailsModal(AppointmentItem apt) {
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
                  const Text('Consultation Details', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF274E13))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _detailRow('Consultation Type', apt.consultationType),
              _detailRow('Midwife Specialist', apt.midwifeName),
              _detailRow('Date & Time', '${apt.date} at ${apt.time}'),
              _detailRow('Patient Name', apt.userFullName),
              _detailRow('Phone Contact', apt.userPhone),
              _detailRow('Status', apt.status),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onChatSelected != null) {
                      widget.onChatSelected!(apt.midwifeName);
                    }
                  },
                  icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                  label: const Text('Message Midwife', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF274E13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelConfirmDialog(AppointmentItem apt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
              SizedBox(width: 10),
              Text(
                'Cancel Appointment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Are you sure you want to cancel your appointment with',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Text(
                apt.midwifeName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF274E13),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${apt.date} · ${apt.time}',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Text(
                  'This action cannot be undone. You can book a new appointment anytime.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFB71C1C)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Keep Appointment',
                style: TextStyle(
                  color: Color(0xFF274E13),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                AppointmentService.cancelAppointment(apt.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Appointment cancelled successfully.'),
                      ],
                    ),
                    backgroundColor: const Color(0xFFD32F2F),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Consult',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const GlobeLanguagePicker(iconColor: Colors.amber),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.amber),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh Appointments')),
              const PopupMenuItem(value: 'help', child: Text('Consultation Help')),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AppointmentItem>>(
        valueListenable: AppointmentService.appointments,
        builder: (context, aptList, _) {
          final filteredList = _showUpcoming
              ? aptList.where((a) => a.status == 'UPCOMING').toList()
              : aptList.where((a) => a.status != 'UPCOMING').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar (Matching Screenshot)
                GestureDetector(
                  onTap: () {
                    if (widget.onFindMidwifeTap != null) {
                      widget.onFindMidwifeTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FindMidwifeScreen(
                            onMessageTap: (name) {
                              if (widget.onChatSelected != null) {
                                widget.onChatSelected!(name);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3EC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Search conversations...',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Section Header: START NEW CONSULTATION
                Text(
                  'START NEW CONSULTATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Find a Midwife Hero Card (Matching Screenshot)
                GestureDetector(
                  onTap: () {
                    if (widget.onFindMidwifeTap != null) {
                      widget.onFindMidwifeTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FindMidwifeScreen(
                            onMessageTap: (name) {
                              if (widget.onChatSelected != null) {
                                widget.onChatSelected!(name);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF274E13), Color(0xFF38682F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF274E13).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Circle Icon (Person + Search)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Find a Midwife',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Connect with professional caregivers\ninstantly for guidance and support.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                        // Yellow Online Status Indicator Dot
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF274E13), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Top Filter Header (Matching Screenshot input_file_0.png)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consultations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showUpcoming = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showUpcoming ? const Color(0xFF274E13) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Upcoming',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _showUpcoming ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showUpcoming = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showUpcoming ? const Color(0xFF274E13) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Past',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_showUpcoming ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Appointment Cards List
                if (filteredList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _showUpcoming ? 'No upcoming consultations' : 'No past consultations',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Book an appointment with a midwife below.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: filteredList.map((apt) {
                      return _buildAppointmentCard(apt);
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // Bottom Banner Card (Matching Screenshot input_file_0.png)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E3D2), // Sage green background
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          Icons.edit_calendar_outlined,
                          size: 90,
                          color: const Color(0xFF8F9E8A).withValues(alpha: 0.35),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need to see someone?',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3C3852),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Our midwives are available\nfor talk or visit any time.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.onFindMidwifeTap != null) {
                                  widget.onFindMidwifeTap!();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FindMidwifeScreen(
                                        onMessageTap: (name) {
                                          if (widget.onChatSelected != null) {
                                            widget.onChatSelected!(name);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF274E13),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                              ),
                              child: const Text(
                                'Book Appointment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentItem apt) {
    final isUpcoming = apt.status == 'UPCOMING';

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
              // Left Accent Line (Yellow for Upcoming matching screenshot)
              if (isUpcoming)
                Container(
                  width: 5,
                  color: const Color(0xFFFFC107), // Gold accent bar
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
                              color: isUpcoming ? const Color(0xFFFFC107) : const Color(0xFFEAEFE9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              isUpcoming ? 'UPCOMING' : 'Voice Call',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isUpcoming ? const Color(0xFF1A1A1A) : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        apt.consultationType,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF274E13),
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
                            child: Icon(Icons.person, color: Color(0xFF274E13), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apt.midwifeName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                apt.midwifeRole,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF274E13)),
                            const SizedBox(width: 6),
                            Text(
                              apt.date,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF274E13),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF274E13)),
                            const SizedBox(width: 6),
                            Text(
                              apt.time,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF274E13),
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
                                        if (widget.onChatSelected != null) {
                                          widget.onChatSelected!(apt.midwifeName);
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EmergencySupportScreen(),
                                            ),
                                          );
                                        }
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
                                        backgroundColor: const Color(0xFF274E13),
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
                            onPressed: () => _showDetailsModal(apt),
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
    );
  }
}
