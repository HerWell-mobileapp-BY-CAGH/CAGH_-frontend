enum SenderType { user, ai }
enum AiFeedback { none, thumbsUp, thumbsDown }

class AiMessage {
  final String id;
  final String text;
  final SenderType sender;
  final DateTime timestamp;
  final String? attachmentPath; // Path or name of the uploaded file
  final AiFeedback feedback;

  const AiMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.attachmentPath,
    this.feedback = AiFeedback.none,
  });

  AiMessage copyWith({
    String? id,
    String? text,
    SenderType? sender,
    DateTime? timestamp,
    String? attachmentPath,
    AiFeedback? feedback,
  }) {
    return AiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      feedback: feedback ?? this.feedback,
    );
  }
}
