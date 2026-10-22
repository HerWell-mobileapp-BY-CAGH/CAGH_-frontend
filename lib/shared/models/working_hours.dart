import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';

class WorkingHours {
  final String id;
  final int? dayOfWeek; // 0 = Monday, 6 = Sunday
  final String? dayNameFromBackend;
  final String? date;
  final String startTime;
  final String endTime;
  final bool isActive;

  WorkingHours({
    required this.id,
    this.dayOfWeek,
    this.dayNameFromBackend,
    this.date,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    int? parsedDay;
    if (json['day_of_week'] != null) {
      parsedDay = int.tryParse(json['day_of_week'].toString());
    }

    final dateStr = json['date']?.toString();
    if (parsedDay == null && dateStr != null && dateStr.isNotEmpty) {
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        parsedDay = parsedDate.weekday - 1; // 0 = Monday, 6 = Sunday
      }
    }

    return WorkingHours(
      id: json['id']?.toString() ?? json['availability_id']?.toString() ?? '',
      dayOfWeek: parsedDay,
      dayNameFromBackend: json['day_name']?.toString(),
      date: dateStr,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  String get dayName {
    if (dayNameFromBackend != null && dayNameFromBackend!.isNotEmpty) {
      return dayNameFromBackend!;
    }
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek != null && dayOfWeek! >= 0 && dayOfWeek! < 7) {
      if (date != null && date!.isNotEmpty) {
        return '${days[dayOfWeek!]} ($date)';
      }
      return days[dayOfWeek!];
    }
    return date ?? 'Scheduled Day';
  }

  String localizedDayName([String? locale]) {
    if (dayNameFromBackend != null && dayNameFromBackend!.isNotEmpty) {
      return dayNameFromBackend!;
    }
    const daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const daysAm = ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ', 'እሑድ'];
    final isAm = (locale ?? 'en').toLowerCase().startsWith('am');
    final days = isAm ? daysAm : daysEn;
    if (dayOfWeek != null && dayOfWeek! >= 0 && dayOfWeek! < 7) {
      if (date != null && date!.isNotEmpty) {
        return '${days[dayOfWeek!]} ($date)';
      }
      return days[dayOfWeek!];
    }
    return date ?? (isAm ? 'የተመደበ ቀን' : 'Scheduled Day');
  }

  String get formattedTimeRange => formattedEthiopianTimeRange();

  String formattedEthiopianTimeRange([String? locale]) {
    return EthiopianDateHelper.formatEthiopianTimeRange(startTime, endTime, locale: locale ?? 'en');
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (date != null) 'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
    };
  }
}
