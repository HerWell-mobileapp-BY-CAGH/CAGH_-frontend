import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';

void main() {
  group("Midwife Home Dashboard Today's Appointment Date Filtering Tests", () {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final pastStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 4)));
    final futureStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 2)));

    bool isToday(String dateStr) {
      if (dateStr.trim().isEmpty) return false;
      try {
        final cleanDateStr = dateStr.trim();
        if (cleanDateStr.startsWith(todayStr)) return true;

        final parsed = DateTime.parse(cleanDateStr).toLocal();
        return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
      } catch (_) {
        return false;
      }
    }

    final todayApt = Appointment(
      appointmentId: 'apt-today',
      userId: 'user-1',
      midwifeId: 'midwife-1',
      date: todayStr,
      startTime: '14:00',
      endTime: '15:00',
      appointmentType: 'VIRTUAL_VOICE',
      status: AppointmentStatus.confirmed,
    );

    final pastApt = Appointment(
      appointmentId: 'apt-past',
      userId: 'user-2',
      midwifeId: 'midwife-1',
      date: pastStr,
      startTime: '10:00',
      endTime: '11:00',
      appointmentType: 'VIRTUAL_VOICE',
      status: AppointmentStatus.confirmed,
    );

    final futureApt = Appointment(
      appointmentId: 'apt-future',
      userId: 'user-3',
      midwifeId: 'midwife-1',
      date: futureStr,
      startTime: '16:00',
      endTime: '17:00',
      appointmentType: 'VIRTUAL_VOICE',
      status: AppointmentStatus.confirmed,
    );

    final pendingTodayApt = Appointment(
      appointmentId: 'apt-pending',
      userId: 'user-4',
      midwifeId: 'midwife-1',
      date: todayStr,
      startTime: '18:00',
      endTime: '19:00',
      appointmentType: 'VIRTUAL_VOICE',
      status: AppointmentStatus.pending,
    );

    test('Filters only confirmed appointments scheduled for current local date', () {
      final allAppointments = [todayApt, pastApt, futureApt, pendingTodayApt];

      final filtered = allAppointments.where((a) {
        final isConfirmed = a.status == AppointmentStatus.confirmed;
        return isConfirmed && isToday(a.date);
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.appointmentId, equals('apt-today'));
      expect(filtered.first.date, equals(todayStr));
    });
  });
}
