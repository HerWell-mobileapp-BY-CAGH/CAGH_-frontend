class BlockedDate {
  final String id;
  final String date;
  final String reason;

  BlockedDate({
    required this.id,
    required this.date,
    required this.reason,
  });

  factory BlockedDate.fromJson(Map<String, dynamic> json) {
    return BlockedDate(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'reason': reason,
    };
  }
}
