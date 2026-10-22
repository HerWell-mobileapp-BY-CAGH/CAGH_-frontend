import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';

void main() {
  group('SIM Direct Calling Logic & Model Tests', () {
    test('Appointment model correctly parses callEligibility map', () {
      final json = {
        'id': 'apt-sim-100',
        'appointment_id': 'apt-sim-100',
        'user': 'user-42',
        'user_name': 'Abebe Bikila',
        'midwife': 'midwife-99',
        'midwife_name': 'Sister Sara',
        'midwife_phone': '+251911223344',
        'date': '2026-10-22',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'status': 'CONFIRMED',
        'appointment_type': 'VIRTUAL_VOICE',
        'call_eligibility': {
          'can_call': true,
          'is_call_window_active': true,
          'window_state': 'ACTIVE',
          'phone_number': '+251911223344',
          'phone_number_local': '0911223344',
          'carrier': 'Ethio Telecom',
          'start_time_12h': '10:00 AM',
          'end_time_12h': '11:00 AM',
          'timezone': 'Africa/Addis_Ababa',
          'message': 'Consultation call window is currently open (EAT).',
        },
      };

      final apt = Appointment.fromJson(json);

      expect(apt.appointmentId, 'apt-sim-100');
      expect(apt.userFullName, 'Abebe Bikila');
      expect(apt.midwifeName, 'Sister Sara');
      expect(apt.callEligibility, isNotNull);
      expect(apt.callEligibility!['can_call'], isTrue);
      expect(apt.callEligibility!['carrier'], 'Ethio Telecom');
      expect(apt.callEligibility!['window_state'], 'ACTIVE');
      expect(apt.callEligibility!['phone_number_local'], '0911223344');
    });

    test('Carrier detection distinguishes Ethio Telecom and Safaricom Ethiopia', () {
      String detectCarrier(String? phone, String? backendCarrier) {
        if (backendCarrier != null && backendCarrier.isNotEmpty) {
          return backendCarrier;
        }
        if (phone == null || phone.isEmpty) return 'Mobile Network';
        final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
        final local = clean.startsWith('251')
            ? '0${clean.substring(3)}'
            : (clean.startsWith('0') ? clean : '0$clean');

        if (local.startsWith('09')) return 'Ethio Telecom';
        if (local.startsWith('07')) return 'Safaricom Ethiopia';
        return 'Mobile Network';
      }

      expect(detectCarrier('0911223344', null), 'Ethio Telecom');
      expect(detectCarrier('+251912345678', null), 'Ethio Telecom');
      expect(detectCarrier('0712345678', null), 'Safaricom Ethiopia');
      expect(detectCarrier('+251712345678', null), 'Safaricom Ethiopia');
      expect(detectCarrier('+251912345678', 'Custom Carrier'), 'Custom Carrier');
      expect(detectCarrier('123456', null), 'Mobile Network');
    });

    test('Local phone number display formatting works correctly', () {
      String formatPhoneNumber(String? raw) {
        if (raw == null || raw.trim().isEmpty) return '';
        final clean = raw.replaceAll(RegExp(r'[^\d]'), '');
        final local = clean.startsWith('251')
            ? '0${clean.substring(3)}'
            : (clean.startsWith('0') ? clean : '0$clean');

        if (local.length == 10) {
          return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
        }
        return raw;
      }

      expect(formatPhoneNumber('0911223344'), '091 122 3344');
      expect(formatPhoneNumber('+251911223344'), '091 122 3344');
      expect(formatPhoneNumber('0712345678'), '071 234 5678');
    });
  });
}
