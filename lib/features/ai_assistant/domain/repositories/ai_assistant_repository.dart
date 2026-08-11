import 'package:cagh_frontend/shared/models/ai_question.dart';

abstract class AiAssistantRepository {
  Future<AiQuestion> askQuestion(String question);
}
