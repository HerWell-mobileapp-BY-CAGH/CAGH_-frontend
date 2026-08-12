import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/blocked_date.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_manage_schedule_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class MidwifeScheduleScreen extends StatefulWidget {
  const MidwifeScheduleScreen({super.key});

  @override
  State<MidwifeScheduleScreen> createState() => _MidwifeScheduleScreenState();
}

class _MidwifeScheduleScreenState extends State<MidwifeScheduleScreen> {
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());
  final _appointmentsApi = AppointmentApiService();
  
  bool _isLoading = true;
  MidwifeProfile? _profile;
  List<BlockedDate> _blockedDates = [];
  List<AvailabilitySlot> _availabilities = [];

  bool _isAvailable = false;
  bool _voiceCall = false;
  bool _inPerson = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _repository.getMyProfile();
      final blocked = await _repository.getBlockedDates();
      final availData = await _appointmentsApi.getAvailabilities();
      
      final availList = availData.map((e) => AvailabilitySlot.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _profile = profile;
          _blockedDates = blocked;
          _availabilities = availList;
          _isAvailable = profile.isAcceptingBookings;
          _voiceCall = profile.offeredConsultationTypes.contains('Voice Call') || profile.offeredConsultationTypes.contains('VOICE_CALL');
          _inPerson = profile.offeredConsultationTypes.contains('In-person') || profile.offeredConsultationTypes.contains('IN_PERSON');
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    try {
      await _repository.updateMyProfile({'is_accepting_bookings': value});
    } catch (e) {
      if (mounted) {
        setState(() => _isAvailable = !value);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    }
  }

  Future<void> _updatePrefs() async {
    final types = <String>[];
    if (_voiceCall) types.add('VOICE_CALL');
    if (_inPerson) types.add('IN_PERSON');
    try {
      await _repository.updateMyProfile({'offered_consultation_types': types});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences updated'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update preferences'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteBlockedDate(String id) async {
    try {
      await _repository.deleteBlockedDate(id);
      setState(() {
        _blockedDates.removeWhere((b) => b.id == id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete blocked date')));
      }
    }
  }

  void _showAddLeaveModal() {
    String? reason;
    DateTime? selectedDate = _selectedDay;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Reason (e.g. Personal Leave)'),
              onChanged: (val) => reason = val,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
              child: const Text('Change Date'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedDate != null && reason != null && reason!.isNotEmpty) {
                final dateStr = '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _repository.addBlockedDate(dateStr, reason!);
                  await _fetchData();
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add leave')));
                }
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _showScheduleTimeBottomSheet(DateTime date) {
    final dayOfWeek = date.weekday - 1; // 0=Monday to 6=Sunday
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    Set<int> _selectedSlots = {}; // Store in minutes from midnight

    // Pre-populate with existing availabilities
    for (var a in _availabilities) {
      if (a.dateOrDay == dateStr || a.dateOrDay == dayOfWeek.toString()) {
        final startParts = a.startTime.split(':');
        final endParts = a.endTime.split(':');
        if (startParts.length >= 2 && endParts.length >= 2) {
          final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          for (int m = startMin; m < endMin; m += 30) {
            _selectedSlots.add(m);
          }
        }
      }
    }

    final List<int> morningSlots = [
      for (int h = 8; h <= 11; h++) ...[h * 60, h * 60 + 30],
    ];
    final List<int> afternoonSlots = [
      for (int h = 12; h <= 16; h++) ...[h * 60, h * 60 + 30],
    ];
    final List<int> eveningSlots = [
      for (int h = 17; h <= 21; h++) ...[h * 60, h * 60 + 30],
    ];

    String formatTime(int minutes) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final p = hour >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $p';
    }

    Widget buildSlotSection(String title, List<int> slots, StateSetter setSheetState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((minutes) {
              final isSelected = _selectedSlots.contains(minutes);
              return ChoiceChip(
                label: Text(formatTime(minutes)),
                selected: isSelected,
                onSelected: (val) {
                  setSheetState(() {
                    if (val) {
                      _selectedSlots.add(minutes);
                    } else {
                      _selectedSlots.remove(minutes);
                    }
                  });
                },
                selectedColor: const Color(0xFFE8F5E9),
                backgroundColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(color: isSelected ? const Color(0xFF2E5B2E) : Colors.grey.shade300),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2E5B2E) : Colors.black87,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set Working Hours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E5B2E))),
                  const SizedBox(height: 4),
                  Text('For ${_formatMonthYearDay(date)}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSlotSection('MORNING', morningSlots, setSheetState),
                          buildSlotSection('AFTERNOON', afternoonSlots, setSheetState),
                          buildSlotSection('EVENING', eveningSlots, setSheetState),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _selectedSlots.isEmpty ? null : () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
                          final dayOfWeek = date.weekday - 1; // 0=Monday to 6=Sunday
                          
                          // Group into blocks
                          final sortedSlots = _selectedSlots.toList()..sort();
                          List<List<int>> blocks = [];
                          
                          for (int slot in sortedSlots) {
                            if (blocks.isEmpty) {
                              blocks.add([slot]);
                            } else {
                              final lastBlock = blocks.last;
                              if (lastBlock.last + 30 == slot) {
                                lastBlock.add(slot);
                              } else {
                                blocks.add([slot]);
                              }
                            }
                          }

                          // Make API calls for each block
                          for (var block in blocks) {
                            final startMin = block.first;
                            final endMin = block.last + 30; // block ends 30 mins after its last slot starts
                            
                            final startStr = '${(startMin ~/ 60).toString().padLeft(2, '0')}:${(startMin % 60).toString().padLeft(2, '0')}:00';
                            final endStr = '${(endMin ~/ 60).toString().padLeft(2, '0')}:${(endMin % 60).toString().padLeft(2, '0')}:00';
                            
                            await _appointmentsApi.setAvailability({
                              'day_of_week': dayOfWeek,
                              'start_time': startStr,
                              'end_time': endStr,
                              'is_active': true,
                            });
                          }
                          
                          await _fetchData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability scheduled successfully!'), backgroundColor: Colors.green));
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e'), backgroundColor: Colors.red));
                        }
                      },
                      child: Text('Save Selected Slots (${_selectedSlots.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCF9F6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Block
              Container(
                color: const Color(0xFF2E5B2E),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Digital Midwife',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.notifications_outlined, color: Colors.amber, size: 24),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVAILABILITY MANAGEMENT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your Schedule',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E5B2E)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your consulting hours, block out dates for rest, and set your preferred session types.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 24),

                    // Live Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E9DF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_available, color: Color(0xFF2E5B2E), size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('Available for new bookings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: _toggleAvailability,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF2E5B2E),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Functional Calendar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select a day to set working hours', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 12),
                          TableCalendar(
                            firstDay: DateTime.utc(2023, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              _showScheduleTimeBottomSheet(selectedDay);
                            },
                            calendarFormat: CalendarFormat.month,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E5B2E)),
                            ),
                            calendarStyle: const CalendarStyle(
                              selectedDecoration: BoxDecoration(
                                color: Color(0xFF2E5B2E),
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Color(0xFFE5E9DF),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                
                                bool isBlocked = _blockedDates.any((b) => b.date == dateStr);
                                bool hasAvailability = _availabilities.any((a) {
                                  if (a.dateOrDay == dateStr) return true;
                                  if (a.dateOrDay == (date.weekday - 1).toString()) return true;
                                  return false;
                                });

                                if (isBlocked) {
                                  return Positioned(
                                    bottom: 1,
                                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                  );
                                }
                                if (hasAvailability) {
                                  return Positioned(
                                    bottom: 1,
                                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Consultation Types Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Consultation Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4B9A))),
                          ),
                          Material(
                            color: Colors.white.withOpacity(0.5),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  value: _voiceCall,
                                  onChanged: (v) => setState(() => _voiceCall = v ?? false),
                                  title: const Text('Voice Call', style: TextStyle(fontSize: 14)),
                                  secondary: const Icon(Icons.phone_outlined, color: Color(0xFF6B4B9A), size: 20),
                                  activeColor: const Color(0xFF6B4B9A),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                ),
                                CheckboxListTile(
                                  value: _inPerson,
                                  onChanged: (v) => setState(() => _inPerson = v ?? false),
                                  title: const Text('In-person', style: TextStyle(fontSize: 14)),
                                  secondary: const Icon(Icons.person_outline, color: Color(0xFF6B4B9A), size: 20),
                                  activeColor: const Color(0xFF6B4B9A),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _updatePrefs,
                                icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                                label: const Text('Update Prefs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E5B2E),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Blocked Dates
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Blocked Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E5B2E))),
                              GestureDetector(
                                onTap: _showAddLeaveModal,
                                child: const Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: Color(0xFF6B4B9A), size: 16),
                                    SizedBox(width: 4),
                                    Text('Add Leave', style: TextStyle(color: Color(0xFF6B4B9A), fontSize: 12, fontWeight: FontWeight.bold))
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._blockedDates.map((b) => _buildBlockedDateItem(b)).toList(),
                          if (_blockedDates.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('No blocked dates.', style: TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Working Hours
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD6E3D6), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recurring Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E5B2E))),
                          const SizedBox(height: 4),
                          Text('Set your default weekly working schedule for all days.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Manage Default Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedDateItem(BlockedDate b) {
    DateTime? d = DateTime.tryParse(b.date);
    String month = d != null ? _formatShortMonth(d).toUpperCase() : '';
    String day = d != null ? d.day.toString().padLeft(2, '0') : '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEAEA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(month, style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                Text(day, style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.reason ?? 'Blocked', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFA12C2C))),
                const Text('Full Day', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteBlockedDate(b.id),
          )
        ],
      ),
    );
  }

  String _formatMonthYearDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (date.month >= 1 && date.month <= 12) {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
    return '';
  }

  String _formatShortMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (date.month >= 1 && date.month <= 12) {
      return months[date.month - 1];
    }
    return '';
  }
}
