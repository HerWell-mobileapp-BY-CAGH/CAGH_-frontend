import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

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
      _consultationType = 'Voice Call';
    } else if (widget.midwife.supportsInPerson) {
      _consultationType = AppLocalizations.of(context)!.inPerson;
    } else {
      _consultationType = 'Voice Call';
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
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateStatus}: $e')));
        setState(() {
          _isLoading = false;
          _timeSlots = null;
        });
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectTimeSlotFirst)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF315E26))),
    );

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
      final slot = [...?_timeSlots?.morningSlots, ...?_timeSlots?.afternoonSlots, ...?_timeSlots?.eveningSlots]
          .firstWhere((s) => s.startTime == _selectedSlotTime, orElse: () => throw Exception('Slot not found'));
          
      String apptType = 'VIRTUAL_VOICE';
      if (_consultationType == 'Voice Call') {
        apptType = 'VIRTUAL_VOICE';
      } else if (_consultationType == AppLocalizations.of(context)!.inPerson) {
        apptType = 'IN_PERSON';
      }

      await _appointmentRepository.requestAppointment({
        'midwife': widget.midwife.id,
        'appointment_type': apptType,
        'scheduled_date': dateStr,
        'start_time': slot.startTime.length == 5 ? '${slot.startTime}:00' : slot.startTime,
        'end_time': slot.endTime.length == 5 ? '${slot.endTime}:00' : slot.endTime,
        'reason': _reasonController.text.isNotEmpty ? _reasonController.text : 'General Consultation',
      });

      if (mounted) Navigator.pop(context);
      _showSuccessBottomSheet();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      final isConflict = e.toString().contains('409');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConflict ? 'This slot was just booked by someone else! Please choose another time.' : 'Booking failed.'),
          backgroundColor: Colors.red
        ),
      );
      _fetchSchedule();
    }
  }

  void _showSuccessBottomSheet() {
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
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_send_rounded,
                  color: Color(0xFF315E26),
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appointment Request Sent',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
              ),
              const SizedBox(height: 8),
              Text(
                'Your request has been sent to ${widget.midwife.fullName}.\n\nWaiting for confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
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
                    backgroundColor: Color(0xFF315E26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(AppLocalizations.of(context)!.returnToDashboard, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    
    final morningSlots = _timeSlots?.morningSlots.where((s) => s.isAvailable).toList() ?? [];
    final afternoonSlots = _timeSlots?.afternoonSlots.where((s) => s.isAvailable).toList() ?? [];
    final eveningSlots = _timeSlots?.eveningSlots.where((s) => s.isAvailable).toList() ?? [];
    final hasSlots = morningSlots.isNotEmpty || afternoonSlots.isNotEmpty || eveningSlots.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315E26),
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
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: widget.midwife.avatarUrl != null ? NetworkImage(widget.midwife.avatarUrl!) : null,
              child: widget.midwife.avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF315E26), size: 16) : null,
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (!widget.midwife.supportsVoiceCall && !widget.midwife.supportsInPerson)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This midwife is not currently offering consultation options.',
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  if (widget.midwife.supportsVoiceCall)
                    _buildConsultationTypeCard('Voice Call', Icons.call),
                  if (widget.midwife.supportsVoiceCall && widget.midwife.supportsInPerson)
                    SizedBox(width: 12),
                  if (widget.midwife.supportsInPerson)
                    _buildConsultationTypeCard(AppLocalizations.of(context)!.inPerson, Icons.home_outlined),
                ],
              ),
            const SizedBox(height: 24),

            // Calendar Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchSchedule();
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey),
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF315E26),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  defaultDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                  ),
                  weekendDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // AVAILABLE TIMES Section
            Text(
              AppLocalizations.of(context)!.availableTimes,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFF315E26))))
            else if (!hasSlots)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0), 
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 12),
                      Text('0 available slots / Blocked by Midwife', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  )
                )
              )
            else ...[
              if (morningSlots.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: Color(0xFF315E26), size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.morning, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: morningSlots.map((slot) => _buildSlotChip(slot.id, slot.startTime, slot.displayTime, slot.isAvailable)).toList(),
                ),
                SizedBox(height: 20),
              ],
              if (afternoonSlots.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: Color(0xFF315E26), size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.afternoon, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: afternoonSlots.map((slot) => _buildSlotChip(slot.id, slot.startTime, slot.displayTime, slot.isAvailable)).toList(),
                ),
                SizedBox(height: 20),
              ],
              if (eveningSlots.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.nights_stay_outlined, color: Color(0xFF315E26), size: 16),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.evening, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: eveningSlots.map((slot) => _buildSlotChip(slot.id, slot.startTime, slot.displayTime, slot.isAvailable)).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ],

            // Patient Notes Section
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.reasonForVisit,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade600),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.describeSymptoms,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF315E26), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Booking Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.bookingSummary,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE8F5E9),
                          backgroundImage: widget.midwife.avatarUrl != null ? NetworkImage(widget.midwife.avatarUrl!) : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.yourMidwife, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              Text(widget.midwife.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(widget.midwife.specialty, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.consultationFee, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text(widget.midwife.consultationFee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.serviceType, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text(_consultationType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.totalAmount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        widget.midwife.consultationFee,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _confirmBooking,
                      icon: Icon(Icons.calendar_today, color: Colors.white, size: 18),
                      label: Text(AppLocalizations.of(context)!.confirmBooking, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315E26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Free cancellation up to 24 hours before\nyour appointment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Privacy Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF315E26), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your health data is encrypted and handled according to HerWell's strict privacy standards.",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.3),
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

  Widget _buildConsultationTypeCard(String title, IconData icon) {
    final isSelected = _consultationType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _consultationType = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Color(0xFFFFD22B) : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF315E26) : Colors.grey.shade500, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF315E26) : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String id, String startTime, String displayTime, bool isAvailable) {
    final isSelected = startTime == _selectedSlotTime;
    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() {
          _selectedSlotId = id;
          _selectedSlotTime = startTime;
        });
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF315E26) 
              : (isAvailable ? Colors.white : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF315E26) 
                : (isAvailable ? const Color(0xFFE0E0E0) : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayTime.isNotEmpty ? displayTime : startTime,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (isAvailable ? Colors.black87 : Colors.grey.shade500),
              ),
            ),
            if (!isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Booked',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
