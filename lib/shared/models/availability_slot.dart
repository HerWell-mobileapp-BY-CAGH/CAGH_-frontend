class AvailabilitySlot {
  final String availabilityId;
  final String midwifeId;
  final String dateOrDay; // e.g. "0" for Monday, or "2026-08-28"
  final String? dayName;
  final String startTime;
  final String endTime;
  final int? durationMinutes;
  final String status; // e.g. "AVAILABLE", "BOOKED"
  final bool isActive;
  final bool isInPerson;
  final bool isVoiceCall;

  AvailabilitySlot({
    required this.availabilityId,
    required this.midwifeId,
    required this.dateOrDay,
    this.dayName,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    required this.status,
    this.isActive = true,
    this.isInPerson = true,
    this.isVoiceCall = false,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final dayOfWeekVal = json['day_of_week']?.toString();
    var dateVal = json['date']?.toString();
    if (dateVal != null && dateVal.length > 10) {
      dateVal = dateVal.substring(0, 10);
    }
    // Prioritize specific date over day of week
    final dateOrDayVal = json['date_or_day']?.toString() ?? dateVal ?? dayOfWeekVal ?? json['day']?.toString() ?? '';

    final isActiveBool = json['is_active'] ?? true;
    final statusStr = json['status'] ?? (isActiveBool ? 'AVAILABLE' : 'UNAVAILABLE');

    bool parseBool(dynamic val, bool def) {
      if (val == null) return def;
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true' || val == '1';
      if (val is int) return val == 1;
      return def;
    }

    final inPersonRaw = json['is_in_person'] ?? json['in_person'] ?? json['isInPerson'] ?? json['inPerson'];
    final voiceCallRaw = json['is_voice_call'] ?? json['voice_call'] ?? json['isVoiceCall'] ?? json['voiceCall'];
    final consultType = (json['consultation_type'] ?? json['appointment_type'] ?? json['type'] ?? '').toString().toUpperCase();
    final rawTypes = json['offered_consultation_types'] ?? json['consultation_types'] ?? json['types'];

    bool? inPerson;
    bool? voiceCall;

    if (inPersonRaw != null) {
      inPerson = parseBool(inPersonRaw, false);
    }
    if (voiceCallRaw != null) {
      voiceCall = parseBool(voiceCallRaw, false);
    }

    if (rawTypes is List && rawTypes.isNotEmpty) {
      for (final t in rawTypes) {
        final str = t.toString().toLowerCase();
        if (str.contains('voice') || str.contains('call') || str.contains('virtual') || str.contains('phone')) {
          voiceCall = true;
        }
        if (str.contains('person') || str.contains('hospital') || str.contains('clinic')) {
          inPerson = true;
        }
      }
    }

    if (consultType.isNotEmpty) {
      if (consultType.contains('VOICE') || consultType.contains('VIRTUAL') || consultType.contains('PHONE')) {
        voiceCall = true;
      }
      if (consultType.contains('PERSON') || consultType.contains('HOSPITAL') || consultType.contains('CLINIC')) {
        inPerson = true;
      }
      if (consultType == 'BOTH' || consultType.contains('ALL')) {
        inPerson = true;
        voiceCall = true;
      }
    }

    final finalInPerson = inPerson ?? (voiceCall == true ? false : true);
    final finalVoiceCall = voiceCall ?? (inPerson == true ? false : false);

    return AvailabilitySlot(
      availabilityId: json['availability_id']?.toString() ?? json['id']?.toString() ?? '',
      midwifeId: json['midwife_id']?.toString() ?? json['midwife']?.toString() ?? '',
      dateOrDay: dateOrDayVal,
      dayName: json['day_name']?.toString(),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      status: statusStr,
      isActive: isActiveBool,
      isInPerson: finalInPerson,
      isVoiceCall: finalVoiceCall,
    );
  }

  String get formattedTimeRange {
    String formatTime(String t) {
      if (t.isEmpty) return '';
      final parts = t.split(':');
      if (parts.length < 2) return t;
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;
      return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
    }

    return '${formatTime(startTime)}–${formatTime(endTime)}';
  }

  String get dayDisplayName {
    if (dayName != null && dayName!.isNotEmpty) return dayName!;
    final dayInt = int.tryParse(dateOrDay);
    if (dayInt != null && dayInt >= 0 && dayInt < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[dayInt];
    }
    return dateOrDay.isNotEmpty ? dateOrDay : 'Scheduled Day';
  }

  Map<String, dynamic> toJson() {
    return {
      'availability_id': availabilityId,
      'midwife_id': midwifeId,
      'date_or_day': dateOrDay,
      if (dayName != null) 'day_name': dayName,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'status': status,
      'is_active': isActive,
      'is_in_person': isInPerson,
      'is_voice_call': isVoiceCall,
    };
  }
}
