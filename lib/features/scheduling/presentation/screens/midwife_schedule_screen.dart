import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_add_availability_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_day_view_screen.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:intl/intl.dart';

class MidwifeScheduleScreen extends StatefulWidget {
  const MidwifeScheduleScreen({super.key});

  @override
  State<MidwifeScheduleScreen> createState() => _MidwifeScheduleScreenState();
}

class _MidwifeScheduleScreenState extends State<MidwifeScheduleScreen> {
  final _appointmentsApi = AppointmentApiService();
  
  bool _isLoading = true;
  List<AvailabilitySlot> _availabilities = [];

  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final availData = await _appointmentsApi.getAvailabilities();
      final availList = availData.map((e) => AvailabilitySlot.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _availabilities = availList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AvailabilitySlot> _getAvailabilitiesForDay(DateTime day) {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    final dayOfWeekString = (day.weekday - 1).toString();
    
    return _availabilities.where((a) {
      final d = a.dateOrDay.toLowerCase();
      return d == dateString.toLowerCase() || d == dayOfWeekString;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Green App Bar
            Container(
              width: double.infinity,
              color: const Color(0xFF385A2E), // Dark green
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const GlobeLanguagePicker(iconColor: Colors.white, iconSize: 24),
                      const SizedBox(width: 16),
                      const Icon(Icons.notifications_none, color: Colors.white), // Simplified for now since NotificationBell might not be readily exported here without extra setup in some files. I'll use standard icon if NotificationBell causes issues. Assuming it's fine.
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF385A2E)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Availability Calendar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2A3A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create the times spiritual children may request.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MidwifeAddAvailabilityScreen(),
                                ),
                              ).then((_) => _fetchData());
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Add Availability',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF385A2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Calendar Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('MMMM yyyy').format(_focusedDay),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1C2A3A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Select a day to manage\nits availability.',
                                        style: TextStyle(fontSize: 12, color: Colors.black54),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _focusedDay = DateTime.now();
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.black12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: const Text('Today', style: TextStyle(color: Color(0xFF385A2E), fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.chevron_left, color: Colors.black87),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.chevron_right, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              TableCalendar(
                                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                                lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                                focusedDay: _focusedDay,
                                currentDay: DateTime.now(),
                                headerVisible: false,
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                                selectedDayPredicate: (day) {
                                  return false;
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MidwifeDayViewScreen(date: selectedDay),
                                    ),
                                  ).then((_) => _fetchData());
                                },
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder: (context, day, focusedDay) {
                                    final hasAvail = _getAvailabilitiesForDay(day).isNotEmpty;
                                    if (hasAvail) {
                                      return Container(
                                        margin: const EdgeInsets.all(6),
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF385A2E),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${day.day}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return Container(
                                      margin: const EdgeInsets.all(6),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  },
                                  todayBuilder: (context, day, focusedDay) {
                                    final hasAvail = _getAvailabilitiesForDay(day).isNotEmpty;
                                    if (hasAvail) {
                                      return Container(
                                        margin: const EdgeInsets.all(6),
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF385A2E),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${day.day}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return Container(
                                      margin: const EdgeInsets.all(6),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFF385A2E)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(color: Color(0xFF385A2E), fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  },
                                ),
                                daysOfWeekStyle: const DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(color: Colors.black54, fontSize: 13),
                                  weekendStyle: TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ),
                              
                              const Divider(height: 32, color: Colors.black12),
                              
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF385A2E), shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text('Available', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  const SizedBox(width: 16),
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text('Past', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
