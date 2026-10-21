import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';
import 'package:cagh_frontend/shared/widgets/ethiopian_calendar_view.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

/// Shows an Ethiopian date picker dialog and returns the selected Gregorian [DateTime].
Future<DateTime?> showEthiopianDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? locale,
}) async {
  final currentLocale = locale ?? Localizations.localeOf(context).languageCode;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
  final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF315E26);
  final dialogBg = isDark ? AppColors.darkSurface : Colors.white;

  DateTime tempSelected = initialDate;
  DateTime tempFocused = initialDate;

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final ethSelected = EthiopianDate.fromGregorian(tempSelected);
          final selectedTitle = '${ethSelected.getMonthName(currentLocale)} ${ethSelected.day}, ${ethSelected.year}';

          return Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLocale.startsWith('am') ? 'የኢትዮጵያ ቀን መቁጠሪያ' : 'Ethiopian Calendar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calendar
                  EthiopianCalendarView(
                    focusedDay: tempFocused,
                    selectedDay: tempSelected,
                    firstDay: firstDate,
                    lastDay: lastDate,
                    locale: currentLocale,
                    showHeader: true,
                    onDaySelected: (selectedDay, focusedDay) {
                      setDialogState(() {
                        tempSelected = selectedDay;
                        tempFocused = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setDialogState(() {
                        tempFocused = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, tempSelected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          currentLocale.startsWith('am') ? 'ምረጥ' : 'Select',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Step for the two-step analog clock time picker.
enum _ClockPickerStep { hour, minute }

/// Shows an Ethiopian traditional time picker dialog and returns standard [TimeOfDay].
///
/// Implements a modern two-step interactive circular analog clock:
/// 1. Hour selection (1 - 12) via interactive circular dial.
/// 2. Minute selection (00, 15, 30, 45) via interactive circular dial.
///
/// Time periods are strictly limited to Morning (ጠዋት), Afternoon (ከሰዓት), and Evening (ማታ).
/// Night is completely removed.
Future<TimeOfDay?> showEthiopianTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? locale,
}) async {
  final currentLocale = locale ?? Localizations.localeOf(context).languageCode;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
  const accentGold = Color(0xFFD4AF37);
  final dialogBg = isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA);
  final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF182335);
  final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

  final initialEth = EthiopianTime.fromTimeOfDay(initialTime);

  int selectedHour = initialEth.hour;
  // Snap to 15-minute intervals by default (00, 15, 30, 45)
  int selectedMinute = (initialEth.minute / 15).round() * 15;
  if (selectedMinute >= 60) selectedMinute = 45;

  // Never allow night - only Morning, Afternoon, Evening
  EthiopianPeriod selectedPeriod = initialEth.period == EthiopianPeriod.night
      ? EthiopianPeriod.morning
      : initialEth.period;

  _ClockPickerStep currentStep = _ClockPickerStep.hour;

  return showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isAm = currentLocale.startsWith('am');

          final previewEth = EthiopianTime(
            hour: selectedHour,
            minute: selectedMinute,
            period: selectedPeriod,
          );

          return Dialog(
            backgroundColor: dialogBg,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAm ? 'የኢትዮጵያ ሰዓት ይምረጡ' : 'Select Ethiopian Time',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAm
                                  ? 'በባህላዊ የኢትዮጵያ የሰዓት አቆጣጠር'
                                  : 'Ethiopian traditional 12-hour clock',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.access_time_rounded, color: primaryColor, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Prominent Digital Time Display Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Tappable Hour Box
                              GestureDetector(
                                onTap: () => setDialogState(() => currentStep = _ClockPickerStep.hour),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: currentStep == _ClockPickerStep.hour
                                        ? (isDark ? const Color(0xFF1E3A1A) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: currentStep == _ClockPickerStep.hour
                                          ? primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: currentStep == _ClockPickerStep.hour
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    selectedHour.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: currentStep == _ClockPickerStep.hour
                                          ? primaryColor
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              // Tappable Minute Box
                              GestureDetector(
                                onTap: () => setDialogState(() => currentStep = _ClockPickerStep.minute),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: currentStep == _ClockPickerStep.minute
                                        ? (isDark ? const Color(0xFF1E3A1A) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: currentStep == _ClockPickerStep.minute
                                          ? primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: currentStep == _ClockPickerStep.minute
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    selectedMinute.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: currentStep == _ClockPickerStep.minute
                                          ? primaryColor
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Current Period Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  previewEth.getPeriodName(currentLocale),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Secondary Western Reference
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                previewEth.formatWesternReference(currentLocale),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Period Selector (Morning, Afternoon, Evening ONLY - NO Night)
                    Row(
                      children: [
                        _buildPeriodChip(
                          label: isAm ? 'ጠዋት' : 'Morning',
                          isSelected: selectedPeriod == EthiopianPeriod.morning,
                          primaryColor: primaryColor,
                          isDark: isDark,
                          onTap: () => setDialogState(() => selectedPeriod = EthiopianPeriod.morning),
                        ),
                        const SizedBox(width: 8),
                        _buildPeriodChip(
                          label: isAm ? 'ከሰዓት' : 'Afternoon',
                          isSelected: selectedPeriod == EthiopianPeriod.afternoon,
                          primaryColor: primaryColor,
                          isDark: isDark,
                          onTap: () => setDialogState(() => selectedPeriod = EthiopianPeriod.afternoon),
                        ),
                        const SizedBox(width: 8),
                        _buildPeriodChip(
                          label: isAm ? 'ማታ' : 'Evening',
                          isSelected: selectedPeriod == EthiopianPeriod.evening,
                          primaryColor: primaryColor,
                          isDark: isDark,
                          onTap: () => setDialogState(() => selectedPeriod = EthiopianPeriod.evening),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Step Indicator Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentStep == _ClockPickerStep.hour
                                ? Icons.schedule_rounded
                                : Icons.timelapse_rounded,
                            size: 15,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentStep == _ClockPickerStep.hour
                                ? (isAm ? 'ሰዓት ይምረጡ' : 'Select hour')
                                : (isAm ? 'ደቂቃ ይምረጡ' : 'Select minutes'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentStep == _ClockPickerStep.hour ? '1 / 2' : '2 / 2',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Circular Analog Clock Dial
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: _EthiopianClockDial(
                        step: currentStep,
                        selectedHour: selectedHour,
                        selectedMinute: selectedMinute,
                        isDark: isDark,
                        primaryColor: primaryColor,
                        accentGold: accentGold,
                        onHourChanged: (h) => setDialogState(() => selectedHour = h),
                        onMinuteChanged: (m) => setDialogState(() => selectedMinute = m),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentStep == _ClockPickerStep.hour)
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => setDialogState(() => currentStep = _ClockPickerStep.hour),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: Text(isAm ? 'ተመለስ' : 'Back'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        if (currentStep == _ClockPickerStep.hour)
                          ElevatedButton.icon(
                            onPressed: () => setDialogState(() => currentStep = _ClockPickerStep.minute),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            label: Text(
                              isAm ? 'ቀጣይ' : 'Next',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              elevation: 0,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              final selectedEthTime = EthiopianTime(
                                hour: selectedHour,
                                minute: selectedMinute,
                                period: selectedPeriod,
                              );
                              Navigator.pop(ctx, selectedEthTime.toTimeOfDay());
                            },
                            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                            label: Text(
                              isAm ? 'ምረጥ' : 'Confirm',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              elevation: 0,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// A period chip for Morning, Afternoon, Evening (Night removed).
Widget _buildPeriodChip({
  required String label,
  required bool isSelected,
  required Color primaryColor,
  required bool isDark,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// An interactive analog clock dial widget that responds to both tap and drag gestures.
class _EthiopianClockDial extends StatelessWidget {
  final _ClockPickerStep step;
  final int selectedHour;
  final int selectedMinute;
  final bool isDark;
  final Color primaryColor;
  final Color accentGold;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const _EthiopianClockDial({
    required this.step,
    required this.selectedHour,
    required this.selectedMinute,
    required this.isDark,
    required this.primaryColor,
    required this.accentGold,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  void _handleTouch(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 12) return; // Dead zone around center hub

    final angle = atan2(dy, dx);
    // Normalize angle to [0, 2*pi) where 0 is 12 o'clock (top)
    var phi = angle + (pi / 2);
    if (phi < 0) phi += 2 * pi;

    if (step == _ClockPickerStep.hour) {
      final sector = ((phi + (pi / 12)) / (pi / 6)).floor() % 12;
      final hour = sector == 0 ? 12 : sector;
      if (hour != selectedHour) {
        onHourChanged(hour);
      }
    } else {
      // 4 quadrants for 15-minute intervals: 0, 15, 30, 45
      final quad = ((phi + (pi / 4)) / (pi / 2)).floor() % 4;
      final minute = quad * 15;
      if (minute != selectedMinute) {
        onMinuteChanged(minute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _handleTouch(details.localPosition, size),
          onPanUpdate: (details) => _handleTouch(details.localPosition, size),
          onTapDown: (details) => _handleTouch(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _ClockDialPainter(
              step: step,
              selectedHour: selectedHour,
              selectedMinute: selectedMinute,
              isDark: isDark,
              primaryColor: primaryColor,
              accentGold: accentGold,
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the analog clock dial face, hands, center hub, and markers.
class _ClockDialPainter extends CustomPainter {
  final _ClockPickerStep step;
  final int selectedHour;
  final int selectedMinute;
  final bool isDark;
  final Color primaryColor;
  final Color accentGold;

  _ClockDialPainter({
    required this.step,
    required this.selectedHour,
    required this.selectedMinute,
    required this.isDark,
    required this.primaryColor,
    required this.accentGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final numRadius = radius - 28.0;

    // 1. Dial Background Plate
    final platePaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, platePaint);

    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // 2. Hand / Selection Angle
    double selectedAngle;
    if (step == _ClockPickerStep.hour) {
      final h = selectedHour % 12;
      selectedAngle = -pi / 2 + (h * 2 * pi / 12);
    } else {
      selectedAngle = -pi / 2 + (selectedMinute / 60 * 2 * pi);
    }

    final selPos = Offset(
      center.dx + numRadius * cos(selectedAngle),
      center.dy + numRadius * sin(selectedAngle),
    );

    // 3. Hand Line
    final handPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, selPos, handPaint);

    // 4. Center Pivot Hub (Green with Gold Inner Dot)
    final centerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, centerPaint);

    final centerGoldPaint = Paint()
      ..color = accentGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, centerGoldPaint);

    // 5. Selection Circle at Selected Value with Gold Rim
    final selCirclePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(selPos, 18.0, selCirclePaint);

    final selRingPaint = Paint()
      ..color = accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(selPos, 18.0, selRingPaint);

    // 6. Draw Dial Numbers and Markers
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (step == _ClockPickerStep.hour) {
      for (int h = 1; h <= 12; h++) {
        final angle = -pi / 2 + ((h % 12) * 2 * pi / 12);
        final pos = Offset(
          center.dx + numRadius * cos(angle),
          center.dy + numRadius * sin(angle),
        );
        final isSelected = h == selectedHour;

        textPainter.text = TextSpan(
          text: '$h',
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
            fontSize: isSelected ? 15 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
        );
      }
    } else {
      // Minute Step: 00, 15, 30, 45 with tick dots for intermediate 5-minute ticks
      const minutes = [0, 15, 30, 45];
      final tickPaint = Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 12; i++) {
        final m = i * 5;
        if (!minutes.contains(m)) {
          final angle = -pi / 2 + (m / 60 * 2 * pi);
          final pos = Offset(
            center.dx + numRadius * cos(angle),
            center.dy + numRadius * sin(angle),
          );
          canvas.drawCircle(pos, 2.5, tickPaint);
        }
      }

      for (final m in minutes) {
        final angle = -pi / 2 + (m / 60 * 2 * pi);
        final pos = Offset(
          center.dx + numRadius * cos(angle),
          center.dy + numRadius * sin(angle),
        );
        final isSelected = m == selectedMinute;

        textPainter.text = TextSpan(
          text: m.toString().padLeft(2, '0'),
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
            fontSize: isSelected ? 15 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}
