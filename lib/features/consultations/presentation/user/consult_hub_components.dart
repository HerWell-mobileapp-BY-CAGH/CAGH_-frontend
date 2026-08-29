import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

String formatAppointmentDateTime(String dateStr, String startTimeStr) {
  if (dateStr.isEmpty) return '';
  try {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      int hour = 9;
      int minute = 0;
      if (startTimeStr.isNotEmpty) {
        final tParts = startTimeStr.split(':');
        if (tParts.length >= 2) {
          hour = int.parse(tParts[0]);
          minute = int.parse(tParts[1]);
        }
      }

      final dt = DateTime(year, month, day, hour, minute);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      final weekday = weekdays[dt.weekday - 1];
      final monthStr = months[dt.month - 1];
      final dayNum = dt.day;
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
      final minuteStr = minute.toString().padLeft(2, '0');
      
      return '$weekday, $monthStr $dayNum · $formattedHour:$minuteStr $period';
    }
  } catch (_) {}
  return '$dateStr · $startTimeStr';
}

Color getStatusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return const Color(0xFFE65100);
    case AppointmentStatus.confirmed:
      return const Color(0xFF2E7D32);
    case AppointmentStatus.completed:
      return const Color(0xFF616161);
    case AppointmentStatus.cancelled:
    case AppointmentStatus.declined:
      return const Color(0xFFC62828);
    default:
      return Colors.grey;
  }
}

Widget buildStatusIndicator(AppointmentStatus status) {
  final dotColor = getStatusColor(status);
  String text = status.name.toUpperCase();
  if (status == AppointmentStatus.declined) text = 'DECLINED';
  if (status == AppointmentStatus.cancelled) text = 'CANCELLED';

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: dotColor,
          letterSpacing: 0.6,
        ),
      ),
    ],
  );
}

Widget detailRow(String label, String val) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
      ],
    ),
  );
}

void showRescheduleModal(BuildContext context, Appointment apt) {
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
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
                  'With ${apt.midwifeName ?? 'Midwife'}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 20),

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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 12),
                        Text(selectedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.primaryGreen,
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

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rescheduled to $selectedDate $selectedTime'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

void showDetailsModal(
  BuildContext context,
  Appointment apt, {
  VoidCallback? onReschedule,
  VoidCallback? onCancel,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final isCancelable = apt.status == AppointmentStatus.pending || apt.status == AppointmentStatus.confirmed;
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
            detailRow('Midwife', apt.midwifeName ?? 'Midwife'),
            detailRow('Date & Time', formatAppointmentDateTime(apt.date, apt.startTime)),
            detailRow('Status', apt.status.name.toUpperCase()),
            if (apt.reason != null && apt.reason!.isNotEmpty)
              detailRow('Reason', apt.reason!),
            const SizedBox(height: 16),
            if (isCancelable && (onReschedule != null || onCancel != null)) ...[
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onReschedule != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onReschedule();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Reschedule', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (onReschedule != null && onCancel != null)
                    const SizedBox(width: 12),
                  if (onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onCancel();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.errorRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Cancel Request', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      );
    },
  );
}

void showCancelConfirmDialog(BuildContext context, Appointment apt, VoidCallback onConfirmed) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 24),
            SizedBox(width: 10),
            Text('Cancel Appointment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Appointment', style: TextStyle(color: AppColors.primaryGreen)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirmed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

Widget buildMinimalTabBar({
  required int selectedIndex,
  required ValueChanged<int> onTabSelected,
}) {
  final tabs = ['Requests', 'Upcoming', 'Past'];
  return Container(
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    child: Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTabSelected(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryGreen : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

Widget buildAppointmentCard(
  BuildContext context,
  Appointment apt, {
  required VoidCallback onCardTap,
  required VoidCallback onJoinCall,
  required VoidCallback onReschedule,
  required VoidCallback onCancel,
  required VoidCallback onViewDetails,
}) {
  final isUpcoming = apt.status == AppointmentStatus.confirmed && !apt.isPast;
  final isPending = apt.status == AppointmentStatus.pending;
  final formattedDateTime = formatAppointmentDateTime(apt.date, apt.startTime);

  final String midwifeDisplayName = (apt.midwifeName != null &&
          apt.midwifeName!.trim().isNotEmpty &&
          apt.midwifeName!.trim().toLowerCase() != 'recipient')
      ? apt.midwifeName!.trim()
      : 'Midwife';

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

          // 2. Person Info (Midwife Name & Role)
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1F8E9),
                child: Text(
                  midwifeDisplayName.isNotEmpty ? midwifeDisplayName[0].toUpperCase() : 'M',
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
                      midwifeDisplayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Certified Midwife',
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
          if (isUpcoming) ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onJoinCall,
                  icon: const Icon(Icons.call_outlined, color: Colors.white, size: 15),
                  label: const Text('Join Call', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          ] else if (isPending) ...[
            TextButton(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
          ] else ...[
            TextButton(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
          ],
        ],
      ),
    ),
  );
}
