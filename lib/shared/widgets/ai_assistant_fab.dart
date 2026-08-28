import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/widgets/hover_scale_widget.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class AiAssistantFab extends StatelessWidget {
  final VoidCallback onTap;

  const AiAssistantFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverScaleWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.brandPurple, // Purpleish brand color for AI
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.psychology, color: Colors.white, size: 28),
      ),
    );
  }
}
