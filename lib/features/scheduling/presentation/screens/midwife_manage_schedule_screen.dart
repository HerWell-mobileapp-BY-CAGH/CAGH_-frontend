import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';
import 'package:cagh_frontend/shared/models/blocked_date.dart';

class MidwifeManageScheduleScreen extends StatefulWidget {
  const MidwifeManageScheduleScreen({super.key});

  @override
  State<MidwifeManageScheduleScreen> createState() => _MidwifeManageScheduleScreenState();
}

class _MidwifeManageScheduleScreenState extends State<MidwifeManageScheduleScreen> {
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());
  final _midwifeRepository = MidwifeRepositoryImpl(MidwifeApiService());
  
  bool _isLoading = true;
  bool _isSaving = false;

  List<WorkingHours> _availabilities = [];
  List<BlockedDate> _blockedDates = [];

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  int _selectedDay = 0; // 0 = Monday
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final availabilities = await _appointmentRepository.getAvailabilities();
      final blocked = await _midwifeRepository.getBlockedDates();
      if (mounted) {
        setState(() {
          _availabilities = availabilities;
          _blockedDates = blocked;
        });
      }
    } catch (e) {
      print('Error fetching schedule data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWorkingHours() async {
    setState(() => _isSaving = true);
    try {
      final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

      await _appointmentRepository.setAvailability({
        'day_of_week': _selectedDay,
        'start_time': startStr,
        'end_time': endStr,
        'is_active': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added working hours successfully!'), backgroundColor: Colors.green),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add working hours: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: const Text('Manage Schedule', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Working Hours',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Define your regular working hours. This will automatically generate 30-minute bookable slots for patients.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                // Add new Working Hours Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Day of Week',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: List.generate(_daysOfWeek.length, (index) {
                          return DropdownMenuItem(
                            value: index,
                            child: Text(_daysOfWeek[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDay = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: _startTime);
                                if (time != null) setState(() => _startTime = time);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Time',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: Text(_startTime.format(context)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: _endTime);
                                if (time != null) setState(() => _endTime = time);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: Text(_endTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _addWorkingHours,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                          child: const Text('Add Time Range', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                const Text(
                  'Current Availabilities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                if (_availabilities.isEmpty)
                  const Text('No working hours configured yet.', style: TextStyle(color: Colors.grey))
                else
                  ..._availabilities.map((avail) {
                    final dayName = _daysOfWeek[avail.dayOfWeek.clamp(0, 6)];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFF1B5E20)),
                        title: Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${avail.startTime} - ${avail.endTime}'),
                        trailing: Icon(
                          avail.isActive ? Icons.check_circle : Icons.cancel,
                          color: avail.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 32),
                const Text(
                  'Blocked Dates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                if (_blockedDates.isEmpty)
                  const Text('No blocked dates.', style: TextStyle(color: Colors.grey))
                else
                  ..._blockedDates.map((block) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: Text(block.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(block.reason ?? 'No reason provided'),
                      ),
                    );
                  }),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}

