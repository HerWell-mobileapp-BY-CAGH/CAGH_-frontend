import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> midwife;

  const BookAppointmentScreen({
    super.key,
    required this.midwife,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String _consultationType = 'Virtual'; // 'Virtual' or 'In-person'
  int? _selectedDateDay;
  String? _selectedSlot;

  final List<String> _morningSlots = ['09:00 AM', '10:30 AM', '11:15 AM'];
  final List<String> _afternoonSlots = ['01:30 PM', '02:45 PM', '04:00 PM'];

  void _confirmBooking() {
    final midwifeName = widget.midwife['name'] ?? 'Midwife Sarah Jenkins';
    final dateStr = 'Oct ${_selectedDateDay ?? 24}, 2023';
    final timeStr = _selectedSlot ?? '10:30 AM';

    AppointmentService.addBooking(
      midwifeName: midwifeName,
      consultationType: '$_consultationType Consultation',
      date: dateStr,
      time: timeStr,
    );

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
                  Icons.check_circle_rounded,
                  color: Color(0xFF274E13),
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF274E13),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your $_consultationType consultation with ${widget.midwife['name'] ?? 'Sr. Abeba Selassie'} is confirmed for Sep $_selectedDateDay, 2024 at $_selectedSlot.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.pop(context); // Back to detail
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
    final name = widget.midwife['name'] ?? 'Sr. Abeba Selassie';
    final specialty = widget.midwife['specialty'] ?? 'Obstetrics Specialist';

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, color: Color(0xFF274E13), size: 18),
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

            // Date Calendar Picker Container (September 2024 Grid)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'September 2024',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF274E13),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Days Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('S', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('M', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('T', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('W', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('T', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('F', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('S', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Date Rows
                  _buildCalendarRow(['25', '26', '27', '28', '29', '30', '1'], isFadedPreviousMonth: true),
                  const SizedBox(height: 8),
                  _buildCalendarRow(['2', '3', '4', '5', '6', '7', '8']),
                  const SizedBox(height: 8),
                  _buildCalendarRow(['9', '10', '11', '12', '13', '14', '15']),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // AVAILABLE TIMES Section
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
            Row(
              children: _morningSlots.map((slot) => _buildSlotChip(slot)).toList(),
            ),

            const SizedBox(height: 16),

            // Afternoon
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
            Row(
              children: _afternoonSlots.map((slot) => _buildSlotChip(slot)).toList(),
            ),

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
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.person, color: Color(0xFF274E13), size: 26),
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
                const Text('Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF274E13))),
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

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'FREE',
                  style: TextStyle(
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

  Widget _buildCalendarRow(List<String> days, {bool isFadedPreviousMonth = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) {
        final dayNum = int.tryParse(d);
        final isSelected = dayNum == _selectedDateDay && !isFadedPreviousMonth;
        return GestureDetector(
          onTap: () {
            if (!isFadedPreviousMonth && dayNum != null) {
              setState(() => _selectedDateDay = dayNum);
            }
          },
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF274E13) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              d,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isFadedPreviousMonth ? Colors.grey.shade400 : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlotChip(String slot) {
    final isSelected = slot == _selectedSlot;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(slot),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedSlot = slot);
          }
        },
        selectedColor: const Color(0xFFDCEDC8),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF274E13) : const Color(0xFFE0E0E0),
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF274E13) : Colors.black87,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
