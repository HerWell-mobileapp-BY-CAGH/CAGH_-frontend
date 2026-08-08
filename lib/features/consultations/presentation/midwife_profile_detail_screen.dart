import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/presentation/book_appointment_screen.dart';

class MidwifeProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> midwife;
  final Function(String midwifeName)? onMessageTap;

  const MidwifeProfileDetailScreen({
    super.key,
    required this.midwife,
    this.onMessageTap,
  });

  @override
  State<MidwifeProfileDetailScreen> createState() => _MidwifeProfileDetailScreenState();
}

class _MidwifeProfileDetailScreenState extends State<MidwifeProfileDetailScreen> {
  bool _isFavorite = false;
  int? _selectedDayIndex;
  int? _selectedSlotIndex;

  final List<Map<String, String>> _days = [
    {'day': 'MON', 'date': '12'},
    {'day': 'TUE', 'date': '13'},
    {'day': 'WED', 'date': '14'},
    {'day': 'THU', 'date': '15'},
    {'day': 'FRI', 'date': '16'},
  ];

  final List<String> _slots = [
    '09:00 AM',
    '10:30 AM',
    '11:15 AM',
  ];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.midwife['isFavorite'] ?? false;
  }



  @override
  Widget build(BuildContext context) {
    final String name = widget.midwife['name'] ?? 'Abeba Selassie';
    final String firstName = name.split(' ').first;
    final String hospital = widget.midwife['hospital'] ?? "St. Paul's Maternity";
    final String experience = widget.midwife['experience'] ?? '12+ Years';
    final String bio = widget.midwife['bio'] ??
        'A dedicated Senior Midwife with over 12 years of experience specializing in natural birthing techniques and postpartum care. $firstName is passionate about empowering young women through their reproductive health journeys with a blend of modern clinical expertise and holistic nurturing care.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner Section (Matching Screenshot)
                    Stack(
                      children: [
                        Container(
                          height: 320,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                            image: DecorationImage(
                              image: AssetImage('assets/images/midwife_abeba.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Top Controls (Back Arrow & Favorite Heart)
                        Positioned(
                          top: 44,
                          left: 20,
                          right: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF274E13),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isFavorite = !_isFavorite),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: _isFavorite ? Colors.red : const Color(0xFF274E13),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Midwife Name & Verified Badge Overlay
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA5D6A7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Midwife',
                                      style: TextStyle(
                                        color: Color(0xFF1B5E20),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Hospital & Experience Stat Cards Row (Matching Screenshot)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.apartment_rounded,
                              label: 'HOSPITAL',
                              value: hospital,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.verified_outlined,
                              label: 'EXPERIENCE',
                              value: experience,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Languages Section (Matching Screenshot)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LANGUAGES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildLanguageChip('English'),
                              const SizedBox(width: 8),
                              _buildLanguageChip('Amharic'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // About Midwife Section (Matching Screenshot)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About $firstName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF274E13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Availability & Slots Section (Matching Screenshot)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Availability',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF274E13),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF274E13),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Day Selector Cards
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_days.length, (index) {
                              final day = _days[index];
                              final isSelected = index == _selectedDayIndex;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedDayIndex = index),
                                child: Container(
                                  width: 54,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF274E13) : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        day['day']!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        day['date']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'MORNING SLOTS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Slots Selector Chips
                          Row(
                            children: List.generate(_slots.length, (index) {
                              final slot = _slots[index];
                              final isSelected = index == _selectedSlotIndex;
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(slot),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _selectedSlotIndex = index);
                                    }
                                  },
                                  selectedColor: const Color(0xFFDCEDC8),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF274E13) : const Color(0xFFE0E0E0),
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF274E13) : Colors.black87,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons (Message & Book Buttons) (Inline, not fixed at bottom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        if (widget.onMessageTap != null) {
                                          widget.onMessageTap!(name);
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      },
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF274E13), size: 18),
                                      label: const Text(
                                        'Message',
                                        style: TextStyle(
                                          color: Color(0xFF274E13),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF274E13), width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookAppointmentScreen(
                                              midwife: widget.midwife,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
                                      label: const Text(
                                        'Book',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF274E13),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF274E13), size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF274E13),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
