import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';

class TimeSlot {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String displayTime;
  final bool isAvailable;
  final List<String> consultationMethods;

  TimeSlot({
    this.id = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.displayTime = '',
    required this.isAvailable,
    this.consultationMethods = const [],
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    List<String> methods = [];
    if (json['consultation_methods'] is List) {
      methods = List<String>.from(json['consultation_methods']);
    } else if (json['offered_consultation_types'] is List) {
      methods = List<String>.from(json['offered_consultation_types']);
    }

    final rawType = (json['consultation_type'] ?? json['appointment_type'] ?? '').toString();
    if (rawType.isNotEmpty && !methods.contains(rawType)) {
      methods.add(rawType);
    }

    return TimeSlot(
      id: (json['id'] ?? json['availability_id'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      displayTime: (json['start_time_12h'] ?? json['start_time'] ?? '').toString(),
      isAvailable: json['is_available'] ?? false,
      consultationMethods: methods,
    );
  }

  /// Returns Ethiopian traditional time string (e.g. `2:00 morning` or `2:00 ጠዋት`).
  String ethiopianDisplayTime([String? locale]) {
    return EthiopianDateHelper.formatEthiopianTime(startTime, locale: locale ?? 'en');
  }

  /// Returns Ethiopian traditional time range (e.g. `2:00 – 3:00 morning`).
  String ethiopianDisplayTimeRange([String? locale]) {
    return EthiopianDateHelper.formatEthiopianTimeRange(startTime, endTime, locale: locale ?? 'en');
  }


  bool get supportsInPerson {
    if (consultationMethods.isEmpty) return true;
    return consultationMethods.any((m) {
      final u = m.toUpperCase();
      return u == 'IN_PERSON' || u == 'IN-PERSON' || u == 'BOTH';
    });
  }

  bool get supportsVoice {
    if (consultationMethods.isEmpty) return true;
    return consultationMethods.any((m) {
      final u = m.toUpperCase();
      return u == 'VIRTUAL_VOICE' || u == 'VOICE_CALL' || u == 'VOICE' || u == 'BOTH';
    });
  }

  /// Returns 'in_person', 'voice', or 'both'
  String get consultationTypeCategory {
    final inPerson = supportsInPerson;
    final voice = supportsVoice;
    if (inPerson && voice) return 'both';
    if (inPerson) return 'in_person';
    if (voice) return 'voice';
    return 'both';
  }

  /// Display text for slot tag: 'In-Person', 'Voice', or 'Voice / In-Person'
  String get consultationTypeTagText {
    final cat = consultationTypeCategory;
    if (cat == 'in_person') return 'In-Person';
    if (cat == 'voice') return 'Voice';
    return 'Voice / In-Person';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'availability_id': id,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
      'consultation_methods': consultationMethods,
    };
  }
}
