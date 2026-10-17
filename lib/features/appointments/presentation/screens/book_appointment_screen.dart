import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:cagh_frontend/shared/models/time_slot.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class BookAppointmentScreen extends StatefulWidget {
  final MidwifeProfile midwife;

  const BookAppointmentScreen({
    super.key,
    required this.midwife,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  bool _isLoading = false;
  late String _consultationType;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  String? _selectedSlotId;
  String? _selectedSlotTime;
  
  final TextEditingController _reasonController = TextEditingController();

  TimeSlotsResponse? _timeSlots;
  
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());

  @override
  void initState() {
    super.initState();
    if (widget.midwife.supportsVoiceCall) {
      _consultationType = 'VOICE';
    } else if (widget.midwife.supportsInPerson) {
      _consultationType = 'IN_PERSON';
    } else {
      _consultationType = 'VOICE';
    }
    _fetchSchedule();
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _selectedSlotId = null;
      _selectedSlotTime = null;
    });
    
    final midwifeId = widget.midwife.id;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    
    try {
      final slots = await _appointmentRepository.getTimeSlots(midwifeId, dateStr);
      if (mounted) {
        setState(() {
          _timeSlots = slots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '${AppLocalizations.of(context)!.failedToUpdateStatus}: $e', isError: true);
        setState(() {
          _isLoading = false;
          _timeSlots = null;
        });
      }
    }
  }

  String? _getIncompatibilityErrorMessage(TimeSlot slot, String selectedType) {
    final isVoiceSelected = selectedType == 'VOICE' || selectedType.toLowerCase().contains('voice');
    final isPersonSelected = selectedType == 'IN_PERSON' || !isVoiceSelected;
    final category = slot.consultationTypeCategory;

    if (category == 'both') return null; // Always compatible

    if (isPersonSelected && category == 'voice') {
      return 'This time is available for voice consultation only. Please select Voice or choose another time.';
    }

    if (isVoiceSelected && category == 'in_person') {
      return 'This time is available for in-person consultation only. Please select In-Person or choose another time.';
    }

    return null;
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlotId == null) {
      CustomSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.selectTimeSlotFirst,
        isError: true,
      );
      return;
    }

    final slot = [...?_timeSlots?.morningSlots, ...?_timeSlots?.afternoonSlots, ...?_timeSlots?.eveningSlots]
        .firstWhere((s) => s.startTime == _selectedSlotTime, orElse: () => throw Exception('Slot not found'));

    final incompatibilityErr = _getIncompatibilityErrorMessage(slot, _consultationType);
    if (incompatibilityErr != null) {
      CustomSnackBar.show(
        context,
        message: incompatibilityErr,
        isError: true,
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: isDark ? AppColors.darkPrimary : const Color(0xFF315E26))),
    );

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
          
      final apptType = _consultationType == 'IN_PERSON' ? 'IN_PERSON' : 'VIRTUAL_VOICE';

      await _appointmentRepository.requestAppointment({
        'midwife': widget.midwife.id,
        'appointment_type': apptType,
        'scheduled_date': dateStr,
        'start_time': slot.startTime.length == 5 ? '${slot.startTime}:00' : slot.startTime,
        'end_time': slot.endTime.length == 5 ? '${slot.endTime}:00' : slot.endTime,
        'reason': _reasonController.text.isNotEmpty ? _reasonController.text : 'General Consultation',
        if (slot.id.isNotEmpty) 'availability_id': slot.id,
      });

      if (mounted) Navigator.pop(context);
      _showSuccessBottomSheet();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      final errStr = e.toString().replaceAll('Exception: ', '');
      final isConflict = errStr.contains('409') || errStr.toLowerCase().contains('conflict');
      CustomSnackBar.show(
        context,
        message: isConflict ? 'This slot was just booked by someone else! Please choose another time.' : errStr,
        isError: true,
      );
      _fetchSchedule();
    }
  }

  void _showSuccessBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF315E26);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF315E26);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_send_rounded,
                  color: primaryColor,
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Appointment Request Sent',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your request has been sent to ${widget.midwife.fullName}.\n\nWaiting for confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(AppLocalizations.of(context)!.returnToDashboard, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF315E26);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.grey.shade200;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF182335);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    final morningSlots = _timeSlots?.morningSlots.where((s) => s.isAvailable).toList() ?? [];
    final afternoonSlots = _timeSlots?.afternoonSlots.where((s) => s.isAvailable).toList() ?? [];
    final eveningSlots = _timeSlots?.eveningSlots.where((s) => s.isAvailable).toList() ?? [];
    final hasSlots = morningSlots.isNotEmpty || afternoonSlots.isNotEmpty || eveningSlots.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFF315E26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F5E9),
              backgroundImage: widget.midwife.avatarUrl != null ? NetworkImage(widget.midwife.avatarUrl!) : null,
              child: widget.midwife.avatarUrl == null ? Icon(Icons.person, color: primaryColor, size: 16) : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CONSULTATION TYPE Section
            Text(
              AppLocalizations.of(context)!.consultationType,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
            ),
            const SizedBox(height: 12),
            if (!widget.midwife.supportsVoiceCall && !widget.midwife.supportsInPerson)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This midwife is not currently offering consultation options.',
                        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  if (widget.midwife.supportsVoiceCall)
                    _buildConsultationTypeCard(
                      typeKey: 'VOICE',
                      title: AppLocalizations.of(context)!.voiceCall,
                      icon: Icons.call,
                    ),
                  if (widget.midwife.supportsVoiceCall && widget.midwife.supportsInPerson)
                    const SizedBox(width: 12),
                  if (widget.midwife.supportsInPerson)
                    _buildConsultationTypeCard(
                      typeKey: 'IN_PERSON',
                      title: AppLocalizations.of(context)!.inPerson,
                      icon: Icons.home_outlined,
                    ),
                ],
              ),
            const SizedBox(height: 24),

            // Calendar Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  if (selectedDay.isBefore(today)) return;
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchSchedule();
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left, color: textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: textSecondary),
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                  weekendStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                calendarStyle: CalendarStyle(
                  disabledTextStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.35) : Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 13,
                  ),
                  disabledDecoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.2) : Colors.grey.shade100.withValues(alpha: 0.5),
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: buttonGreen,
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  todayDecoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : const Color(0xFFE8F5E9),
                    border: Border.all(color: primaryColor, width: 1.5),
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  todayTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  defaultTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                  weekendTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                  outsideTextStyle: TextStyle(color: isDark ? textSecondary.withValues(alpha: 0.35) : Colors.grey.shade400),
                  defaultDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                  weekendDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AVAILABLE TIMES Section
            Text(
              AppLocalizations.of(context)!.availableTimes,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(color: primaryColor)))
            else if (!hasSlots)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0), 
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, color: textSecondary, size: 40),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context)!.noSlotsFound, style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  )
                )
              )
            else ...[
              if (morningSlots.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.morning, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ...morningSlots.map((slot) => _buildSlotCard(
                  slot: slot,
                  sessionTitle: AppLocalizations.of(context)!.morning,
                )),
                const SizedBox(height: 16),
              ],
              if (afternoonSlots.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.afternoon, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ...afternoonSlots.map((slot) => _buildSlotCard(
                  slot: slot,
                  sessionTitle: AppLocalizations.of(context)!.afternoon,
                )),
                const SizedBox(height: 16),
              ],
              if (eveningSlots.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.nights_stay_outlined, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.evening, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ...eveningSlots.map((slot) => _buildSlotCard(
                  slot: slot,
                  sessionTitle: AppLocalizations.of(context)!.evening,
                )),
                const SizedBox(height: 16),
              ],
            ],

            // Patient Notes Section
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.reasonForVisit,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.describeSymptoms,
                hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Booking Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmBooking,
                icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppLocalizations.of(context)!.confirmBooking,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your health data is encrypted and handled according to strict privacy standards.",
                      style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationTypeCard({
    required String typeKey,
    required String title,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    final isSelected = _consultationType == typeKey;
    final cardBorder = isSelected
        ? primaryColor
        : (isDark ? AppColors.darkBorder : Colors.grey.shade200);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _consultationType = typeKey;
            _selectedSlotId = null;
            _selectedSlotTime = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? primaryColor : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade500), size: 28),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade600),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime12h(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int min = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return time;
    }
  }

  Widget _buildSlotCard({
    required TimeSlot slot,
    required String sessionTitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final isSelected = slot.startTime == _selectedSlotTime;

    final cardBg = isSelected 
        ? (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F8E9))
        : (isDark ? AppColors.darkSurface : Colors.white);
    final cardBorder = isSelected
        ? primaryColor
        : (isDark ? AppColors.darkBorder : Colors.black12);

    final start12 = slot.displayTime.isNotEmpty ? slot.displayTime : _formatTime12h(slot.startTime);
    final end12 = slot.endTime.isNotEmpty ? _formatTime12h(slot.endTime) : '';
    final typeTagText = slot.consultationTypeTagText;

    IconData typeIcon;
    Color tagColor;
    final cat = slot.consultationTypeCategory;
    if (cat == 'in_person') {
      typeIcon = Icons.home_outlined;
      tagColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
    } else if (cat == 'voice') {
      typeIcon = Icons.phone_in_talk_outlined;
      tagColor = isDark ? AppColors.darkPrimary : const Color(0xFF2E7D32);
    } else {
      typeIcon = Icons.medical_services_outlined;
      tagColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    }

    return GestureDetector(
      onTap: slot.isAvailable
          ? () {
              final err = _getIncompatibilityErrorMessage(slot, _consultationType);
              if (err != null) {
                CustomSnackBar.show(
                  context,
                  message: err,
                  isError: true,
                );
                return;
              }
              setState(() {
                _selectedSlotId = slot.id;
                _selectedSlotTime = slot.startTime;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  start12,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? primaryColor : (isDark ? AppColors.darkTextPrimary : const Color(0xFF182335)),
                  ),
                ),
                Icon(
                  Icons.add,
                  size: 18,
                  color: primaryColor,
                ),
                Text(
                  end12.isNotEmpty ? end12 : start12,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? primaryColor : (isDark ? AppColors.darkTextPrimary : const Color(0xFF182335)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, size: 16, color: tagColor),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sessionTitle · $typeTagText',
                        style: TextStyle(fontSize: 12, color: tagColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Selected',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            slot.isAvailable ? 'Select' : 'Booked',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: slot.isAvailable ? primaryColor : (isDark ? AppColors.darkTextSecondary : Colors.grey),
                            ),
                          ),
                          if (slot.isAvailable) ...[
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward, size: 13, color: primaryColor),
                          ],
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
