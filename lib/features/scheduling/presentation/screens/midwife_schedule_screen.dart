import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_add_availability_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_day_view_screen.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
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
    final dateString = DateFormat('yyyy-MM-dd').format(day).toLowerCase();
    final dayIndex = (day.weekday - 1).toString();
    final dayIndex1Based = day.weekday.toString();
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayName = days[day.weekday - 1];
    
    return _availabilities.where((a) {
      final d = a.dateOrDay.trim().toLowerCase();
      if (d == dateString || d == dayIndex || d == dayIndex1Based || d == dayName) {
        return true;
      }
      if (a.dayName != null && a.dayName!.trim().toLowerCase() == dayName) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF385A2E)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.availabilityCalendar,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.availabilitySubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
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
                          label: Text(
                            AppLocalizations.of(context)!.addAvailability,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
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
                                      DateFormat('MMMM yyyy', currentLocale).format(_focusedDay),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)!.selectDayToManage,
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: isDark ? Colors.grey.shade400 : Colors.black54,
                                      ),
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
                                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.today,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF385A2E), 
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.chevron_left, 
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.chevron_right, 
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            TableCalendar(
                              locale: currentLocale,
                              firstDay: DateTime.now().subtract(const Duration(days: 365)),
                              lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                              focusedDay: _focusedDay,
                              currentDay: DateTime.now(),
                              headerVisible: false,
                              enabledDayPredicate: (day) {
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                return !day.isBefore(today);
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              selectedDayPredicate: (day) {
                                return false;
                              },
                              onDaySelected: (selectedDay, focusedDay) {
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                if (selectedDay.isBefore(today)) {
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MidwifeDayViewScreen(date: selectedDay),
                                  ),
                                ).then((_) => _fetchData());
                              },
                              calendarBuilders: CalendarBuilders(
                                disabledBuilder: (context, day, focusedDay) {
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                                outsideBuilder: (context, day, focusedDay) {
                                  return Container(
                                    margin: const EdgeInsets.all(6),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
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
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87, 
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                      border: Border.all(color: const Color(0xFF385A2E), width: 1.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF385A2E), 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 13),
                                weekendStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 13),
                              ),
                            ),
                            
                            Divider(height: 32, color: Theme.of(context).dividerColor),
                            
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF385A2E), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.available, 
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.black54),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 8, 
                                  height: 8, 
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey.shade600 : Colors.black45, 
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.pastStatus, 
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.black54),
                                ),
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
    );
  }
}
