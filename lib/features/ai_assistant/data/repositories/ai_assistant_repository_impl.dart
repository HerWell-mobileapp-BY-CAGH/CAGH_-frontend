import 'package:cagh_frontend/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:cagh_frontend/features/ai_assistant/data/services/ai_assistant_api_service.dart';
import 'package:cagh_frontend/shared/models/ai_question.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final AiAssistantApiService _apiService;

  AiAssistantRepositoryImpl(this._apiService);

  @override
  Future<AiQuestion> askQuestion(String question) async {
    final response = await _apiService.askQuestion(question);
    return AiQuestion.fromJson(response);
  }
}
