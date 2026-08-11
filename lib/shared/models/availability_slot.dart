class AvailabilitySlot {
  final String availabilityId;
  final String midwifeId;
  final String dateOrDay; // e.g. "Monday" or "2023-10-15"
  final String startTime;
  final String endTime;
  final int? durationMinutes;
  final String status; // e.g. "AVAILABLE", "BOOKED"

  AvailabilitySlot({
    required this.availabilityId,
    required this.midwifeId,
    required this.dateOrDay,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    required this.status,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      availabilityId: json['availability_id'] ?? json['id'] ?? '',
      midwifeId: json['midwife_id'] ?? '',
      dateOrDay: json['date_or_day'] ?? json['date'] ?? json['day'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      status: json['status'] ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availability_id': availabilityId,
      'midwife_id': midwifeId,
      'date_or_day': dateOrDay,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'status': status,
    };
  }
}
