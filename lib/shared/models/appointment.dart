enum AppointmentStatus {
  pending,
  confirmed,
  declined,
  cancelled,
  completed,
  unknown;

  static AppointmentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'CONFIRMED':
        return AppointmentStatus.confirmed;
      case 'DECLINED':
        return AppointmentStatus.declined;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.unknown;
    }
  }

  String get nameStr => name.toUpperCase();
}

class Appointment {
  final String appointmentId;
  final String? appointmentNumber;
  final String userId;
  final String midwifeId;
  final String? availabilityId;
  final String date;
  final String startTime;
  final String endTime;
  final String appointmentType;
  final AppointmentStatus status;
  final String? reason;
  final String? fee;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Extra fields for UI convenience
  final String? userFullName;
  final String? midwifeName;

  Appointment({
    required this.appointmentId,
    this.appointmentNumber,
    required this.userId,
    required this.midwifeId,
    this.availabilityId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.appointmentType,
    required this.status,
    this.reason,
    this.fee,
    this.createdAt,
    this.updatedAt,
    this.userFullName,
    this.midwifeName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['id'] ?? json['appointment_id'] ?? '',
      appointmentNumber: json['appointment_number'],
      userId: json['user_id'] ?? json['user'] ?? '',
      midwifeId: json['midwife_id'] ?? json['midwife'] ?? '',
      availabilityId: json['availability_id'],
      date: json['scheduled_date'] ?? json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      appointmentType: json['appointment_type'] ?? json['consultation_type'] ?? '',
      status: AppointmentStatus.fromString(json['status'] ?? ''),
      reason: json['reason'] ?? json['note'],
      fee: json['fee'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      userFullName: json['user_full_name'],
      midwifeName: json['midwife_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': appointmentId,
      'appointment_number': appointmentNumber,
      'user': userId,
      'midwife': midwifeId,
      'availability_id': availabilityId,
      'scheduled_date': date,
      'start_time': startTime,
      'end_time': endTime,
      'appointment_type': appointmentType,
      'status': status.nameStr,
      'reason': reason,
      'fee': fee,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
