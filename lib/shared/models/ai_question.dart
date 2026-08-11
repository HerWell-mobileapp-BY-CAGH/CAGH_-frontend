class AiQuestion {
  final String id;
  final String question;
  final String response;
  final DateTime? createdAt;

  AiQuestion({
    required this.id,
    required this.question,
    required this.response,
    this.createdAt,
  });

  factory AiQuestion.fromJson(Map<String, dynamic> json) {
    return AiQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      response: json['response'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
