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
        SnackBar(content: Text(AppLocalizations.of(context)!.addedWorkingHoursSuccessfully), backgroundColor: Colors.green),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToAddWorkingHours}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addBlockedDateAction() async {
    if (_blockedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectDateToBlock), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final dateStr = "${_blockedDate!.year}-${_blockedDate!.month.toString().padLeft(2, '0')}-${_blockedDate!.day.toString().padLeft(2, '0')}";
      await _midwifeRepository.addBlockedDate(dateStr, _blockReasonController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.preferencesSaved), backgroundColor: Colors.green),
      );
      _blockedDate = null;
      _blockReasonController.clear();
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateStatus}: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageSchedule),
        backgroundColor: const Color(0xFF315E26),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF315E26)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form 1: Add Recurring Availability
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.addAvailability, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDayOfWeek,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.dayOfWeek,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.startTime,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.endTime,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF315E26)),
                            child: Text(AppLocalizations.of(context)!.addTimeRange, style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  Text(
                    AppLocalizations.of(context)!.currentAvailabilities,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 12),
                  if (_availabilities.isEmpty)
                    Text(AppLocalizations.of(context)!.noWorkingHoursConfigured, style: const TextStyle(color: Colors.grey))
                  else
                    ..._availabilities.map((avail) {
                      final dayName = avail.date ?? (avail.dayOfWeek != null ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][avail.dayOfWeek!.clamp(0, 6)] : 'Unknown');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.access_time, color: Color(0xFF315E26)),
                          title: Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${avail.startTime} - ${avail.endTime}'),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Form 2: Block Specific Dates
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.addBlockedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.reasonOptional,
                            hintText: 'e.g. Annual Leave, Holiday',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Text(AppLocalizations.of(context)!.noBlockedDates, style: const TextStyle(color: Colors.grey))
                  else
                    ..._blockedDates.map((block) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.block, color: Colors.red),
                          title: Text(block.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(block.reason),
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

