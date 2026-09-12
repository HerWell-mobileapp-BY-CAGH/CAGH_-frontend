import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:cagh_frontend/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:cagh_frontend/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:cagh_frontend/features/ai_assistant/data/services/ai_api_service.dart';

// Dependency Injection
final aiApiServiceProvider = Provider<AiApiService>((ref) => AiApiService());

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  final apiService = ref.read(aiApiServiceProvider);
  return AiAssistantRepositoryImpl(apiService);
});

// State
class AiChatState {
  final List<AiMessage> messages;
  final List<String> suggestedQuestions;
  final bool isLoading;
  final String? error;

  AiChatState({
    this.messages = const [],
    this.suggestedQuestions = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    List<String>? suggestedQuestions,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiAssistantRepository _repository;

  AiChatNotifier(this._repository)
      : super(
          AiChatState(
            messages: [
              AiMessage(
                id: 'welcome_greeting',
                text: 'Hello! I am your AI Health Assistant. How can I help you today?',
                sender: SenderType.ai,
                timestamp: DateTime.now(),
              ),
            ],
          ),
        ) {
    fetchSuggestedQuestions();
  }

  Future<void> fetchSuggestedQuestions() async {
    try {
      final suggestions = await _repository.getSuggestedQuestions();
      state = state.copyWith(suggestedQuestions: suggestions);
    } catch (e) {
      print('Failed to load suggestions: $e');
    }
  }

  Future<void> submitFeedback(String messageId, AiFeedback feedback) async {
    try {
      // Optimistically update UI
      state = state.copyWith(
        messages: state.messages.map((msg) {
          if (msg.id == messageId) {
            return msg.copyWith(feedback: feedback);
          }
          return msg;
        }).toList(),
      );

      final feedbackString = feedback == AiFeedback.thumbsUp ? "THUMBS_UP" : "THUMBS_DOWN";
      await _repository.submitFeedback(messageId, feedbackString);
    } catch (e) {
      print('Failed to submit feedback: $e');
      // Revert if needed (simplified for now)
    }
  }

  Future<void> sendMessage(String text, {String? attachmentPath}) async {
    if (text.trim().isEmpty && attachmentPath == null) return;

    // 1. Add User Message
    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: SenderType.user,
      timestamp: DateTime.now(),
      attachmentPath: attachmentPath,
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    // 2. Call API
    try {
      final aiResponse = await _repository.askQuestion(text, attachmentPath: attachmentPath);
      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final repository = ref.read(aiAssistantRepositoryProvider);
  return AiChatNotifier(repository);
});
