import 'package:cagh_frontend/features/ai_assistant/domain/entities/ai_message.dart';

abstract class AiAssistantRepository {
  /// Sends a message to the AI backend and returns the AI's response.
  Future<AiMessage> askQuestion(String message, {String? attachmentPath});
  
  /// Fetches suggested questions from the backend.
  Future<List<String>> getSuggestedQuestions();
  
  /// Submits feedback for a specific AI message.
  Future<void> submitFeedback(String id, String feedback);
}
