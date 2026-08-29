import 'package:cagh_frontend/shared/models/time_slot.dart';

class TimeSlotsResponse {
  final String midwifeId;
  final String midwifeName;
  final String date;
  final List<String> offeredConsultationTypes;
  final int availableSlotsCount;
  final List<TimeSlot> morningSlots;
  final List<TimeSlot> afternoonSlots;
  final List<TimeSlot> eveningSlots;
  final String rawJsonDump;

  TimeSlotsResponse({
    required this.midwifeId,
    required this.midwifeName,
    required this.date,
    required this.offeredConsultationTypes,
    required this.availableSlotsCount,
    required this.morningSlots,
    required this.afternoonSlots,
    required this.eveningSlots,
    this.rawJsonDump = '',
  });

  factory TimeSlotsResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, TimeSlot> slotMap = {};

    void addSlots(List<dynamic>? rawList) {
      if (rawList == null) return;
      for (var e in rawList) {
        if (e is Map<String, dynamic>) {
          final slot = TimeSlot.fromJson(e);
          final key = slot.startTime;
          if (!slotMap.containsKey(key) || (!slotMap[key]!.isAvailable && slot.isAvailable)) {
            slotMap[key] = slot;
          }
        }
      }
    }

    addSlots(json['morning_slots'] as List<dynamic>?);
    addSlots(json['afternoon_slots'] as List<dynamic>?);
    addSlots(json['evening_slots'] as List<dynamic>?);
    addSlots(json['slots'] as List<dynamic>?);

    final List<TimeSlot> morning = [];
    final List<TimeSlot> afternoon = [];
    final List<TimeSlot> evening = [];

    final sortedKeys = slotMap.keys.toList()..sort();
    for (var key in sortedKeys) {
      final slot = slotMap[key]!;
      final hour = int.tryParse(slot.startTime.split(':').first) ?? 0;
      if (hour < 12) {
        morning.add(slot);
      } else if (hour < 17) {
        afternoon.add(slot);
      } else {
        evening.add(slot);
      }
    }

    final totalAvailable = slotMap.values.where((s) => s.isAvailable).length;

    return TimeSlotsResponse(
      midwifeId: json['midwife_id'] ?? '',
      midwifeName: json['midwife_name'] ?? '',
      date: json['date'] ?? '',
      offeredConsultationTypes: json['offered_consultation_types'] != null 
          ? List<String>.from(json['offered_consultation_types']) 
          : [],
      availableSlotsCount: json['available_slots_count'] ?? totalAvailable,
      morningSlots: morning,
      afternoonSlots: afternoon,
      eveningSlots: evening,
      rawJsonDump: json.keys.join(', '),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'midwife_id': midwifeId,
      'midwife_name': midwifeName,
      'date': date,
      'offered_consultation_types': offeredConsultationTypes,
      'available_slots_count': availableSlotsCount,
      'morning_slots': morningSlots.map((e) => e.toJson()).toList(),
      'afternoon_slots': afternoonSlots.map((e) => e.toJson()).toList(),
    };
  }
}
