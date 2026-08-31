import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';
import 'package:cagh_frontend/shared/models/blocked_date.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

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

  int _selectedDayOfWeek = 0; // 0 = Monday, 6 = Sunday
  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  final TextEditingController _blockReasonController = TextEditingController();
  DateTime? _blockedDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final availabilities = await _appointmentRepository.getAvailabilities();
      if (mounted) {
        setState(() => _availabilities = availabilities);
      }
    } catch (e) {
      AppLogger.d('Error fetching availabilities: $e');
    }

    try {
      final blocked = await _midwifeRepository.getBlockedDates();
      if (mounted) {
        setState(() => _blockedDates = blocked);
      }
    } catch (e) {
      AppLogger.d('Error fetching blocked dates: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWorkingHours() async {
    setState(() => _isSaving = true);
    try {
      final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

      await _appointmentRepository.setAvailability({
        'day_of_week': _selectedDayOfWeek,
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

  Future<void> _addBlockedDateAction() async {
    if (_blockedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date to block.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final dateStr = "${_blockedDate!.year}-${_blockedDate!.month.toString().padLeft(2, '0')}-${_blockedDate!.day.toString().padLeft(2, '0')}";
      await _midwifeRepository.addBlockedDate(dateStr, _blockReasonController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocked date added successfully!'), backgroundColor: Colors.green),
      );
      _blockedDate = null;
      _blockReasonController.clear();
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add blocked date: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _blockReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: Color(0xFF315E26),
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.manageSchedule, style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF315E26)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.setWorkingHours,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.defineRegularWorkingHours,
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
                      Text(AppLocalizations.of(context)!.addAvailability, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedDayOfWeek,
                        decoration: const InputDecoration(
                          labelText: 'Day of Week',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: List.generate(7, (index) {
                          return DropdownMenuItem(
                            value: index,
                            child: Text(_daysOfWeek[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDayOfWeek = val);
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
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF315E26)),
                          child: Text(AppLocalizations.of(context)!.addTimeRange, style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),
                
                Text(
                  AppLocalizations.of(context)!.currentAvailabilities,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                if (_availabilities.isEmpty)
                  const Text('No working hours configured yet.', style: TextStyle(color: Colors.grey))
                else
                  ..._availabilities.map((avail) {
                    final dayName = avail.date ?? (avail.dayOfWeek != null ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][avail.dayOfWeek!.clamp(0, 6)] : 'Unknown');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFF315E26)),
                        title: Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${avail.startTime} - ${avail.endTime}'),
                        trailing: Icon(
                          avail.isActive ? Icons.check_circle : Icons.cancel,
                          color: avail.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  }),

                SizedBox(height: 32),
                Text(
                  AppLocalizations.of(context)!.manageBlockedDates,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Block out specific dates (e.g. holidays, conferences, or leave) so patients cannot book them.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Add Blocked Date Form
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
                      Text(AppLocalizations.of(context)!.addBlockedDate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) setState(() => _blockedDate = date);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.selectDate,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: Text(_blockedDate == null ? 'Not selected' : '${_blockedDate!.year}-${_blockedDate!.month}-${_blockedDate!.day}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _blockReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason (Optional)',
                          hintText: 'e.g. Annual Leave, Holiday',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _addBlockedDateAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(AppLocalizations.of(context)!.blockDate),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
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

