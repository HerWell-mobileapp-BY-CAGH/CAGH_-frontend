import 'package:cagh_frontend/shared/models/time_slot.dart';

class TimeSlotsResponse {
  final String midwifeId;
  final String midwifeName;
  final String date;
  final List<String> offeredConsultationTypes;
  final int availableSlotsCount;
  final List<TimeSlot> morningSlots;
  final List<TimeSlot> afternoonSlots;

  TimeSlotsResponse({
    required this.midwifeId,
    required this.midwifeName,
    required this.date,
    required this.offeredConsultationTypes,
    required this.availableSlotsCount,
    required this.morningSlots,
    required this.afternoonSlots,
  });

  factory TimeSlotsResponse.fromJson(Map<String, dynamic> json) {
    return TimeSlotsResponse(
      midwifeId: json['midwife_id'] ?? '',
      midwifeName: json['midwife_name'] ?? '',
      date: json['date'] ?? '',
      offeredConsultationTypes: json['offered_consultation_types'] != null 
          ? List<String>.from(json['offered_consultation_types']) 
          : [],
      availableSlotsCount: json['available_slots_count'] ?? 0,
      morningSlots: (json['morning_slots'] as List<dynamic>?)
          ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      afternoonSlots: (json['afternoon_slots'] as List<dynamic>?)
          ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
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
