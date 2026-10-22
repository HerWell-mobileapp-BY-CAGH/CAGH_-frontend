class NotificationModel {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedId;
  final String? relatedType;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.relatedId,
    this.relatedType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawRead = json['is_read'] ?? json['read'] ?? json['status'];
    final bool isRead = rawRead == true ||
        rawRead == 1 ||
        rawRead?.toString().toLowerCase() == 'true' ||
        rawRead?.toString().toUpperCase() == 'READ';

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? json['user']?.toString() ?? '',
      type: json['type']?.toString() ?? json['notification_type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? json['content']?.toString() ?? '',
      isRead: isRead,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now() 
          : (json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString())?.toLocal() ?? DateTime.now()
              : DateTime.now()),
      readAt: json['read_at'] != null 
          ? DateTime.tryParse(json['read_at'].toString())?.toLocal() 
          : null,
      relatedId: json['reference_id']?.toString() ?? json['related_id']?.toString(),
      relatedType: json['action']?.toString() ?? json['related_type']?.toString() ?? json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      if (relatedId != null) 'reference_id': relatedId,
      if (relatedType != null) 'action': relatedType,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? relatedId,
    String? relatedType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
    );
  }
}
