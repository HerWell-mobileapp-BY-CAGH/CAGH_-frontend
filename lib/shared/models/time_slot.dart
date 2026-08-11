class TimeSlot {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TimeSlot({
    this.id = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isAvailable: json['is_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };
  }
}
