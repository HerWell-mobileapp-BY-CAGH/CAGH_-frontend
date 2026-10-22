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

    test('isPast correctly identifies past vs future and today dates', () {
      final pastSlot = AvailabilitySlot.fromJson({
        'id': 'past-1',
        'date': '2020-01-01',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
      });
      expect(pastSlot.isPast, isTrue);

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todaySlot = AvailabilitySlot.fromJson({
        'id': 'today-1',
        'date': todayStr,
        'start_time': '10:00:00',
        'end_time': '11:00:00',
      });
      expect(todaySlot.isPast, isFalse);

      final futureDate = now.add(const Duration(days: 30));
      final futureStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final futureSlot = AvailabilitySlot.fromJson({
        'id': 'future-1',
        'date': futureStr,
        'start_time': '10:00:00',
        'end_time': '11:00:00',
      });
      expect(futureSlot.isPast, isFalse);
    });

    test('formattedDayDisplay formats date in Ethiopian calendar with Amharic & English', () {
      final slot = AvailabilitySlot.fromJson({
        'id': 'eth-slot-1',
        'date': '2026-09-12', // Meskerem 2, 2019 E.C. (Saturday)
        'start_time': '10:00:00',
        'end_time': '11:00:00',
      });

      final enDisplay = slot.formattedDayDisplay(locale: 'en', includeWeekday: true);
      expect(enDisplay, contains('2019'));
      expect(enDisplay, contains('Meskerem'));
      expect(enDisplay, contains('Saturday'));

      final amDisplay = slot.formattedDayDisplay(locale: 'am', includeWeekday: true);
      expect(amDisplay, contains('2019'));
      expect(amDisplay, contains('መስከረም'));
      expect(amDisplay, contains('ቅዳሜ'));
    });

    test('matchesDate accurately matches target dates', () {
      final slot = AvailabilitySlot.fromJson({
        'id': 'match-1',
        'date': '2026-10-24',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
      });

      expect(slot.matchesDate(DateTime(2026, 10, 24)), isTrue);
      expect(slot.matchesDate(DateTime(2026, 10, 24, 15, 30)), isTrue);
      expect(slot.matchesDate(DateTime(2026, 10, 25)), isFalse);
    });
  });
}
