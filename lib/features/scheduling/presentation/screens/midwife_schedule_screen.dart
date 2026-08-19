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
  bool _videoCall = false;
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
          if (profile != null) {
            _isAvailable = profile.isAcceptingBookings;
            _voiceCall = profile.offeredConsultationTypes.contains('Voice Call') || profile.offeredConsultationTypes.contains('VOICE_CALL');
            _videoCall = profile.offeredConsultationTypes.contains('Video Call') || profile.offeredConsultationTypes.contains('VIDEO_CALL');
            _inPerson = profile.offeredConsultationTypes.contains('In-person') || profile.offeredConsultationTypes.contains('IN_PERSON');
          }
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
    if (_videoCall) types.add('VIDEO_CALL');
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
    DateTime selectedDate = DateTime.now();
    bool showError = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            title: Text('Block a Date', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2E5B2E))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select the date you want to take off or block from bookings.', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                const SizedBox(height: 20),
                
                // Date Picker Button
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDark 
                              ? const ColorScheme.dark(primary: Color(0xFFB39DDB), surface: Color(0xFF2C2C2C))
                              : const ColorScheme.light(primary: Color(0xFF315E26), surface: Colors.white),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF6B4B9A)),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ],
                        ),
                        Icon(Icons.edit, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reason TextField
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Reason (e.g., Sick leave, Vacation)',
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6B4B9A))),
                    errorText: showError ? 'Please provide a reason' : null,
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  onChanged: (val) {
                    reason = val;
                    if (showError && val.trim().isNotEmpty) {
                      setDialogState(() => showError = false);
                    }
                  },
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4B9A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  if (reason == null || reason!.trim().isEmpty) {
                    setDialogState(() => showError = true);
                    return;
                  }
                  
                  final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await _repository.addBlockedDate(dateStr, reason!.trim());
                    await _fetchData();
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add leave')));
                  }
                },
                child: const Text('Block Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  void _showScheduleTimeBottomSheet(int dayOfWeek) {
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[dayOfWeek];
    
    Set<int> _selectedSlots = {}; // Store in minutes from midnight

    // Pre-populate with existing availabilities
    for (var a in _availabilities) {
      if (a.dateOrDay == dayOfWeek.toString()) {
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
              final isDark = Theme.of(context).brightness == Brightness.dark;
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
                selectedColor: isDark ? const Color(0xFF315E26) : const Color(0xFFE8F5E9),
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                showCheckmark: false,
                side: BorderSide(color: isSelected ? const Color(0xFF2E5B2E) : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? (isDark ? Colors.white : const Color(0xFF2E5B2E)) 
                      : (isDark ? Colors.grey.shade300 : Colors.black87),
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Working Hours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2E5B2E))),
                  const SizedBox(height: 4),
                  Text('Every $dayName', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
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
                        backgroundColor: const Color(0xFF315E26),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _selectedSlots.isEmpty ? null : () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading && _profile == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFCF9F6),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF315E26))),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFCF9F6),
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
                    Icon(Icons.notifications_outlined, color: Color(0xFFFFD22B), size: 24),
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
                    Text(
                      'Your Schedule',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2E5B2E)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your consulting hours, block out dates for rest, and set your preferred session types.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 24),

                    // Live Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F6ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E9DF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_available, color: Color(0xFF2E5B2E), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                                const SizedBox(height: 2),
                                Text('Available for new bookings', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey)),
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

                    // Weekly Schedule Picker
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select a day of the week to set recurring hours', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].asMap().entries.map((entry) {
                              final int index = entry.key; // 0 = Monday
                              final String label = entry.value;
                              
                              bool hasAvailability = _availabilities.any((a) => a.dateOrDay == index.toString());
                              
                              return GestureDetector(
                                onTap: () => _showScheduleTimeBottomSheet(index),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF4F6ED),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2E5B2E)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (hasAvailability)
                                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))
                                    else
                                      const SizedBox(height: 6),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Consultation Types Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2533) : const Color(0xFFFDF7E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('Consultation Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF6B4B9A))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildConsultationChip(
                                  title: 'Voice Call',
                                  icon: Icons.phone_outlined,
                                  isSelected: _voiceCall,
                                  onSelected: (v) => setState(() => _voiceCall = v),
                                  isDark: isDark,
                                ),
                                _buildConsultationChip(
                                  title: 'Video Call',
                                  icon: Icons.videocam_outlined,
                                  isSelected: _videoCall,
                                  onSelected: (v) => setState(() => _videoCall = v),
                                  isDark: isDark,
                                ),
                                _buildConsultationChip(
                                  title: 'In-person',
                                  icon: Icons.person_outline,
                                  isSelected: _inPerson,
                                  onSelected: (v) => setState(() => _inPerson = v),
                                  isDark: isDark,
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
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                              Text('Blocked Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF2E5B2E))),
                              GestureDetector(
                                onTap: _showAddLeaveModal,
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF6B4B9A), size: 16),
                                    const SizedBox(width: 4),
                                    Text('Add Leave', style: TextStyle(color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF6B4B9A), fontSize: 12, fontWeight: FontWeight.bold))
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._blockedDates.map((b) => _buildBlockedDateItem(b, isDark)).toList(),
                          if (_blockedDates.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('No blocked dates.', style: TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationChip({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Function(bool) onSelected,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF6B4B9A))),
          const SizedBox(width: 6),
          Text(title),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF6B4B9A),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6B4B9A) : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }

  Widget _buildBlockedDateItem(BlockedDate b, bool isDark) {
    DateTime? d = DateTime.tryParse(b.date);
    String month = d != null ? _formatShortMonth(d).toUpperCase() : '';
    String day = d != null ? d.day.toString().padLeft(2, '0') : '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF331E1E) : const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF4A2A2A) : const Color(0xFFFFEAEA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4A2A2A) : const Color(0xFFFFEAEA),
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
                Text(b.reason ?? 'Blocked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFFE57373) : const Color(0xFFA12C2C))),
                Text('Full Day', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey)),
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
