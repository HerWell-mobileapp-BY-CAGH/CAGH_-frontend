import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _selectedDate = DateTime.tryParse(slot.dateOrDay);
      if (_selectedDate == null || _selectedDate!.isBefore(today)) {
        _selectedDate = widget.initialDate != null && !widget.initialDate!.isBefore(today) 
            ? widget.initialDate 
            : today;
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
      if (widget.initialDate != null && !widget.initialDate!.isBefore(today)) {
        _selectedDate = widget.initialDate;
      } else {
        _selectedDate = today;
      }
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = (_selectedDate != null && !_selectedDate!.isBefore(today)) ? _selectedDate! : today;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
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
      CustomSnackBar.show(context, message: AppLocalizations.of(context)!.pleaseSelectDateTime, type: SnackBarType.error);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDateOnly = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

    if (selDateOnly.isBefore(today)) {
      CustomSnackBar.show(context, message: 'Cannot schedule availability for past dates.', type: SnackBarType.error);
      return;
    }

    // Convert TimeOfDay to minutes for easy comparison
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    if (endMinutes <= startMinutes) {
      CustomSnackBar.show(context, message: AppLocalizations.of(context)!.endTimeAfterStartTime, type: SnackBarType.error);
      return;
    }

    if (selDateOnly.isAtSameMomentAs(today)) {
      final currentMinutes = now.hour * 60 + now.minute;
      if (startMinutes < currentMinutes) {
        CustomSnackBar.show(context, message: AppLocalizations.of(context)!.startTimeCannotBeInPast, type: SnackBarType.error);
        return;
      }
    }
    
    if (!_inPerson && !_voiceCall) {
      CustomSnackBar.show(context, message: AppLocalizations.of(context)!.selectConsultationMethod, type: SnackBarType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final startStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
      
      String consultType = 'VIRTUAL_VOICE';
      if (_inPerson && _voiceCall) {
        consultType = 'BOTH';
      } else if (_inPerson) {
        consultType = 'IN_PERSON';
      } else if (_voiceCall) {
        consultType = 'VIRTUAL_VOICE';
      }

      final List<String> methodsList = [];
      if (_voiceCall) methodsList.add('VIRTUAL_VOICE');
      if (_inPerson) methodsList.add('IN_PERSON');

      final List<String> typesList = [];
      if (_inPerson) typesList.add('In-Person');
      if (_voiceCall) typesList.add('Voice Call');

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final Map<String, dynamic> payload = {
        'date': dateStr,
        'start_time': startStr,
        'end_time': endStr,
        'is_in_person': _inPerson,
        'is_voice_call': _voiceCall,
        'in_person': _inPerson,
        'voice_call': _voiceCall,
        'consultation_type': consultType,
        'consultation_methods': methodsList,
        'appointment_type': consultType,
        'offered_consultation_types': typesList,
        'is_active': true,
      };

      if (widget.existingSlot != null) {
        await _api.updateAvailability(widget.existingSlot!.availabilityId, payload);
        if (mounted) {
          CustomSnackBar.show(context, message: AppLocalizations.of(context)!.availabilityUpdatedSuccess, type: SnackBarType.success);
          Navigator.pop(context, true);
        }
      } else {
        await _api.setAvailability(payload);
        if (mounted) {
          CustomSnackBar.show(context, message: AppLocalizations.of(context)!.availabilityAddedSuccess, type: SnackBarType.success);
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = '$e'.replaceAll('Exception: ', '');
        if (msg.contains('TimeoutException')) {
          msg = 'Server took too long to respond. Please check your connection and try again.';
        }
        CustomSnackBar.show(context, message: '${AppLocalizations.of(context)!.failedToAddAvailability}: $msg', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF385A2E);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.black12;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1C2A3A);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black54;
    final cancelButtonBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F1);
    final closeIconBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top Green App Bar
          Container(
            width: double.infinity,
            color: isDark ? AppColors.darkBackground : const Color(0xFF385A2E),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.schedule,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                            GlobeLanguagePicker(iconColor: Colors.white, iconSize: 22),
                            SizedBox(width: 2),
                            Icon(Icons.notifications_none, color: Colors.white, size: 22),
                            SizedBox(width: 12),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.existingSlot != null 
                            ? AppLocalizations.of(context)!.editAvailableTime 
                            : AppLocalizations.of(context)!.addAvailableTime,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: closeIconBg, shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 16, color: textSecondary),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.addTimeSubtitle,
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      AppLocalizations.of(context)!.dateTimeSection,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel(context, AppLocalizations.of(context)!.dateRequired),
                    _buildSelectorField(
                      context: context,
                      icon: Icons.calendar_today,
                      text: _selectedDate != null 
                        ? DateFormat('MMM d, yyyy', Localizations.localeOf(context).languageCode).format(_selectedDate!) 
                        : AppLocalizations.of(context)!.selectDatePrompt,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel(context, AppLocalizations.of(context)!.startTimeRequired),
                    _buildSelectorField(
                      context: context,
                      icon: Icons.access_time,
                      text: _startTime != null ? _startTime!.format(context) : AppLocalizations.of(context)!.selectStartTimePrompt,
                      onTap: () => _selectTime(true),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel(context, AppLocalizations.of(context)!.endTimeRequired),
                    _buildSelectorField(
                      context: context,
                      icon: Icons.access_time,
                      text: _endTime != null ? _endTime!.format(context) : AppLocalizations.of(context)!.selectEndTimePrompt,
                      onTap: () => _selectTime(false),
                    ),
                    const SizedBox(height: 32),
                    
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : Colors.black12),
                    const SizedBox(height: 24),
                    
                    Text(
                      AppLocalizations.of(context)!.consultationMethodSection,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildCheckboxField(context, AppLocalizations.of(context)!.inPerson, _inPerson, (v) => setState(() => _inPerson = v ?? false)),
                    const SizedBox(height: 12),
                    _buildCheckboxField(context, AppLocalizations.of(context)!.voiceCall, _voiceCall, (v) => setState(() => _voiceCall = v ?? false)),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppLocalizations.of(context)!.saveAvailability,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: cancelButtonBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
    );
  }

  Widget _buildSelectorField({required BuildContext context, required IconData icon, required String text, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? AppColors.darkSurfaceVariant : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.black12;
    final textPrimary = isDark ? AppColors.darkTextPrimary : Colors.black87;
    final hintColor = isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.6) : Colors.black45;
    final iconColor = isDark ? AppColors.darkTextSecondary : Colors.black54;

    final isPlaceholder = text.startsWith('Select') || text.startsWith('اختر') || text.startsWith('ይምረጡ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(12),
          color: fieldBg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(text, style: TextStyle(fontSize: 14, color: isPlaceholder ? hintColor : textPrimary)),
              ],
            ),
            Icon(Icons.keyboard_arrow_down, size: 20, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxField(BuildContext context, String label, bool value, ValueChanged<bool?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF9F9F9);
    final cardBorder = isDark ? AppColors.darkBorder : Colors.black12;
    final textPrimary = isDark ? AppColors.darkTextPrimary : Colors.black87;
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF385A2E);

    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: CheckboxListTile(
          title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: buttonGreen,
          checkColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          dense: true,
        ),
      ),
    );
  }
}
