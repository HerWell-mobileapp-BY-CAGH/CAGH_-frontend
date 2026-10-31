import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/models/time_slot.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';

String formatAppointmentDateTime(String dateStr, String startTimeStr, [String? locale]) {
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
      final isAm = (locale ?? '').toLowerCase().startsWith('am');

      if (isAm) {
        final ethDate = EthiopianDate.fromGregorian(dt);
        final ethMonth = ethDate.getMonthName('am');
        final ethTime = EthiopianDateHelper.formatEthiopianTime(
          '$hour:${minute.toString().padLeft(2, '0')}',
          locale: 'am',
        );
        return '$ethMonth ${ethDate.day}, ${ethDate.year} · $ethTime';
      }

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

Widget buildStatusIndicator(BuildContext context, AppointmentStatus status, {bool isPast = false}) {
  Color dotColor = getStatusColor(status);
  final l10n = AppLocalizations.of(context);
  final isAm = Localizations.localeOf(context).languageCode.startsWith('am');
  String text = status.name.toUpperCase();

  if (status == AppointmentStatus.pending && isPast) {
    dotColor = const Color(0xFFC2410C);
    text = isAm ? 'ያለፈበት' : 'EXPIRED';
  } else if (l10n != null) {
    switch (status) {
      case AppointmentStatus.pending:
        text = l10n.statusPending;
        break;
      case AppointmentStatus.confirmed:
        text = isPast ? 'PAST' : l10n.statusConfirmed;
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
      case AppointmentStatus.missed:
        text = 'MISSED';
        break;
      case AppointmentStatus.unknown:
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
                        AppLocalizations.of(context)!.reschedule,
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
                    'With ${apt.midwifeName ?? 'Health Professional'}',
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
                        AppLocalizations.of(context)!.noSlotsAvailableForDay,
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
              detailRow(AppLocalizations.of(context)!.yourMidwife, apt.midwifeName ?? 'Health Professional'),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryGreen : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                    ),
                  ),
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
  VoidCallback? onChat,
  bool isProfessional = false,
  VoidCallback? onAccept,
  VoidCallback? onDecline,
}) {
  return AppointmentCardWidget(
    appointment: apt,
    onCardTap: onCardTap,
    onJoinCall: onJoinCall,
    onReschedule: onReschedule,
    onCancel: onCancel,
    onViewDetails: onViewDetails,
    onChat: onChat,
    isProfessional: isProfessional,
    onAccept: onAccept,
    onDecline: onDecline,
  );
}

enum _ConsultationModality { cellularVoice, chat, inPerson }
enum _CallWindowState { active, upcoming, completed, missed, cancelled, pending, expiredPending, concluded }

class AppointmentCardWidget extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onCardTap;
  final VoidCallback onJoinCall;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback onViewDetails;
  final VoidCallback? onChat;
  final bool isProfessional;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const AppointmentCardWidget({
    super.key,
    required this.appointment,
    required this.onCardTap,
    required this.onJoinCall,
    required this.onReschedule,
    required this.onCancel,
    required this.onViewDetails,
    this.onChat,
    this.isProfessional = false,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<AppointmentCardWidget> createState() => _AppointmentCardWidgetState();
}

class _AppointmentCardWidgetState extends State<AppointmentCardWidget> {
  Timer? _countdownTimer;
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    _parseTimes();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AppointmentCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointment.date != widget.appointment.date ||
        oldWidget.appointment.startTime != widget.appointment.startTime ||
        oldWidget.appointment.endTime != widget.appointment.endTime ||
        oldWidget.appointment.status != widget.appointment.status) {
      _parseTimes();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _parseTimes() {
    _startDateTime = _parseDateTime(widget.appointment.date, widget.appointment.startTime);
    _endDateTime = _parseEndDateTime(widget.appointment.date, widget.appointment.startTime, widget.appointment.endTime);
  }

  DateTime? _parseDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty) return null;
    try {
      final dParts = dateStr.split('-');
      if (dParts.length < 3) return null;
      final year = int.parse(dParts[0]);
      final month = int.parse(dParts[1]);
      final day = int.parse(dParts[2]);

      int hour = 9;
      int minute = 0;
      if (timeStr.isNotEmpty) {
        final clean = timeStr.trim().toUpperCase();
        final isPm = clean.contains('PM');
        final isAm = clean.contains('AM');
        final raw = clean.replaceAll(RegExp(r'[^\d:]'), '');
        final tParts = raw.split(':');
        if (tParts.isNotEmpty) {
          hour = int.tryParse(tParts[0]) ?? 9;
          if (tParts.length > 1) {
            minute = int.tryParse(tParts[1]) ?? 0;
          }
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      }
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseEndDateTime(String dateStr, String startStr, String endStr) {
    if (endStr.isNotEmpty) {
      final parsed = _parseDateTime(dateStr, endStr);
      if (parsed != null) return parsed;
    }
    final start = _parseDateTime(dateStr, startStr);
    if (start != null) {
      return start.add(const Duration(minutes: 30));
    }
    return null;
  }

  _ConsultationModality _getModality() {
    final type = widget.appointment.appointmentType.toUpperCase().trim();
    if (type.contains('IN_PERSON') || type.contains('IN-PERSON') || type.contains('PHYSICAL') || type.contains('CLINIC')) {
      return _ConsultationModality.inPerson;
    }
    if (type.contains('CHAT') || type.contains('MESSAGE') || type.contains('MESSAGING')) {
      return _ConsultationModality.chat;
    }
    return _ConsultationModality.cellularVoice;
  }

  _CallWindowState _getWindowState() {
    final apt = widget.appointment;
    final eligibility = apt.callEligibility;
    if (eligibility != null) {
      if (eligibility['can_call'] == true || eligibility['is_call_window_active'] == true) {
        return _CallWindowState.active;
      }
      final ws = eligibility['window_state']?.toString().toUpperCase();
      if (ws == 'ACTIVE') return _CallWindowState.active;
      if (ws == 'UPCOMING') return _CallWindowState.upcoming;
      if (ws == 'MISSED' || ws == 'EXPIRED') return _CallWindowState.missed;
      if (ws == 'CLOSED') return _CallWindowState.completed;
    }

    if (apt.status == AppointmentStatus.completed) return _CallWindowState.completed;
    if (apt.status == AppointmentStatus.missed) return _CallWindowState.missed;
    if (apt.status == AppointmentStatus.cancelled || apt.status == AppointmentStatus.declined) {
      return _CallWindowState.cancelled;
    }
    if (apt.status == AppointmentStatus.pending) {
      return apt.isPast ? _CallWindowState.expiredPending : _CallWindowState.pending;
    }

    if (_startDateTime == null) {
      return apt.isPast ? _CallWindowState.concluded : _CallWindowState.upcoming;
    }

    final now = DateTime.now();
    final activeStart = _startDateTime!.subtract(const Duration(minutes: 5));
    final activeEnd = _endDateTime ?? _startDateTime!.add(const Duration(minutes: 30));

    if (now.isBefore(activeStart)) {
      return _CallWindowState.upcoming;
    } else if (now.isAfter(activeEnd)) {
      return _CallWindowState.concluded;
    } else {
      return _CallWindowState.active;
    }
  }

  String _formatTime12h(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final mStr = minute.toString().padLeft(2, '0');
    return '$h12:$mStr $period';
  }

  String _getCarrierName() {
    final phone = widget.isProfessional ? widget.appointment.patientPhone : widget.appointment.midwifePhone;
    final backendCarrier = widget.appointment.callEligibility?['carrier']?.toString();
    if (backendCarrier != null && backendCarrier.isNotEmpty) return backendCarrier;
    if (phone == null || phone.isEmpty) return 'Cellular Network';
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.contains('9') && (clean.startsWith('09') || clean.startsWith('2519'))) {
      return 'Ethio Telecom';
    }
    if (clean.contains('7') && (clean.startsWith('07') || clean.startsWith('2517'))) {
      return 'Safaricom';
    }
    return 'Cellular Network';
  }

  String _getCountdownOrCallMessage(BuildContext context, bool isAm) {
    if (_startDateTime == null) {
      final t = widget.appointment.startTime;
      return isAm ? 'ጥሪው በ $t ክፍት ይሆናል' : 'Call available at $t';
    }

    final now = DateTime.now();
    final diff = _startDateTime!.difference(now);

    if (diff.isNegative) {
      return isAm ? 'የጥሪ መስመር ክፍት ነው' : 'Call Window Open Now';
    }

    if (diff.inMinutes <= 5) {
      return isAm ? 'ጥሪው አሁን ይጀምራል (ከ 5 ደቂቃ በታች)' : 'Call starting in less than 5 mins';
    } else if (diff.inMinutes < 60) {
      return isAm
          ? 'ጥሪው በ ${diff.inMinutes} ደቂቃ ውስጥ ይጀምራል'
          : 'Call available in ${diff.inMinutes} mins';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final timeStr = _formatTime12h(_startDateTime!);
      return isAm
          ? 'ጥሪው በ $timeStr ይጀምራል ($h ሰዓት${m > 0 ? " $m ደ" : ""})'
          : 'Call available at $timeStr (${h}h${m > 0 ? " ${m}m" : ""})';
    } else {
      final timeStr = _formatTime12h(_startDateTime!);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final w = weekdays[_startDateTime!.weekday - 1];
      final m = months[_startDateTime!.month - 1];
      final d = _startDateTime!.day;
      return isAm
          ? 'ጥሪው በ $m $d በ $timeStr ክፍት ይሆናል'
          : 'Call available on $w, $m $d at $timeStr';
    }
  }

  void _showCallLockedNotice(BuildContext context, String timeStr) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Direct cellular call opens at $timeStr when your appointment starts.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAm = Localizations.localeOf(context).languageCode.startsWith('am');
    final apt = widget.appointment;
    final modality = _getModality();
    final windowState = _getWindowState();
    final formattedDateTime = formatAppointmentDateTime(apt.date, apt.startTime, isAm ? 'am' : 'en');

    // Resolve target display details
    final String targetName;
    final String targetRole;
    if (widget.isProfessional) {
      targetName = (apt.userFullName != null &&
              apt.userFullName!.trim().isNotEmpty &&
              apt.userFullName!.trim().toLowerCase() != 'recipient')
          ? apt.userFullName!.trim()
          : (AppLocalizations.of(context)?.patient ?? 'Patient');
      targetRole = AppLocalizations.of(context)?.patient ?? 'Patient';
    } else {
      targetName = (apt.midwifeName != null &&
              apt.midwifeName!.trim().isNotEmpty &&
              apt.midwifeName!.trim().toLowerCase() != 'recipient')
          ? apt.midwifeName!.trim()
          : 'Health Professional';
      targetRole = AppLocalizations.of(context)?.certifiedMidwife ?? 'Certified Health Professional';
    }

    final initials = targetName.trim().isNotEmpty
        ? targetName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : (widget.isProfessional ? 'P' : 'H');

    final bool isCallWindowActive = windowState == _CallWindowState.active;
    final bool isUpcomingConfirmed = (apt.status == AppointmentStatus.confirmed && !apt.isPast);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E17) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCallWindowActive
              ? (isDark ? const Color(0xFF22C55E).withValues(alpha: 0.5) : const Color(0xFF16A34A).withValues(alpha: 0.45))
              : (isDark ? const Color(0xFF233026) : const Color(0xFFE4EDE3)),
          width: isCallWindowActive ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCallWindowActive
                ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.28 : 0.09)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: isCallWindowActive ? 18 : 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: widget.onCardTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HEADER: Modality Badge + Status Dot + More Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildModalityBadge(modality, isDark, isAm),
                    const Spacer(),
                    buildStatusIndicator(context, apt.status, isPast: apt.isPast),
                    if (isUpcomingConfirmed) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                        tooltip: AppLocalizations.of(context)?.moreOptions ?? 'More options',
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (value) {
                          if (value == 'reschedule') {
                            widget.onReschedule();
                          } else if (value == 'cancel') {
                            widget.onCancel();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'reschedule',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.primaryGreen),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)?.reschedule ?? 'Reschedule',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'cancel',
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined, size: 18, color: AppColors.errorRed),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)?.cancel ?? 'Cancel',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.errorRed),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // 2. PERSON INFO ROW: Avatar with verified badge, Name, Role
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF263C2A), const Color(0xFF1E3223)]
                                  : [const Color(0xFFDCEFD9), const Color(0xFFC7E7C5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.primaryGreen.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF86EFAC) : AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161E17) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.primaryGreen,
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
                            targetName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                widget.isProfessional ? Icons.person_outline_rounded : Icons.medical_services_outlined,
                                size: 13,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  targetRole,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. DATE & TIME RIBBON
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A261D) : const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF243628) : const Color(0xFFE8EFE8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedDateTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. CALL STATUS & WINDOW LIFECYCLE BANNER (For Cellular Voice Calls)
                if (modality == _ConsultationModality.cellularVoice && isUpcomingConfirmed) ...[
                  const SizedBox(height: 12),
                  _buildCallWindowBanner(isCallWindowActive, windowState, isDark, isAm),
                ] else if (windowState == _CallWindowState.completed) ...[
                  const SizedBox(height: 12),
                  _buildCompletedBanner(isDark, isAm),
                ] else if (windowState == _CallWindowState.missed) ...[
                  const SizedBox(height: 12),
                  _buildMissedBanner(isDark, isAm),
                ] else if (windowState == _CallWindowState.expiredPending) ...[
                  const SizedBox(height: 12),
                  _buildExpiredPendingBanner(isDark, isAm),
                ],

                const SizedBox(height: 16),

                // 5. INTUITIVE ACTIONS SECTION
                _buildActionButtons(context, modality, windowState, isCallWindowActive, isDark, isAm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SUB-COMPONENTS ---

  Widget _buildModalityBadge(_ConsultationModality modality, bool isDark, bool isAm) {
    switch (modality) {
      case _ConsultationModality.cellularVoice:
        final carrier = _getCarrierName();
        final label = isAm ? 'ቀጥታ ሴሉላር ጥሪ' : 'Direct Cellular Voice Call';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B3822) : const Color(0xFFEBF7ED),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2A5534) : const Color(0xFFC7E7CC),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_in_talk_rounded,
                size: 13,
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2C5927),
              ),
              const SizedBox(width: 6),
              Text(
                carrier != 'Cellular Network' ? '$label • $carrier' : label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2C5927),
                ),
              ),
            ],
          ),
        );

      case _ConsultationModality.chat:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152A42) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 13,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 6),
              Text(
                isAm ? 'የመልዕክት ምክክር' : 'Messaging Consultation',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
        );

      case _ConsultationModality.inPerson:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF382613) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
              ),
              const SizedBox(width: 6),
              Text(
                isAm ? 'በአካል ክሊኒክ መገኘት' : 'In-Person Clinic Visit',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildCallWindowBanner(bool isActive, _CallWindowState state, bool isDark, bool isAm) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F361E) : const Color(0xFFE8F7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E6135) : const Color(0xFFA6E3B3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF22C55E),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? 'የጥሪ መስመር አሁን ክፍት ነው' : 'Call Window Open Now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAm
                        ? 'የስልክ ጥሪ ለመጀመር ከታች ይጫኑ • ቀጥታ ሴሉላር ደዋይ ይከፈታል'
                        : 'Scheduled window active • Direct cellular dialer connects instantly',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF86EFAC).withValues(alpha: 0.85) : const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Upcoming before appointment window
    final message = _getCountdownOrCallMessage(context, isAm);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C241E) : const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF28362B) : const Color(0xFFE2EAE1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner(bool isDark, bool isAm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAm ? 'ምክክሩ በተሳካ ሁኔታ ተጠናቋል' : 'Consultation Completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedBanner(bool isDark, bool isAm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E1919) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_missed_rounded, size: 15, color: AppColors.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAm ? 'ያመለጠ የቀጠሮ ሰዓት • ምክክሩ አልተካሄደም' : 'Scheduled Call Window Ended • Missed Consultation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredPendingBanner(bool isDark, bool isAm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF7C4A15) : const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 15, color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAm ? 'የቀጠሮው ቀንና ሰዓት ያለፈ በመሆኑ ጥያቄው ጊዜው አልፎበታል' : 'Request expired: scheduled time passed without confirmation.',
              style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    _ConsultationModality modality,
    _CallWindowState windowState,
    bool isCallWindowActive,
    bool isDark,
    bool isAm,
  ) {
    // 1. Pending Consultation (Accept / Decline for professional)
    if (windowState == _CallWindowState.pending) {
      if (widget.isProfessional && widget.onAccept != null) {
        return Row(
          children: [
            ElevatedButton(
              onPressed: widget.onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                AppLocalizations.of(context)?.accept ?? 'Accept',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.onDecline != null) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: widget.onDecline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  AppLocalizations.of(context)?.decline ?? 'Decline',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: widget.onViewDetails,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              child: Text(
                AppLocalizations.of(context)?.viewDetails ?? 'View Details',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: widget.onViewDetails,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: Text(
            AppLocalizations.of(context)?.viewDetails ?? 'View Details',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // 2. Cellular Voice Call Modality (The core requirement)
    if (modality == _ConsultationModality.cellularVoice) {
      if (isCallWindowActive) {
        // ACTIVE CALL NOW BUTTON
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onJoinCall();
                },
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                label: Text(
                  widget.isProfessional
                      ? (isAm ? 'ለታካሚው ደውል (ሴሉላር)' : 'Call Patient Now')
                      : (isAm ? 'አሁን ደውል (ቀጥታ ሴሉላር)' : 'Call Now'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 2,
                  shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            if (widget.onChat != null) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2922) : const Color(0xFFF1F8F1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: widget.onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGreen, size: 20),
                  tooltip: 'Chat',
                ),
              ),
            ],
            const SizedBox(width: 4),
            TextButton(
              onPressed: widget.onViewDetails,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              child: Text(
                AppLocalizations.of(context)?.viewDetails ?? 'Details',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      } else if (windowState == _CallWindowState.upcoming) {
        // LOCKED/COUNTDOWN BEFORE WINDOW
        final timeStr = _startDateTime != null ? _formatTime12h(_startDateTime!) : widget.appointment.startTime;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCallLockedNotice(context, timeStr),
                icon: const Icon(Icons.lock_clock_rounded, size: 16, color: Color(0xFF64748B)),
                label: Text(
                  isAm ? 'ጥሪ በ $timeStr ይከፈታል' : 'Call available at $timeStr',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? const Color(0xFF2E3D31) : const Color(0xFFD6E2D6),
                    width: 1,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1A241C) : const Color(0xFFF8FAF8),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ),
            if (widget.onChat != null) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2922) : const Color(0xFFF1F8F1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: widget.onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGreen, size: 20),
                  tooltip: 'Chat',
                ),
              ),
            ],
            const SizedBox(width: 4),
            TextButton(
              onPressed: widget.onViewDetails,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              child: Text(
                AppLocalizations.of(context)?.viewDetails ?? 'Details',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      } else if (windowState == _CallWindowState.missed) {
        // MISSED WINDOW ACTIONS
        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.onReschedule,
              icon: const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.primaryGreen),
              label: Text(
                AppLocalizations.of(context)?.reschedule ?? 'Reschedule',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onViewDetails,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              child: Text(
                AppLocalizations.of(context)?.viewDetails ?? 'View Details',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }
    }

    // 3. Chat Modality
    if (modality == _ConsultationModality.chat) {
      return Row(
        children: [
          ElevatedButton.icon(
            onPressed: widget.onChat ?? widget.onViewDetails,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
            label: Text(
              isAm ? 'መልዕክት ይክፈቱ' : 'Open Messages',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: widget.onViewDetails,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            child: Text(
              AppLocalizations.of(context)?.viewDetails ?? 'View Details',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    // 4. Default / In-Person Modality / Other
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: widget.onViewDetails,
          icon: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryGreen),
          label: Text(
            isAm ? 'የክሊኒክ ዝርዝር' : 'View Clinic Info',
            style: const TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryGreen),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: widget.onViewDetails,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: Text(
            AppLocalizations.of(context)?.viewDetails ?? 'View Details',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
