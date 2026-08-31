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
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      readAt: json['read_at'] != null 
          ? DateTime.tryParse(json['read_at'].toString()) 
          : null,
      relatedId: json['related_id']?.toString(),
      relatedType: json['related_type']?.toString(),
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
      if (relatedId != null) 'related_id': relatedId,
      if (relatedType != null) 'related_type': relatedType,
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
