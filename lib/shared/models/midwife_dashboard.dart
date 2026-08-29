import 'package:cagh_frontend/shared/models/appointment.dart';

class MidwifeDashboard {
  final String verificationStatus;
  final List<dynamic> todaySchedule;
  final List<Appointment> upcomingAppointments;
  final List<Appointment> pendingRequests;
  final Map<String, int> counts;

  MidwifeDashboard({
    required this.verificationStatus,
    required this.todaySchedule,
    required this.upcomingAppointments,
    required this.pendingRequests,
    required this.counts,
  });

  factory MidwifeDashboard.fromJson(Map<String, dynamic> json) {
    return MidwifeDashboard(
      verificationStatus: json['verification_status'] ?? '',
      todaySchedule: json['today_schedule'] ?? [],
      upcomingAppointments: (json['upcoming_appointments'] as List<dynamic>?)
          ?.map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      pendingRequests: (json['pending_requests'] as List<dynamic>?)
          ?.map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      counts: json['counts'] != null 
          ? Map<String, int>.from(json['counts']) 
          : {},
    );
  }
}
