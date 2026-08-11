import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:intl/intl.dart';

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
  String _consultationType = 'Virtual';
  
  late List<DateTime> _nextDays;
  int _selectedDateIndex = 0;
  
  String? _selectedSlotId;
  String? _selectedSlotTime;

  TimeSlotsResponse? _timeSlots;
  
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());

  @override
  void initState() {
    super.initState();
    _generateNextDays();
    _fetchSchedule();
  }

  void _generateNextDays() {
    final now = DateTime.now();
    _nextDays = List.generate(14, (index) => now.add(Duration(days: index)));
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _selectedSlotId = null;
      _selectedSlotTime = null;
    });
    
    final midwifeId = widget.midwife.id;
    final dateStr = DateFormat('yyyy-MM-dd').format(_nextDays[_selectedDateIndex]);
    
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
        const SnackBar(content: Text('Please select a time slot first.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
    );

    try {
      await _appointmentRepository.requestAppointment({
        'midwife_id': widget.midwife.id,
        'time_slot_id': _selectedSlotId,
        'consultation_type': _consultationType,
      });

      if (mounted) Navigator.pop(context);
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
      return;
    }

    final midwifeName = widget.midwife.fullName;

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
                  color: Color(0xFF274E13),
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appointment Request Sent',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF274E13),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your request has been sent to $midwifeName.\n\nWaiting for confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending_actions, size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF274E13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Return to Dashboard',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
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
    final name = widget.midwife.fullName;
    final specialty = widget.midwife.specialty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: widget.midwife.avatarUrl != null ? NetworkImage(widget.midwife.avatarUrl!) : null,
              child: widget.midwife.avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF274E13), size: 18) : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CONSULTATION TYPE Section
            Text(
              'CONSULTATION TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _consultationType = 'Virtual'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _consultationType == 'Virtual' ? Colors.amber : Colors.grey.shade200,
                          width: _consultationType == 'Virtual' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.videocam,
                            color: _consultationType == 'Virtual' ? const Color(0xFF274E13) : Colors.grey.shade600,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Virtual',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _consultationType == 'Virtual' ? const Color(0xFF274E13) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _consultationType = 'In-person'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _consultationType == 'In-person' ? Colors.amber : Colors.grey.shade200,
                          width: _consultationType == 'In-person' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: _consultationType == 'In-person' ? const Color(0xFF274E13) : Colors.grey.shade600,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'In-person',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _consultationType == 'In-person' ? const Color(0xFF274E13) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Date Picker
            Text(
              'SELECT DATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nextDays.length,
                itemBuilder: (context, index) {
                  final date = _nextDays[index];
                  final isSelected = index == _selectedDateIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDateIndex = index);
                      _fetchSchedule();
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF274E13) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF274E13) : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // AVAILABLE TIMES Section
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                ),
              )
            else if (_timeSlots == null || (_timeSlots!.morningSlots.isEmpty && _timeSlots!.afternoonSlots.isEmpty))
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('No available slots for this date.', style: TextStyle(color: Colors.red)),
                ),
              )
            else ...[
              Text(
                'AVAILABLE TIMES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              // Morning
              if (_timeSlots!.morningSlots.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: Color(0xFF274E13), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Morning',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF274E13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots!.morningSlots.map((slot) => _buildSlotChip(slot.id, slot.startTime, slot.isAvailable)).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Afternoon
              if (_timeSlots!.afternoonSlots.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: Color(0xFF274E13), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Afternoon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF274E13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots!.afternoonSlots.map((slot) => _buildSlotChip(slot.id, slot.startTime, slot.isAvailable)).toList(),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Divider line
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF274E13),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Booking Summary
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: widget.midwife.avatarUrl != null ? NetworkImage(widget.midwife.avatarUrl!) : null,
                    child: widget.midwife.avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF274E13), size: 26) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Midwife',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          specialty,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Consultation Fee', style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5)),
                Text(widget.midwife.consultationFee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF274E13))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Service Type', style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5)),
                Text('$_consultationType Chat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            if (_selectedSlotTime != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date & Time', style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5)),
                  Text('${DateFormat('MMM d').format(_nextDays[_selectedDateIndex])}, $_selectedSlotTime', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  widget.midwife.consultationFee,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF274E13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Confirm Booking Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmBooking,
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF274E13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Free cancellation up to 24 hours before your appointment.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),

            const SizedBox(height: 20),

            // Privacy Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF274E13), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Your health data is encrypted and handled according to HerWell's strict privacy standards.",
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotChip(String id, String startTime, bool isAvailable) {
    final isSelected = id == _selectedSlotId;
    return ChoiceChip(
      label: Text(startTime),
      selected: isSelected,
      onSelected: isAvailable ? (val) {
        if (val) {
          setState(() {
            _selectedSlotId = id;
            _selectedSlotTime = startTime;
          });
        }
      } : null,
      selectedColor: const Color(0xFFDCEDC8),
      backgroundColor: Colors.white,
      disabledColor: Colors.grey.shade200,
      side: BorderSide(
        color: isSelected ? const Color(0xFF274E13) : const Color(0xFFE0E0E0),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isAvailable ? (isSelected ? const Color(0xFF274E13) : Colors.black87) : Colors.grey,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

