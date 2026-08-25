import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/providers/ai_chat_provider.dart';

class AiChatBubble extends ConsumerWidget {
  final AiMessage message;

  const AiChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.sender == SenderType.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF315E26) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachmentPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: isUser ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        message.attachmentPath!.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser ? Colors.white : Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.text.isNotEmpty)
              isUser 
                ? Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 12),
                  _buildFeedbackButtons(context, ref),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: message.feedback == AiFeedback.none 
              ? () => ref.read(aiChatProvider.notifier).submitFeedback(message.id, AiFeedback.thumbsUp)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              message.feedback == AiFeedback.thumbsUp ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 14,
              color: message.feedback == AiFeedback.thumbsUp ? Colors.green : Colors.grey,
            ),
          ),
        ),
        InkWell(
          onTap: message.feedback == AiFeedback.none 
              ? () => ref.read(aiChatProvider.notifier).submitFeedback(message.id, AiFeedback.thumbsDown)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              message.feedback == AiFeedback.thumbsDown ? Icons.thumb_down : Icons.thumb_down_outlined,
              size: 14,
              color: message.feedback == AiFeedback.thumbsDown ? Colors.red : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
