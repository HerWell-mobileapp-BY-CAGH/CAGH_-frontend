import 'package:flutter/foundation.dart';

class AppointmentItem {
  final String id;
  final String midwifeName;
  final String midwifeRole;
  final String consultationType;
  final String date;
  final String time;
  final String status; // 'UPCOMING', 'PAST', 'CANCELLED'
  final String userFullName;
  final String userPhone;
  final String? note;

  AppointmentItem({
    required this.id,
    required this.midwifeName,
    required this.midwifeRole,
    required this.consultationType,
    required this.date,
    required this.time,
    required this.status,
    required this.userFullName,
    required this.userPhone,
    this.note,
  });
}

class AppointmentService {
  static final ValueNotifier<List<AppointmentItem>> appointments = ValueNotifier<List<AppointmentItem>>([]);

  static void loadDemoData() {
    appointments.value = [
      AppointmentItem(
        id: 'apt_maya_chen',
        midwifeName: 'Sr. Abeba Selassie',
        midwifeRole: 'Obstetrics & Maternal Care',
        consultationType: 'Video Consult',
        date: 'Today',
        time: '14:30 - 15:15',
        status: 'UPCOMING',
        userFullName: 'Maya Chen',
        userPhone: '+251 912 345 678',
        note: "I've been experiencing some mild cramping in the evenings and wanted to discuss if this is normal for 24 weeks. Also, I'm feeling a bit anxious about the upcoming glucose test next week.",
      ),
    ];
  }

  static void addBooking({
    required String midwifeName,
    required String consultationType,
    required String date,
    required String time,
    String? userFullName,
    String? userPhone,
    String? note,
  }) {
    final newApt = AppointmentItem(
      id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
      midwifeName: midwifeName,
      midwifeRole: 'Voice & Video Call',
      consultationType: consultationType,
      date: date,
      time: time,
      status: 'UPCOMING',
      userFullName: userFullName ?? 'Sarah Tesfaye',
      userPhone: userPhone ?? '+251 911 234 567',
      note: note,
    );

    appointments.value = [newApt, ...appointments.value];
  }

  static void rescheduleBooking(String id, String newDate, String newTime) {
    appointments.value = appointments.value.map((apt) {
      if (apt.id == id) {
        return AppointmentItem(
          id: apt.id,
          midwifeName: apt.midwifeName,
          midwifeRole: apt.midwifeRole,
          consultationType: apt.consultationType,
          date: newDate,
          time: newTime,
          status: 'UPCOMING',
          userFullName: apt.userFullName,
          userPhone: apt.userPhone,
          note: apt.note,
        );
      }
      return apt;
    }).toList();
  }

  static void updateStatus(String id, String newStatus) {
    appointments.value = appointments.value.map((apt) {
      if (apt.id == id) {
        return AppointmentItem(
          id: apt.id,
          midwifeName: apt.midwifeName,
          midwifeRole: apt.midwifeRole,
          consultationType: apt.consultationType,
          date: apt.date,
          time: apt.time,
          status: newStatus,
          userFullName: apt.userFullName,
          userPhone: apt.userPhone,
          note: apt.note,
        );
      }
      return apt;
    }).toList();
  }

  /// Cancel an appointment by ID — marks it CANCELLED and moves to past.
  static void cancelAppointment(String id) {
    appointments.value = appointments.value.map((apt) {
      if (apt.id == id) {
        return AppointmentItem(
          id: apt.id,
          midwifeName: apt.midwifeName,
          midwifeRole: apt.midwifeRole,
          consultationType: apt.consultationType,
          date: apt.date,
          time: apt.time,
          status: 'CANCELLED',
          userFullName: apt.userFullName,
          userPhone: apt.userPhone,
          note: apt.note,
        );
      }
      return apt;
    }).toList();
  }

  /// Remove a cancelled appointment entirely from the list.
  static void removeAppointment(String id) {
    appointments.value = appointments.value
        .where((apt) => apt.id != id)
        .toList();
  }
}
