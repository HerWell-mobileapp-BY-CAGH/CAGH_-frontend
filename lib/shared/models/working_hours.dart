class WorkingHours {
  final String id;
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String startTime;
  final String endTime;
  final bool isActive;

  WorkingHours({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      id: json['id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
    };
  }
}
