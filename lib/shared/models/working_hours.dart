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

    return WorkingHours(
      id: json['id']?.toString() ?? '',
      dayOfWeek: parsedDay,
      dayNameFromBackend: json['day_name']?.toString(),
      date: json['date']?.toString(),
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
      return days[dayOfWeek!];
    }
    return date ?? 'Scheduled Day';
  }

  String get formattedTimeRange {
    String formatTime(String t) {
      if (t.isEmpty) return '';
      final parts = t.split(':');
      if (parts.length < 2) return t;
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }

    return '${formatTime(startTime)} - ${formatTime(endTime)}';
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
