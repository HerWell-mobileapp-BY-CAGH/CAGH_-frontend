import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/widgets/hover_scale_widget.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class AiAssistantFab extends StatelessWidget {
  final VoidCallback onTap;
  final double? size;

  const AiAssistantFab({super.key, required this.onTap, this.size});

  @override
  Widget build(BuildContext context) {
    final btnSize = size ?? 48.0;
    final iconSize = (btnSize * 0.52).roundToDouble();

    return Tooltip(
      message: 'AI Health Assistant',
      child: HoverScaleWidget(
        onTap: onTap,
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: AppColors.brandPurple,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.36),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
