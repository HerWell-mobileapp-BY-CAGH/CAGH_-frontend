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

    bool? inPerson;
    bool? voiceCall;

    if (inPersonRaw != null) {
      inPerson = parseBool(inPersonRaw, false);
    }
    if (voiceCallRaw != null) {
      voiceCall = parseBool(voiceCallRaw, false);
    }

    final listCandidates = [
      json['consultation_methods'],
      json['offered_consultation_types'],
      json['consultation_types'],
      json['types'],
    ];

    bool foundInList = false;
    for (final candidate in listCandidates) {
      if (candidate is List && candidate.isNotEmpty) {
        foundInList = true;
        bool listHasVoice = false;
        bool listHasPerson = false;
        for (final t in candidate) {
          final str = t.toString().toUpperCase();
          if (str == 'BOTH' || str.contains('VOICE_AND_IN_PERSON')) {
            listHasVoice = true;
            listHasPerson = true;
          }
          if (str.contains('VOICE') || str.contains('CALL') || str.contains('VIRTUAL') || str.contains('PHONE')) {
            listHasVoice = true;
          }
          if (str.contains('PERSON') || str.contains('HOSPITAL') || str.contains('CLINIC')) {
            listHasPerson = true;
          }
        }
        if (listHasVoice && listHasPerson) {
          if (inPersonRaw == null) inPerson = true;
          if (voiceCallRaw == null) voiceCall = true;
        } else if (listHasVoice) {
          if (voiceCallRaw == null) voiceCall = true;
          if (inPersonRaw == null) inPerson = false;
        } else if (listHasPerson) {
          if (inPersonRaw == null) inPerson = true;
          if (voiceCallRaw == null) voiceCall = false;
        }
      }
    }

    final consultType = (json['consultation_type'] ?? json['appointment_type'] ?? json['type'] ?? '').toString().toUpperCase();
    if (consultType.isNotEmpty) {
      if (consultType == 'BOTH' || consultType.contains('ALL') || consultType.contains('VOICE_AND_IN_PERSON')) {
        if (inPersonRaw == null && !foundInList) inPerson = true;
        if (voiceCallRaw == null && !foundInList) voiceCall = true;
      } else if (consultType == 'VOICE_CALL' || consultType == 'VOICE' || consultType == 'VIRTUAL_VOICE' || consultType == 'VIRTUAL') {
        if (voiceCallRaw == null && !foundInList) voiceCall = true;
        if (inPersonRaw == null && !foundInList) inPerson = false;
      } else if (consultType == 'IN_PERSON' || consultType == 'PERSON') {
        if (inPersonRaw == null && !foundInList) inPerson = true;
        if (voiceCallRaw == null && !foundInList) voiceCall = false;
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

  String get consultationTypeTagText {
    if (isInPerson && isVoiceCall) {
      return 'Voice / In-Person';
    } else if (isVoiceCall) {
      return 'Voice Call';
    } else {
      return 'In-Person';
    }
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
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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
