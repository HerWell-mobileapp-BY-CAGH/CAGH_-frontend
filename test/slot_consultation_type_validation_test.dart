import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/shared/models/time_slot.dart';

void main() {
  group('TimeSlot Consultation Type Parsing & Visual Tags', () {
    test('Requirement 1 & 5: Parse in_person, voice, and both from backend consultation_methods', () {
      final inPersonSlot = TimeSlot.fromJson({
        'id': 'avail-1',
        'date': '2026-09-22',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'is_available': true,
        'consultation_methods': ['IN_PERSON'],
      });

      final voiceSlot = TimeSlot.fromJson({
        'id': 'avail-2',
        'date': '2026-09-22',
        'start_time': '11:00:00',
        'end_time': '12:00:00',
        'is_available': true,
        'consultation_methods': ['VIRTUAL_VOICE'],
      });

      final bothSlot = TimeSlot.fromJson({
        'id': 'avail-3',
        'date': '2026-09-22',
        'start_time': '14:00:00',
        'end_time': '15:00:00',
        'is_available': true,
        'consultation_methods': ['IN_PERSON', 'VIRTUAL_VOICE'],
      });

      expect(inPersonSlot.consultationTypeCategory, equals('in_person'));
      expect(inPersonSlot.consultationTypeTagText, equals('In-Person'));

      expect(voiceSlot.consultationTypeCategory, equals('voice'));
      expect(voiceSlot.consultationTypeTagText, equals('Voice'));

      expect(bothSlot.consultationTypeCategory, equals('both'));
      expect(bothSlot.consultationTypeTagText, equals('Voice / In-Person'));
    });
  });

  group('Pre-Booking Compatibility Validation Rules', () {
    String? validateCompatibility(TimeSlot slot, String selectedTypeTitle) {
      final isVoiceSelected = selectedTypeTitle.toLowerCase().contains('voice');
      final isPersonSelected = !isVoiceSelected;
      final category = slot.consultationTypeCategory;

      if (category == 'both') return null; // Always allowed

      if (isPersonSelected && category == 'voice') {
        return 'This time is available for voice consultation only. Please select Voice or choose another time.';
      }

      if (isVoiceSelected && category == 'in_person') {
        return 'This time is available for in-person consultation only. Please select In-Person or choose another time.';
      }

      return null;
    }

    test('Requirement 3 & 4: In-Person user selection + voice slot is blocked with friendly message', () {
      final voiceSlot = TimeSlot.fromJson({
        'id': 'avail-voice-only',
        'date': '2026-09-22',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'is_available': true,
        'consultation_methods': ['VOICE_CALL'],
      });

      final err = validateCompatibility(voiceSlot, 'In-Person');
      expect(err, equals('This time is available for voice consultation only. Please select Voice or choose another time.'));
    });

    test('Requirement 3 & 4: Voice user selection + in_person slot is blocked with friendly message', () {
      final inPersonSlot = TimeSlot.fromJson({
        'id': 'avail-person-only',
        'date': '2026-09-22',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'is_available': true,
        'consultation_methods': ['IN_PERSON'],
      });

      final err = validateCompatibility(inPersonSlot, 'Voice Call');
      expect(err, equals('This time is available for in-person consultation only. Please select In-Person or choose another time.'));
    });

    test('Requirement 3 & 6: Compatible selections (matching or both) return null and preserve availability_id', () {
      final bothSlot = TimeSlot.fromJson({
        'id': 'avail-both',
        'date': '2026-09-22',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'is_available': true,
        'consultation_methods': ['IN_PERSON', 'VIRTUAL_VOICE'],
      });

      expect(validateCompatibility(bothSlot, 'Voice Call'), isNull);
      expect(validateCompatibility(bothSlot, 'In-Person'), isNull);
      expect(bothSlot.id, equals('avail-both'));
    });
  });
}
