import 'package:flutter/material.dart';

/// Enum representing the 4 traditional Ethiopian day/night periods.
enum EthiopianPeriod {
  morning,   // 06:00 - 11:59 standard (ጠዋት)
  afternoon, // 12:00 - 17:59 standard (ከሰዓት)
  evening,   // 18:00 - 23:59 standard (ማታ)
  night,     // 00:00 - 05:59 standard (ሌሊት)
}

/// Represents a date in the Ethiopian Calendar (Ge'ez calendar).
class EthiopianDate {
  final int year;
  final int month; // 1 to 13
  final int day;   // 1 to 30 (or 1 to 5/6 for Pagume)

  const EthiopianDate(this.year, this.month, this.day);

  /// Month names in English.
  static const List<String> monthNamesEn = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yakatit',
    'Magabit',
    'Miyazya',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  /// Month names in Amharic.
  static const List<String> monthNamesAm = [
    'መስከረም',
    'ጥቅምት',
    'ኅዳር',
    'ታኅሣሥ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜ',
  ];

  /// Weekday names in English (Monday = 1, Sunday = 7).
  static const List<String> weekdayNamesEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Weekday names in Amharic (Monday = 1, Sunday = 7).
  static const List<String> weekdayNamesAm = [
    'ሰኞ',
    'ማክሰኞ',
    'ረቡዕ',
    'ሐሙስ',
    'ዓርብ',
    'ቅዳሜ',
    'እሑድ',
  ];

  /// Short weekday names in English.
  static const List<String> weekdayShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Short weekday names in Amharic.
  static const List<String> weekdayShortAm = ['ሰኞ', 'ማክ', 'ረቡ', 'ሐሙ', 'ዓር', 'ቅዳ', 'እሑ'];

  /// Returns true if [year] is an Ethiopian leap year (year % 4 == 3).
  static bool isLeapYear(int year) => year % 4 == 3;

  /// Returns the number of days in the specified Ethiopian month.
  static int daysInMonth(int year, int month) {
    if (month >= 1 && month <= 12) return 30;
    if (month == 13) return isLeapYear(year) ? 6 : 5;
    throw ArgumentError('Invalid Ethiopian month: $month. Must be 1 to 13.');
  }

  /// Month name localized.
  String getMonthName(String locale) {
    final list = locale.toLowerCase().startsWith('am') ? monthNamesAm : monthNamesEn;
    if (month >= 1 && month <= 13) return list[month - 1];
    return 'Month $month';
  }

  /// Julian Day Number constant for Ethiopian epoch (Meskerem 1, 1 E.C.).
  static const int _jdnEpoch = 1724221;

  /// Converts a Gregorian [DateTime] to an [EthiopianDate].
  factory EthiopianDate.fromGregorian(DateTime dt) {
    final jdn = _gregorianToJdn(dt.year, dt.month, dt.day);
    return _jdnToEthiopian(jdn);
  }

  /// Converts this [EthiopianDate] to a Gregorian [DateTime].
  DateTime toGregorian() {
    final jdn = _ethiopianToJdn(year, month, day);
    return _jdnToGregorian(jdn);
  }

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);
    return DateTime(year, month, day);
  }

  static EthiopianDate _jdnToEthiopian(int jdn) {
    final r = jdn - _jdnEpoch;
    final c = r ~/ 1461;
    final d = r % 1461;

    int cycleYear;
    int dayOfYear;

    if (d < 365) {
      cycleYear = 0;
      dayOfYear = d;
    } else if (d < 730) {
      cycleYear = 1;
      dayOfYear = d - 365;
    } else if (d < 1096) {
      cycleYear = 2;
      dayOfYear = d - 730;
    } else {
      cycleYear = 3;
      dayOfYear = d - 1096;
    }

    final year = 4 * c + cycleYear + 1;
    int month;
    int day;

    if (dayOfYear < 360) {
      month = (dayOfYear ~/ 30) + 1;
      day = (dayOfYear % 30) + 1;
    } else {
      month = 13;
      day = dayOfYear - 360 + 1;
    }

    return EthiopianDate(year, month, day);
  }

  static int _ethiopianToJdn(int year, int month, int day) {
    final completedYears = year - 1;
    final cycles = completedYears ~/ 4;
    final remYears = completedYears % 4;

    int daysInRemYears = 0;
    for (int y = 0; y < remYears; y++) {
      daysInRemYears += (y == 2) ? 366 : 365;
    }

    final daysInCurrentYear = (month - 1) * 30 + (day - 1);
    final totalDays = cycles * 1461 + daysInRemYears + daysInCurrentYear;
    return _jdnEpoch + totalDays;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthiopianDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Represents traditional Ethiopian clock time.
///
/// Ethiopian time is shifted by 6 hours from standard local 24-hour time:
/// - 06:00 standard = 12:00 morning (ጠዋት)
/// - 08:00 standard = 2:00 morning (ጠዋት)
/// - 12:00 standard = 6:00 afternoon (ከሰዓት)
/// - 14:00 standard = 8:00 afternoon (ከሰዓት)
/// - 18:00 standard = 12:00 evening (ማታ)
/// - 20:00 standard = 2:00 evening (ማታ)
/// - 00:00 standard = 6:00 night (ሌሊት)
/// - 02:00 standard = 8:00 night (ሌሊት)
class EthiopianTime {
  final int hour; // 1 to 12
  final int minute; // 0 to 59
  final EthiopianPeriod period;

  const EthiopianTime({
    required this.hour,
    required this.minute,
    required this.period,
  });

  /// Period names in English.
  static const Map<EthiopianPeriod, String> periodNamesEn = {
    EthiopianPeriod.morning: 'morning',
    EthiopianPeriod.afternoon: 'afternoon',
    EthiopianPeriod.evening: 'evening',
    EthiopianPeriod.night: 'night',
  };

  /// Period names in Amharic.
  static const Map<EthiopianPeriod, String> periodNamesAm = {
    EthiopianPeriod.morning: 'ጠዋት',
    EthiopianPeriod.afternoon: 'ከሰዓት',
    EthiopianPeriod.evening: 'ማታ',
    EthiopianPeriod.night: 'ሌሊት',
  };

  /// Converts standard 24-hour hour & minute into [EthiopianTime].
  factory EthiopianTime.fromStandard(int stdHour, int stdMinute) {
    final normalizedHour = (stdHour % 24 + 24) % 24;
    final normalizedMinute = stdMinute.clamp(0, 59);

    int ethHour = (normalizedHour - 6) % 12;
    if (ethHour <= 0) ethHour += 12;

    EthiopianPeriod period;
    if (normalizedHour >= 6 && normalizedHour < 12) {
      period = EthiopianPeriod.morning;
    } else if (normalizedHour >= 12 && normalizedHour < 18) {
      period = EthiopianPeriod.afternoon;
    } else if (normalizedHour >= 18 && normalizedHour < 24) {
      period = EthiopianPeriod.evening;
    } else {
      period = EthiopianPeriod.night;
    }

    return EthiopianTime(hour: ethHour, minute: normalizedMinute, period: period);
  }

  /// Converts standard [TimeOfDay] into [EthiopianTime].
  factory EthiopianTime.fromTimeOfDay(TimeOfDay tod) {
    return EthiopianTime.fromStandard(tod.hour, tod.minute);
  }

  /// Converts a standard 24-hour time string (e.g. "08:30" or "14:00:00") into [EthiopianTime].
  factory EthiopianTime.fromStandardString(String timeStr) {
    if (timeStr.isEmpty) {
      return const EthiopianTime(hour: 12, minute: 0, period: EthiopianPeriod.morning);
    }
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return EthiopianTime.fromStandard(hour, minute);
  }

  /// Converts this [EthiopianTime] back to standard local 24-hour hour (0..23).
  int toStandardHour() {
    switch (period) {
      case EthiopianPeriod.morning:
        return (hour % 12) + 6; // 12 -> 6, 1 -> 7, 2 -> 8 ... 5 -> 11
      case EthiopianPeriod.afternoon:
        if (hour >= 6 && hour <= 11) return hour + 6; // 6 -> 12, 7 -> 13, 8 -> 14 ... 11 -> 17
        if (hour == 12) return 18; // 12:00 afternoon is 18:00 (6:00 PM sunset)
        return hour + 12; // 1 -> 13, 2 -> 14 etc.
      case EthiopianPeriod.evening:
        if (hour == 12) return 18;
        if (hour <= 5) return hour + 18; // 1 -> 19, 2 -> 20 ... 5 -> 23
        return hour + 12;
      case EthiopianPeriod.night:
        if (hour >= 6 && hour <= 11) return hour - 6; // 6 -> 0, 7 -> 1 ... 11 -> 5
        if (hour == 12) return 0;
        return hour;
    }
  }

  /// Converts this [EthiopianTime] to standard [TimeOfDay].
  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: toStandardHour(), minute: minute);
  }

  /// Converts to standard HH:mm:ss format for backend API.
  String toStandardTimeString() {
    final stdH = toStandardHour().toString().padLeft(2, '0');
    final stdM = minute.toString().padLeft(2, '0');
    return '$stdH:$stdM:00';
  }

  /// Returns localized period label.
  String getPeriodName(String locale) {
    final map = locale.toLowerCase().startsWith('am') ? periodNamesAm : periodNamesEn;
    return map[period] ?? '';
  }

  /// Formats in Ethiopian traditional time:
  /// English: `2:00 morning`
  /// Amharic: `2:00 ጠዋት`
  String format(String locale, {bool padZero = false}) {
    final hStr = padZero ? hour.toString().padLeft(2, '0') : hour.toString();
    final mStr = minute.toString().padLeft(2, '0');
    final pStr = getPeriodName(locale);
    return '$hStr:$mStr $pStr';
  }

  /// Formats the corresponding Western time as a secondary reference.
  ///
  /// Examples:
  /// - `8:30 AM (Western Time)`
  /// - `8:30 AM (የምዕራባውያን ሰዓት)`
  String formatWesternReference([String locale = 'en']) {
    final stdH = toStandardHour();
    final h12 = stdH % 12 == 0 ? 12 : stdH % 12;
    final mStr = minute.toString().padLeft(2, '0');
    final amPm = stdH >= 12 ? 'PM' : 'AM';
    final isAm = locale.toLowerCase().startsWith('am');
    final label = isAm ? 'የምዕራባውያን ሰዓት' : 'Western Time';
    return '$h12:$mStr $amPm ($label)';
  }

  @override
  String toString() => '$hour:${minute.toString().padLeft(2, '0')} ${period.name}';
}

/// Helpers for formatting Ethiopian dates and traditional times across the app.
class EthiopianDateHelper {
  /// Formats a Gregorian [DateTime] into a localized Ethiopian date string.
  ///
  /// Examples:
  /// - English: `Tikimt 10, 2019` or `Tuesday, Tikimt 10, 2019`
  /// - Amharic: `ጥቅምት 10, 2019` or `ማክሰኞ, ጥቅምት 10, 2019`
  static String formatEthiopianDate(
    DateTime gregorianDate, {
    String locale = 'en',
    bool includeWeekday = false,
  }) {
    final eth = EthiopianDate.fromGregorian(gregorianDate);
    final monthName = eth.getMonthName(locale);
    final isAm = locale.toLowerCase().startsWith('am');

    if (includeWeekday) {
      final weekdayIndex = (gregorianDate.weekday - 1).clamp(0, 6);
      final weekdayName = isAm
          ? EthiopianDate.weekdayNamesAm[weekdayIndex]
          : EthiopianDate.weekdayNamesEn[weekdayIndex];
      return '$weekdayName, $monthName ${eth.day}, ${eth.year}';
    }

    return '$monthName ${eth.day}, ${eth.year}';
  }

  /// Formats a Gregorian date string (e.g. "2026-10-20") into an Ethiopian date string.
  static String formatFromGregorianString(
    String yyyyMmDd, {
    String locale = 'en',
    bool includeWeekday = false,
  }) {
    if (yyyyMmDd.isEmpty) return '';
    try {
      final parsed = DateTime.parse(yyyyMmDd);
      return formatEthiopianDate(parsed, locale: locale, includeWeekday: includeWeekday);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  /// Formats a standard 24h time string (e.g. "08:00" or "14:30:00") into Ethiopian traditional time.
  ///
  /// Examples:
  /// - `08:00` in English -> `2:00 morning`
  /// - `08:00` in Amharic -> `2:00 ጠዋት`
  /// - `14:00` in English -> `8:00 afternoon`
  /// - `14:00` in Amharic -> `8:00 ከሰዓት`
  static String formatEthiopianTime(
    String standardTime, {
    String locale = 'en',
    bool padZero = false,
  }) {
    if (standardTime.isEmpty) return '';
    try {
      final eth = EthiopianTime.fromStandardString(standardTime);
      return eth.format(locale, padZero: padZero);
    } catch (_) {
      return standardTime;
    }
  }

  /// Formats a time range in Ethiopian traditional clock time.
  ///
  /// Examples:
  /// - English: `2:00 – 3:00 morning` or `11:00 morning – 1:00 afternoon`
  /// - Amharic: `2:00 – 3:00 ጠዋት`
  static String formatEthiopianTimeRange(
    String startTime,
    String endTime, {
    String locale = 'en',
  }) {
    if (startTime.isEmpty) return '';
    final start = EthiopianTime.fromStandardString(startTime);
    final end = endTime.isNotEmpty ? EthiopianTime.fromStandardString(endTime) : null;

    final isAm = locale.toLowerCase().startsWith('am');
    final startM = start.minute.toString().padLeft(2, '0');

    if (end == null || end.hour == start.hour && end.minute == start.minute) {
      return start.format(locale);
    }

    final endM = end.minute.toString().padLeft(2, '0');

    if (start.period == end.period) {
      final periodName = isAm
          ? EthiopianTime.periodNamesAm[start.period]
          : EthiopianTime.periodNamesEn[start.period];
      return '${start.hour}:$startM – ${end.hour}:$endM $periodName';
    } else {
      return '${start.format(locale)} – ${end.format(locale)}';
    }
  }
}
