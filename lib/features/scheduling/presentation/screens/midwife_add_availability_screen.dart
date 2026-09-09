import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';

class MidwifeAddAvailabilityScreen extends StatefulWidget {
  final DateTime? initialDate;
  final AvailabilitySlot? existingSlot;
  const MidwifeAddAvailabilityScreen({super.key, this.initialDate, this.existingSlot});

  @override
  State<MidwifeAddAvailabilityScreen> createState() => _MidwifeAddAvailabilityScreenState();
}

class _MidwifeAddAvailabilityScreenState extends State<MidwifeAddAvailabilityScreen> {
  final _api = AppointmentApiService();
  
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  bool _inPerson = false;
  bool _voiceCall = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _selectedDate = DateTime.tryParse(slot.dateOrDay);
      if (_selectedDate == null) {
        _selectedDate = widget.initialDate;
      }
      
      final startParts = slot.startTime.split(':');
      if (startParts.length >= 2) {
        _startTime = TimeOfDay(hour: int.tryParse(startParts[0]) ?? 0, minute: int.tryParse(startParts[1]) ?? 0);
      }
      final endParts = slot.endTime.split(':');
      if (endParts.length >= 2) {
        _endTime = TimeOfDay(hour: int.tryParse(endParts[0]) ?? 0, minute: int.tryParse(endParts[1]) ?? 0);
      }
      _inPerson = slot.isInPerson;
      _voiceCall = slot.isVoiceCall;
    } else {
      _selectedDate = widget.initialDate;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      CustomSnackBar.show(context, message: 'Please select date and time', type: SnackBarType.error);
      return;
    }

    // Convert TimeOfDay to minutes for easy comparison
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    if (endMinutes <= startMinutes) {
      CustomSnackBar.show(context, message: 'End time must be after start time', type: SnackBarType.error);
      return;
    }
    
    if (!_inPerson && !_voiceCall) {
      CustomSnackBar.show(context, message: 'Please select at least one consultation method', type: SnackBarType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final dayOfWeek = _selectedDate!.weekday - 1; // 0 = Monday, 6 = Sunday
      
      final startStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
      
      final Map<String, dynamic> payload = {
        'day_of_week': dayOfWeek,
        'start_time': startStr,
        'end_time': endStr,
        'is_in_person': _inPerson,
        'is_voice_call': _voiceCall,
        'is_active': true,
      };

      if (widget.existingSlot != null) {
        await _api.updateAvailability(widget.existingSlot!.availabilityId, payload);
        if (mounted) {
          CustomSnackBar.show(context, message: 'Availability updated successfully', type: SnackBarType.success);
          Navigator.pop(context);
        }
      } else {
        await _api.setAvailability(payload);
        if (mounted) {
          CustomSnackBar.show(context, message: 'Availability added successfully', type: SnackBarType.success);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: 'Failed to add availability: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              color: const Color(0xFF385A2E),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Row(
                        children: const [
                          GlobeLanguagePicker(iconColor: Colors.white, iconSize: 24),
                          SizedBox(width: 16),
                          Icon(Icons.notifications_none, color: Colors.white),
                          SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.existingSlot != null ? 'Edit Available Time' : 'Add Available Time',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C2A3A)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.black54),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.calendar_today, size: 18, color: Color(0xFF385A2E)),
                          SizedBox(width: 8),
                          Text('Add a time adolescent girls may request.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('DATE AND TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF385A2E))),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Date *'),
                      _buildSelectorField(
                        icon: Icons.calendar_today,
                        text: _selectedDate != null ? DateFormat('MMM d, yyyy').format(_selectedDate!) : 'Select date',
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Start time *'),
                      _buildSelectorField(
                        icon: Icons.access_time,
                        text: _startTime != null ? _startTime!.format(context) : 'Select start time',
                        onTap: () => _selectTime(true),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLabel('End time *'),
                      _buildSelectorField(
                        icon: Icons.access_time,
                        text: _endTime != null ? _endTime!.format(context) : 'Select end time',
                        onTap: () => _selectTime(false),
                      ),
                      const SizedBox(height: 32),
                      
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 24),
                      
                      const Text('CONSULTATION METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF385A2E))),
                      const SizedBox(height: 16),
                      
                      _buildCheckboxField('In person', _inPerson, (v) => setState(() => _inPerson = v ?? false)),
                      const SizedBox(height: 12),
                      _buildCheckboxField('Voice call', _voiceCall, (v) => setState(() => _voiceCall = v ?? false)),
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF385A2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Availability', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF385A2E), fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildSelectorField({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.black54),
                const SizedBox(width: 12),
                Text(text, style: TextStyle(fontSize: 14, color: text.startsWith('Select') ? Colors.black45 : Colors.black87)),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxField(String label, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        child: CheckboxListTile(
          title: Text(label, style: const TextStyle(fontSize: 14)),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFF385A2E),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    );
  }
}
