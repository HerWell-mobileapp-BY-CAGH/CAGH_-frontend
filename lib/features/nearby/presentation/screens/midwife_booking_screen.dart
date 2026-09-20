import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';

class MidwifeBookingScreen extends StatefulWidget {
  final HealthcareFacility facility;

  const MidwifeBookingScreen({super.key, required this.facility});

  @override
  State<MidwifeBookingScreen> createState() => _MidwifeBookingScreenState();
}

class _MidwifeBookingScreenState extends State<MidwifeBookingScreen> {
  int _selectedDayIndex = 4; // Default select Friday for the mock

  final List<Map<String, dynamic>> _mockDays = [
    {'day': 'MON', 'date': '31'},
    {'day': 'TUE', 'date': '1'},
    {'day': 'WED', 'date': '2'},
    {'day': 'THU', 'date': '3'},
    {'day': 'FRI', 'date': '4'},
    {'day': 'SAT', 'date': '5'},
    {'day': 'SUN', 'date': '6'},
  ];

  final List<Map<String, dynamic>> _mockSlots = [
    {
      'start': '08:00 AM',
      'end': '08:30 AM',
      'session': 'Morning session',
      'method': 'In-person',
      'duration': '30 min',
      'icon': Icons.location_on_outlined,
    },
    {
      'start': '09:00 AM',
      'end': '09:30 AM',
      'session': 'Morning session',
      'method': 'Voice call',
      'duration': '30 min',
      'icon': Icons.phone_in_talk_outlined,
    },
    {
      'start': '01:00 PM',
      'end': '01:30 PM',
      'session': 'Afternoon session',
      'method': 'In-person',
      'duration': '30 min',
      'icon': Icons.location_on_outlined,
    },
    {
      'start': '03:30 PM',
      'end': '04:00 PM',
      'session': 'Afternoon session',
      'method': 'Voice call',
      'duration': '30 min',
      'icon': Icons.phone_in_talk_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAEB), // Very light pale green/yellow background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF385A2E), size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF182335),
                      ),
                    ),
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF385A2E).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Days row
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mockDays.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedDayIndex;
                      final day = _mockDays[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = index;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF385A2E) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day['day']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white70 : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day['date']!,
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
                
                // Slots
                ..._mockSlots.map((slot) => _buildSlotCard(slot)),
              ],
            ),
          ),
          
          // Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAEB),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF9FAEB).withValues(alpha: 0.9),
                    blurRadius: 20,
                    spreadRadius: 10,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF385A2E), size: 20),
                      label: const Text('Message', style: TextStyle(color: Color(0xFF385A2E), fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF385A2E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
                      label: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF385A2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slot['start'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF182335)),
              ),
              const Text(
                '+',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xFF385A2E)),
              ),
              Text(
                slot['end'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF182335)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(slot['icon'], size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    '${slot['session']} · ${slot['method']}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    slot['duration'],
                    style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Text(
                        'Select',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF182335)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: Color(0xFF182335)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
