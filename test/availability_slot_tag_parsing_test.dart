import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';

void main() {
  group('AvailabilitySlot Consultation Type Tag Tests', () {
    test('Parse Voice Call only slot correctly', () {
      final slot = AvailabilitySlot.fromJson({
        'id': 'slot-voice-1',
        'date': '2026-09-23',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'consultation_methods': ['VIRTUAL_VOICE'],
        'consultation_type': 'VIRTUAL_VOICE',
        'is_in_person': false,
        'is_voice_call': true,
      });

      expect(slot.isVoiceCall, isTrue);
      expect(slot.isInPerson, isFalse);
      expect(slot.consultationTypeTagText, equals('Voice Call'));
    });

    test('Parse In-Person only slot correctly', () {
      final slot = AvailabilitySlot.fromJson({
        'id': 'slot-person-1',
        'date': '2026-09-23',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'consultation_methods': ['IN_PERSON'],
        'consultation_type': 'IN_PERSON',
        'is_in_person': true,
        'is_voice_call': false,
      });

      expect(slot.isInPerson, isTrue);
      expect(slot.isVoiceCall, isFalse);
      expect(slot.consultationTypeTagText, equals('In-Person'));
    });

    test('Parse Voice / In-Person (Both) slot correctly', () {
      final slot = AvailabilitySlot.fromJson({
        'id': 'slot-both-1',
        'date': '2026-09-23',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'consultation_methods': ['VIRTUAL_VOICE', 'IN_PERSON'],
        'consultation_type': 'BOTH',
        'is_in_person': true,
        'is_voice_call': true,
      });

      expect(slot.isInPerson, isTrue);
      expect(slot.isVoiceCall, isTrue);
      expect(slot.consultationTypeTagText, equals('Voice / In-Person'));
    });

    test('Parse slot with only consultation_methods array from DRF backend', () {
      final slotVoice = AvailabilitySlot.fromJson({
        'id': 'drf-voice',
        'date': '2026-09-23',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'consultation_methods': ['VIRTUAL_VOICE'],
      });

      expect(slotVoice.isVoiceCall, isTrue);
      expect(slotVoice.isInPerson, isFalse);
      expect(slotVoice.consultationTypeTagText, equals('Voice Call'));

      final slotPerson = AvailabilitySlot.fromJson({
        'id': 'drf-person',
        'date': '2026-09-23',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'consultation_methods': ['IN_PERSON'],
      });

      expect(slotPerson.isInPerson, isTrue);
      expect(slotPerson.isVoiceCall, isFalse);
      expect(slotPerson.consultationTypeTagText, equals('In-Person'));

      final slotBoth = AvailabilitySlot.fromJson({
        'id': 'drf-both',
        'date': '2026-09-23',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'consultation_methods': ['VIRTUAL_VOICE', 'IN_PERSON'],
      });

      expect(slotBoth.isInPerson, isTrue);
      expect(slotBoth.isVoiceCall, isTrue);
      expect(slotBoth.consultationTypeTagText, equals('Voice / In-Person'));
    });
  });
}
