class TimeSlot {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String displayTime;
  final bool isAvailable;

  TimeSlot({
    this.id = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.displayTime = '',
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      displayTime: json['start_time_12h'] ?? json['start_time'] ?? '',
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
