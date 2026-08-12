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
  final String? patientPhone;
  String? midwifeName;

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
    this.patientPhone,
    this.midwifeName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    String? parsedPatientName = json['user_full_name'] ?? json['patient_name'];
    String? parsedPatientPhone = json['patient_phone'] ?? json['user_phone'];
    String? parsedMidwifeName = json['midwife_name'] ?? json['midwife_full_name'];

    // Try parsing nested user/patient object
    if (json['patient'] is Map) {
      final p = json['patient'];
      parsedPatientName ??= p['full_name'] ?? p['name'] ?? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
      parsedPatientPhone ??= p['phone'] ?? p['phone_number'];
    }
    if (json['user'] is Map) {
      final u = json['user'];
      parsedPatientName ??= u['full_name'] ?? u['name'] ?? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
      parsedPatientPhone ??= u['phone'] ?? u['phone_number'];
    }

    // Try parsing nested midwife object
    if (json['midwife'] is Map) {
      final m = json['midwife'];
      parsedMidwifeName ??= m['full_name'] ?? m['name'] ?? m['midwife_name'] ?? '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
      if (m['user'] is Map) {
        parsedMidwifeName ??= m['user']['full_name'] ?? m['user']['name'] ?? '${m['user']['first_name'] ?? ''} ${m['user']['last_name'] ?? ''}'.trim();
      }
    }
    if (json['midwife_detail'] is Map) {
      final md = json['midwife_detail'];
      parsedMidwifeName ??= md['full_name'] ?? md['name'] ?? md['midwife_name'] ?? '${md['first_name'] ?? ''} ${md['last_name'] ?? ''}'.trim();
      if (md['user'] is Map) {
        parsedMidwifeName ??= md['user']['full_name'] ?? md['user']['name'] ?? '${md['user']['first_name'] ?? ''} ${md['user']['last_name'] ?? ''}'.trim();
      }
    }
    if (json['midwife_id'] is Map) {
      final mi = json['midwife_id'];
      parsedMidwifeName ??= mi['full_name'] ?? mi['name'] ?? mi['midwife_name'] ?? '${mi['first_name'] ?? ''} ${mi['last_name'] ?? ''}'.trim();
      if (mi['user'] is Map) {
        parsedMidwifeName ??= mi['user']['full_name'] ?? mi['user']['name'] ?? '${mi['user']['first_name'] ?? ''} ${mi['user']['last_name'] ?? ''}'.trim();
      }
    }
    if (json['midwife_profile'] is Map) {
      final mp = json['midwife_profile'];
      parsedMidwifeName ??= mp['full_name'] ?? mp['name'] ?? mp['midwife_name'] ?? '${mp['first_name'] ?? ''} ${mp['last_name'] ?? ''}'.trim();
      if (mp['user'] is Map) {
        parsedMidwifeName ??= mp['user']['full_name'] ?? mp['user']['name'] ?? '${mp['user']['first_name'] ?? ''} ${mp['user']['last_name'] ?? ''}'.trim();
      }
    }

    // Safely extract IDs if they are nested
    String safeUserId = json['user_id']?.toString() ?? '';
    if (safeUserId.isEmpty && json['user'] != null) {
      safeUserId = json['user'] is Map ? (json['user']['id']?.toString() ?? '') : json['user'].toString();
    }
    if (safeUserId.isEmpty && json['patient'] != null) {
      safeUserId = json['patient'] is Map ? (json['patient']['id']?.toString() ?? '') : json['patient'].toString();
    }
    if (safeUserId.isEmpty && json['user_detail'] != null) {
      safeUserId = json['user_detail'] is Map ? (json['user_detail']['id']?.toString() ?? '') : json['user_detail'].toString();
    }

    String safeMidwifeId = json['midwife_id']?.toString() ?? '';
    if (safeMidwifeId.isEmpty && json['midwife'] != null) {
      safeMidwifeId = json['midwife'] is Map ? (json['midwife']['id']?.toString() ?? '') : json['midwife'].toString();
    }
    if (safeMidwifeId.isEmpty && json['midwife_detail'] != null) {
      safeMidwifeId = json['midwife_detail'] is Map ? (json['midwife_detail']['id']?.toString() ?? '') : json['midwife_detail'].toString();
    }

    if (parsedPatientName != null && parsedPatientName.isEmpty) parsedPatientName = null;
    if (parsedMidwifeName != null && parsedMidwifeName.isEmpty) parsedMidwifeName = null;

    return Appointment(
      appointmentId: json['id']?.toString() ?? json['appointment_id']?.toString() ?? '',
      appointmentNumber: json['appointment_number'],
      userId: safeUserId,
      midwifeId: safeMidwifeId,
      availabilityId: json['availability_id']?.toString(),
      date: json['scheduled_date'] ?? json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      appointmentType: json['appointment_type'] ?? json['consultation_type'] ?? '',
      status: AppointmentStatus.fromString(json['status'] ?? ''),
      reason: json['reason'] ?? json['note'],
      fee: json['fee']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      userFullName: parsedPatientName,
      patientPhone: parsedPatientPhone,
      midwifeName: parsedMidwifeName,
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
