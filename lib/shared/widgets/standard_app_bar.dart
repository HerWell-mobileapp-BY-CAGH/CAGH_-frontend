import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/onboarding/presentation/user_type_selection_screen.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showLanguagePicker;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final VoidCallback? onBack;

  const StandardAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showLanguagePicker = false,
    this.actions,
    this.backgroundColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserTypeSelectionScreen(),
                    ),
                  );
                }
              },
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        if (showLanguagePicker) const GlobeLanguagePicker(),
        if (actions != null) ...?actions,
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
