import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/models/time_slot.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

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

Widget buildStatusIndicator(BuildContext context, AppointmentStatus status) {
  final dotColor = getStatusColor(status);
  final l10n = AppLocalizations.of(context);
  String text = status.name.toUpperCase();
  if (l10n != null) {
    switch (status) {
      case AppointmentStatus.pending:
        text = l10n.statusPending;
        break;
      case AppointmentStatus.confirmed:
        text = l10n.statusConfirmed;
        break;
      case AppointmentStatus.completed:
        text = l10n.statusCompleted;
        break;
      case AppointmentStatus.cancelled:
        text = l10n.statusCancelled;
        break;
      case AppointmentStatus.declined:
        text = l10n.statusDeclined;
        break;
    }
  }

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

void showRescheduleModal(
  BuildContext context,
  Appointment apt, {
  VoidCallback? onSuccess,
}) {
  DateTime selectedDate;
  try {
    selectedDate = DateTime.parse(apt.date);
    if (selectedDate.isBefore(DateTime.now())) {
      selectedDate = DateTime.now().add(const Duration(days: 1));
    }
  } catch (_) {
    selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  String? selectedStartTime;
  String? selectedEndTime;
  bool isLoadingSlots = true;
  bool isSubmitting = false;
  String? errorMessage;
  List<TimeSlot> availableSlots = [];
  bool hasFetchedInitial = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> fetchSlots(DateTime date) async {
            setModalState(() {
              isLoadingSlots = true;
              errorMessage = null;
              selectedStartTime = null;
              selectedEndTime = null;
            });
            try {
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final repo = AppointmentRepositoryImpl(AppointmentApiService());
              final slotsResp = await repo.getTimeSlots(apt.midwifeId, dateStr);
              final allSlots = [
                ...slotsResp.morningSlots,
                ...slotsResp.afternoonSlots,
                ...slotsResp.eveningSlots,
              ].where((s) => s.isAvailable).toList();

              setModalState(() {
                availableSlots = allSlots;
                isLoadingSlots = false;
              });
            } catch (e) {
              setModalState(() {
                isLoadingSlots = false;
                errorMessage = 'Failed to load time slots. Please try another date.';
              });
            }
          }

          if (!hasFetchedInitial) {
            hasFetchedInitial = true;
            fetchSlots(selectedDate);
          }

          Future<void> handleConfirm() async {
            if (selectedStartTime == null) {
              setModalState(() {
                errorMessage = 'Please select a new time slot.';
              });
              return;
            }
            if (isSubmitting) return;

            setModalState(() {
              isSubmitting = true;
              errorMessage = null;
            });

            try {
              final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
              final startT = selectedStartTime!.length == 5 ? '$selectedStartTime:00' : selectedStartTime!;
              final endT = selectedEndTime != null && selectedEndTime!.isNotEmpty
                  ? (selectedEndTime!.length == 5 ? '$selectedEndTime:00' : selectedEndTime!)
                  : startT;

              final repo = AppointmentRepositoryImpl(AppointmentApiService());
              await repo.rescheduleAppointment(
                appointmentId: apt.appointmentId,
                scheduledDate: dateStr,
                startTime: startT,
                endTime: endT,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment rescheduled to ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedStartTime'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                onSuccess?.call();
              }
            } catch (e) {
              final cleanMsg = '$e'.replaceAll('Exception: ', '');
              setModalState(() {
                isSubmitting = false;
                errorMessage = cleanMsg.isNotEmpty ? cleanMsg : 'Rescheduling failed. Please try again.';
              });
            }
          }

          final dateDisplay = DateFormat('EEE, MMM d, yyyy').format(selectedDate);

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.rescheduleAppointment,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'With ${apt.midwifeName ?? 'Midwife'}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    AppLocalizations.of(context)!.selectDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: isSubmitting ? null : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                        fetchSlots(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 12),
                          Text(dateDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    AppLocalizations.of(context)!.selectTimeSlot,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  if (isLoadingSlots)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      ),
                    )
                  else if (availableSlots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.noAvailableSlotsForDate,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableSlots.map((slot) {
                        final isSel = selectedStartTime == slot.startTime;
                        return ChoiceChip(
                          label: Text(slot.displayTime.isNotEmpty ? slot.displayTime : slot.startTime),
                          selected: isSel,
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: isSubmitting ? null : (sel) {
                            if (sel) {
                              setModalState(() {
                                selectedStartTime = slot.startTime;
                                selectedEndTime = slot.endTime;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (isSubmitting || selectedStartTime == null) ? null : handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              AppLocalizations.of(context)!.confirmReschedule,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
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
                Text(AppLocalizations.of(context)!.consultationDetails, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
              detailRow(AppLocalizations.of(context)!.consultationType, consultType),
              detailRow(AppLocalizations.of(context)!.yourMidwife, apt.midwifeName ?? 'Midwife'),
              detailRow(AppLocalizations.of(context)!.selectDate, formatAppointmentDateTime(apt.date, apt.startTime)),
              detailRow('Status', apt.status.name.toUpperCase()),
              if (apt.reason != null && apt.reason!.isNotEmpty)
                detailRow(AppLocalizations.of(context)!.reasonForVisit, apt.reason!),
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
                          child: Text(AppLocalizations.of(context)!.reschedule, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
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
                          child: Text(AppLocalizations.of(context)!.cancelRequest, style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void showCancelConfirmDialog(
  BuildContext context,
  Appointment apt,
  Future<void> Function() onConfirmed,
) {
  bool isCancelling = false;
  String? cancelError;

  showDialog(
    context: context,
    barrierDismissible: !isCancelling,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 24),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.cancelAppointment,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.areYouSureCancelAppointment),
                if (cancelError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    cancelError!,
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isCancelling ? null : () => Navigator.pop(dialogContext),
                child: Text(
                  AppLocalizations.of(context)!.keepAppointment,
                  style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: isCancelling
                    ? null
                    : () async {
                        setDialogState(() {
                          isCancelling = true;
                          cancelError = null;
                        });
                        try {
                          await onConfirmed();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          final clean = '$e'.replaceAll('Exception: ', '');
                          setDialogState(() {
                            isCancelling = false;
                            cancelError = clean.isNotEmpty ? clean : 'Failed to cancel appointment.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        AppLocalizations.of(context)!.cancelRequest,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget buildMinimalTabBar({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onTabSelected,
}) {
  final tabs = [
    AppLocalizations.of(context)!.pendingRequests,
    AppLocalizations.of(context)!.upcoming,
    AppLocalizations.of(context)!.past,
  ];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0), width: 1),
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
                  color: isSelected ? AppColors.primaryGreen : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
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

  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0), width: 1),
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
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                  tooltip: AppLocalizations.of(context)!.moreOptions,
                  onSelected: (value) {
                    if (value == 'reschedule') {
                      onReschedule();
                    } else if (value == 'cancel') {
                      onCancel();
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.certifiedMidwife,
                      style: const TextStyle(
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
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
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
                  label: Text(AppLocalizations.of(context)!.joinCall, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  child: Text(AppLocalizations.of(context)!.viewDetails, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
              child: Text(AppLocalizations.of(context)!.viewDetails, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
          ] else ...[
            TextButton(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(AppLocalizations.of(context)!.viewDetails, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
          ],
        ],
      ),
    ),
  );
}
