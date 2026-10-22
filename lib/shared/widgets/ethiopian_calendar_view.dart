import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';

/// A reusable calendar widget displaying the Ethiopian (Ge'ez) calendar month.
class EthiopianCalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final String locale;
  final bool showHeader;
  final bool Function(DateTime day)? enabledDayPredicate;
  final List<dynamic> Function(DateTime day)? eventLoader;
  final void Function(DateTime selectedDay, DateTime focusedDay)? onDaySelected;
  final void Function(DateTime focusedDay)? onPageChanged;

  const EthiopianCalendarView({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    this.firstDay,
    this.lastDay,
    this.locale = 'en',
    this.showHeader = true,
    this.enabledDayPredicate,
    this.eventLoader,
    this.onDaySelected,
    this.onPageChanged,
  });

  void _goToPreviousMonth() {
    final eth = EthiopianDate.fromGregorian(focusedDay);
    int m = eth.month - 1;
    int y = eth.year;
    if (m < 1) {
      m = 13;
      y -= 1;
    }
    final newFocused = EthiopianDate(y, m, 1).toGregorian();
    onPageChanged?.call(newFocused);
  }

  void _goToNextMonth() {
    final eth = EthiopianDate.fromGregorian(focusedDay);
    int m = eth.month + 1;
    int y = eth.year;
    if (m > 13) {
      m = 1;
      y += 1;
    }
    final newFocused = EthiopianDate(y, m, 1).toGregorian();
    onPageChanged?.call(newFocused);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAm = locale.toLowerCase().startsWith('am');
    final ethFocused = EthiopianDate.fromGregorian(focusedDay);
    final int ethYear = ethFocused.year;
    final int ethMonth = ethFocused.month;
    final int daysInMonth = EthiopianDate.daysInMonth(ethYear, ethMonth);

    // Calculate weekday of Ethiopian 1st day of month (Monday = 1, Sunday = 7)
    final firstDayGregorian = EthiopianDate(ethYear, ethMonth, 1).toGregorian();
    final int leadingEmpty = firstDayGregorian.weekday - 1; // 0 to 6

    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final eventCircleColor = const Color(0xFF385A2E);
    final weekdays = isAm ? EthiopianDate.weekdayShortAm : EthiopianDate.weekdayShortEn;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalSlots = leadingEmpty + daysInMonth;
    final numRows = (totalSlots + 6) ~/ 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ethFocused.getMonthName(locale)} $ethYear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF182335),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 22,
                      color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                      visualDensity: VisualDensity.compact,
                      onPressed: _goToPreviousMonth,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 22,
                      color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                      visualDensity: VisualDensity.compact,
                      onPressed: _goToNextMonth,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: weekdays.map((wd) {
              return Expanded(
                child: Center(
                  child: Text(
                    wd,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Days Grid as Rows
        ...List.generate(numRows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: List.generate(7, (colIndex) {
                final slotIndex = rowIndex * 7 + colIndex;
                final dayNumber = slotIndex - leadingEmpty + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 38));
                }

                final ethDay = EthiopianDate(ethYear, ethMonth, dayNumber);
                final gregDate = ethDay.toGregorian();
                final gregDayClean = DateTime(gregDate.year, gregDate.month, gregDate.day);

                // Check enabled status
                bool isEnabled = true;
                if (firstDay != null && gregDayClean.isBefore(DateTime(firstDay!.year, firstDay!.month, firstDay!.day))) {
                  isEnabled = false;
                }
                if (lastDay != null && gregDayClean.isAfter(DateTime(lastDay!.year, lastDay!.month, lastDay!.day))) {
                  isEnabled = false;
                }
                if (enabledDayPredicate != null && !enabledDayPredicate!(gregDayClean)) {
                  isEnabled = false;
                }

                // Check selected status
                final isSelected = selectedDay != null &&
                    selectedDay!.year == gregDate.year &&
                    selectedDay!.month == gregDate.month &&
                    selectedDay!.day == gregDate.day;

                // Check today status
                final isToday = gregDayClean == today;

                // Check events
                final events = eventLoader?.call(gregDayClean) ?? const [];
                final hasEvents = events.isNotEmpty;

                Color? bgColor;
                BoxBorder? border;
                Color textColor;
                FontWeight fontWeight = FontWeight.w500;

                if (isSelected) {
                  bgColor = primaryColor;
                  textColor = Colors.white;
                  fontWeight = FontWeight.bold;
                } else if (hasEvents) {
                  bgColor = eventCircleColor;
                  textColor = Colors.white;
                  fontWeight = FontWeight.bold;
                } else if (isToday) {
                  border = Border.all(color: primaryColor, width: 1.5);
                  textColor = isDark ? Colors.white : primaryColor;
                  fontWeight = FontWeight.bold;
                } else if (!isEnabled) {
                  textColor = isDark ? Colors.white24 : Colors.grey.shade300;
                  fontWeight = FontWeight.normal;
                } else {
                  textColor = isDark ? Colors.white : Colors.black87;
                }

                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isEnabled
                              ? () => onDaySelected?.call(gregDate, focusedDay)
                              : null,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                              border: border,
                            ),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                fontWeight: fontWeight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
