import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class MidwifeManageScheduleScreen extends StatefulWidget {
  const MidwifeManageScheduleScreen({super.key});

  @override
  State<MidwifeManageScheduleScreen> createState() => _MidwifeManageScheduleScreenState();
}

class _MidwifeManageScheduleScreenState extends State<MidwifeManageScheduleScreen> {
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());

  bool _isLoading = true;
  bool _isSaving = false;

  List<WorkingHours> _availabilities = [];

  int _selectedDayOfWeek = 0; // 0 = Monday, 6 = Sunday
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

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

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.addedWorkingHoursSuccessfully,
          isSuccess: true,
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '${AppLocalizations.of(context)!.failedToAddWorkingHours}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF385A2E);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.black12;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF182335);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.manageAvailability,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFF385A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Card: Add Working Hours
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceVariant : primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.more_time_rounded, color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.addAvailability,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Set recurring weekly available hours',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Day Selector Chips
                        Text(
                          AppLocalizations.of(context)!.dayOfWeek,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _daysOfWeek.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedDayOfWeek == index;
                              final dayShort = _daysOfWeek[index].substring(0, 3);
                              return GestureDetector(
                                onTap: () => setState(() => _selectedDayOfWeek = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? buttonGreen
                                        : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F1)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? buttonGreen : (isDark ? AppColors.darkBorder : Colors.transparent),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      dayShort,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Start Time & End Time Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePickerCard(
                                context,
                                label: AppLocalizations.of(context)!.startTime,
                                time: _startTime,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: _startTime);
                                  if (time != null) setState(() => _startTime = time);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimePickerCard(
                                context,
                                label: AppLocalizations.of(context)!.endTime,
                                time: _endTime,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: _endTime);
                                  if (time != null) setState(() => _endTime = time);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save Working Hours Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _addWorkingHours,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    AppLocalizations.of(context)!.addTimeRange,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Configured Working Hours Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.currentAvailabilities,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_availabilities.length} Active',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_availabilities.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined, size: 44, color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.noWorkingHoursConfigured,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._availabilities.map((avail) {
                      final dayIndex = avail.dayOfWeek ?? 0;
                      final dayName = avail.date ??
                          (dayIndex >= 0 && dayIndex < 7 ? _daysOfWeek[dayIndex] : 'Working Day');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEBF3EA),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.access_time_filled, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayName,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${avail.startTime} – ${avail.endTime}',
                                    style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTimePickerCard(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required bool isDark,
    required Color primaryColor,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                Icon(Icons.access_time_rounded, size: 18, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
