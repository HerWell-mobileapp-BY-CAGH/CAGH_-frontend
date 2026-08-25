import 'package:cagh_frontend/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:cagh_frontend/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:cagh_frontend/features/ai_assistant/data/services/ai_api_service.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final AiApiService _apiService;

  AiAssistantRepositoryImpl(this._apiService);

  @override
  Future<AiMessage> askQuestion(String message, {String? attachmentPath}) async {
    try {
      final responseMap = await _apiService.askQuestion(message, attachmentPath: attachmentPath);
      
      // Parse the real backend response map here.
      return AiMessage(
        id: responseMap['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: responseMap['response'] ?? '',
        sender: SenderType.ai,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Re-throw to be handled by the provider UI
      rethrow;
    }
  }

  @override
  Future<List<String>> getSuggestedQuestions() async {
    return await _apiService.getSuggestedQuestions();
  }

  @override
  Future<void> submitFeedback(String id, String feedback) async {
    return await _apiService.submitFeedback(id, feedback);
  }
}
