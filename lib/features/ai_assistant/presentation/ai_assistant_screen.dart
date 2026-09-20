import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/providers/ai_chat_provider.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/widgets/ai_chat_bubble.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/widgets/ai_chat_input_bar.dart';
import 'package:cagh_frontend/features/hotline/presentation/emergency_support_screen.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF315E26), // App green color
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.digitalAiAssistant,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: 
            FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD22B)),
            tooltip: AppLocalizations.of(context)!.emergencySOS,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencySupportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange.withValues(alpha: 0.1)
                  : const Color(0xFFFFF8E1), // Light yellow warning background
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.aiDisclaimer,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF57F17),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat Area
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        return AiChatBubble(message: state.messages[index]);
                      },
                    ),
            ),

            // Loading / Error State
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C5B8B)),
                ),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Suggested Questions
            if (state.suggestedQuestions.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.suggestedQuestions.length,
                  itemBuilder: (context, index) {
                    final question = state.suggestedQuestions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(
                          question,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : const Color(0xFFF0F0F0),
                        onPressed: state.isLoading ? null : () async {
                          await ref.read(aiChatProvider.notifier).sendMessage(question);
                        },
                      ),
                    );
                  },
                ),
              ),

            // Input Bar
            AiChatInputBar(
              onSend: (text, {attachmentPath}) async {
                await ref.read(aiChatProvider.notifier).sendMessage(
                      text,
                      attachmentPath: attachmentPath,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, size: 80, color: Color(0xFF315E26)),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.aiHelpPrompt,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF315E26),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
