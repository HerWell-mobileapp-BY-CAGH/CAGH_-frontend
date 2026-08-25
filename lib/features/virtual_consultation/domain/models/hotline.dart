class Hotline {
  final String name;
  final String number;
  final String callUrl;

  Hotline({
    required this.name,
    required this.number,
    required this.callUrl,
  });

  factory Hotline.fromJson(Map<String, dynamic> json) {
    return Hotline(
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      callUrl: json['call_url'] ?? '',
    );
  }
}

class SosResponse {
  final String defaultCallUrl;
  final String primaryHotlineNumber;
  final int savedContactsCount;
  final List<Hotline> hotlines;
  final int? notifiedContactsCount;

  SosResponse({
    required this.defaultCallUrl,
    required this.primaryHotlineNumber,
    required this.savedContactsCount,
    required this.hotlines,
    this.notifiedContactsCount,
  });

  factory SosResponse.fromJson(Map<String, dynamic> json) {
    var hotlinesList = json['hotlines'] as List? ?? [];
    List<Hotline> hotlines = hotlinesList.map((i) => Hotline.fromJson(i)).toList();

    return SosResponse(
      defaultCallUrl: json['default_call_url'] ?? '',
      primaryHotlineNumber: json['primary_hotline_number'] ?? '',
      savedContactsCount: json['saved_contacts_count'] ?? 0,
      hotlines: hotlines,
      notifiedContactsCount: json['notified_contacts_count'],
    );
  }
}
