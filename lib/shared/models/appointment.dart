import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/shared/utils/name_formatter.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  declined,
  cancelled,
  completed,
  missed,
  unknown;

  static AppointmentStatus fromString(String status) {
    switch (status.toUpperCase().trim()) {
      case 'PENDING':
      case 'REQUESTED':
      case 'REQUEST':
      case 'WAITING':
      case 'SCHEDULED':
        return AppointmentStatus.pending;
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'APPROVED':
      case 'ACTIVE':
        return AppointmentStatus.confirmed;
      case 'DECLINED':
      case 'REJECTED':
        return AppointmentStatus.declined;
      case 'CANCELLED':
      case 'CANCELED':
        return AppointmentStatus.cancelled;
      case 'COMPLETED':
      case 'DONE':
      case 'FINISHED':
        return AppointmentStatus.completed;
      case 'MISSED':
        return AppointmentStatus.missed;
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
  final String? midwifePhone;
  final String? midwifeUserId;

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
    this.midwifePhone,
    this.midwifeUserId,
  });

  DateTime? get scheduledDateTime {
    if (date.isEmpty) return null;
    try {
      final dateParts = date.split('-');
      if (dateParts.length < 3) return null;
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      int hour = 0;
      int minute = 0;
      String t = endTime.isNotEmpty ? endTime : startTime;
      if (t.isNotEmpty) {
        final timeParts = t.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool get isPast {
    final dt = scheduledDateTime;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  static String? _extractPhone(Map<String, dynamic>? map) {
    if (map == null) return null;
    String? phone = map['phone'] ?? map['phone_number'];
    return phone?.trim().isNotEmpty == true ? phone!.trim() : null;
  }

  static String? extractPersonFullName(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final s = data.trim();
      if (s.isEmpty || s == 'null' || s.toLowerCase() == 'recipient' || s.toLowerCase() == 'caller') {
        return null;
      }
      return NameFormatter.format(s);
    }
    if (data is! Map) return null;

    final map = Map<String, dynamic>.from(data);

    // 1. Check nested 'profile' map
    if (map['profile'] is Map) {
      final prof = Map<String, dynamic>.from(map['profile'] as Map);
      final fn = (prof['first_name'] ?? prof['firstName'] ?? '').toString().trim();
      final ln = (prof['last_name'] ?? prof['lastName'] ?? '').toString().trim();
      if (fn.isNotEmpty || ln.isNotEmpty) {
        return NameFormatter.format('$fn $ln'.trim());
      }
      final full = (prof['full_name'] ?? prof['name'])?.toString().trim();
      if (full != null && full.isNotEmpty && full != 'null' && full.toLowerCase() != 'recipient') {
        return NameFormatter.format(full);
      }
    }

    // 2. Check nested 'user' map (e.g. midwife_detail -> user)
    if (map['user'] is Map) {
      final res = extractPersonFullName(map['user']);
      if (res != null && res.isNotEmpty) return res;
    }

    // 3. Check direct first_name and last_name on map
    final fn = (map['first_name'] ?? map['firstName'] ?? '').toString().trim();
    final ln = (map['last_name'] ?? map['lastName'] ?? '').toString().trim();
    if (fn.isNotEmpty || ln.isNotEmpty) {
      return NameFormatter.format('$fn $ln'.trim());
    }

    // 4. Check direct full_name or name on map
    final full = (map['full_name'] ?? map['name'] ?? map['display_name'])?.toString().trim();
    if (full != null && full.isNotEmpty && full != 'null' && full.toLowerCase() != 'recipient') {
      return NameFormatter.format(full);
    }

    return null;
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    AppLogger.d('Appointment JSON: $json');

    // Extract Patient Name
    String? parsedPatientName = extractPersonFullName(json['user_full_name'] ?? json['patient_name'] ?? json['patient_full_name']);
    String? parsedPatientPhone = json['patient_phone'] ?? json['user_phone'];

    if (parsedPatientName == null) {
      for (final key in ['user_detail', 'patient_detail', 'patient', 'user', 'user_profile']) {
        if (json[key] != null) {
          parsedPatientName = extractPersonFullName(json[key]);
          if (parsedPatientName != null) break;
        }
      }
    }

    if (parsedPatientPhone == null || parsedPatientPhone.isEmpty) {
      if (json['user_detail'] is Map) parsedPatientPhone = _extractPhone(json['user_detail']);
      if (json['patient_detail'] is Map) parsedPatientPhone ??= _extractPhone(json['patient_detail']);
      if (json['patient'] is Map) parsedPatientPhone ??= _extractPhone(json['patient']);
    }

    // Extract Midwife Name
    String? parsedMidwifeName = extractPersonFullName(json['midwife_name'] ?? json['midwife_full_name']);
    String? parsedMidwifePhone = json['midwife_phone'];

    if (parsedMidwifeName == null) {
      for (final key in ['midwife_detail', 'midwife', 'midwife_profile']) {
        if (json[key] != null) {
          parsedMidwifeName = extractPersonFullName(json[key]);
          if (parsedMidwifeName != null) break;
        }
      }
    }

    if (parsedMidwifePhone == null || parsedMidwifePhone.isEmpty) {
      if (json['midwife_detail'] is Map) parsedMidwifePhone = _extractPhone(json['midwife_detail']);
      if (json['midwife'] is Map) parsedMidwifePhone ??= _extractPhone(json['midwife']);
    }

    if (parsedPatientName?.isEmpty == true) parsedPatientName = null;
    if (parsedPatientPhone?.isEmpty == true) parsedPatientPhone = null;
    if (parsedMidwifeName?.isEmpty == true) parsedMidwifeName = null;
    if (parsedMidwifePhone?.isEmpty == true) parsedMidwifePhone = null;

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

    String safeMidwifeUserId = '';
    if (json['midwife_detail'] is Map && json['midwife_detail']['user'] != null) {
      final u = json['midwife_detail']['user'];
      safeMidwifeUserId = u is Map ? (u['id']?.toString() ?? '') : u.toString();
    } else if (json['midwife'] is Map && json['midwife']['user'] != null) {
      final u = json['midwife']['user'];
      safeMidwifeUserId = u is Map ? (u['id']?.toString() ?? '') : u.toString();
    }

    if (parsedPatientName != null && parsedPatientName.isEmpty) parsedPatientName = null;
    if (parsedMidwifeName != null && parsedMidwifeName.isEmpty) parsedMidwifeName = null;
    if (parsedMidwifePhone != null && parsedMidwifePhone.isEmpty) parsedMidwifePhone = null;

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
      midwifePhone: parsedMidwifePhone,
      midwifeUserId: safeMidwifeUserId,
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
