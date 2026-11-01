import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

/// A shared, consistent AppBar used across ALL inner/sub pages of the app.
/// Matches the same dark-green style and width as the main tab AppBar.
PreferredSizeWidget buildInnerPageAppBar(
  BuildContext context, {
  required String title,
  VoidCallback? onBack,
  List<Widget>? extraActions,
  bool showNotification = false,
  bool showLanguage = true,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final bgColor = isDark ? AppColors.darkSurface : AppColors.primaryGreen;
  final fgColor = isDark ? AppColors.darkTextPrimary : Colors.white;

  return AppBar(
    backgroundColor: bgColor,
    elevation: 0,
    centerTitle: false,
    titleSpacing: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: fgColor, size: 20),
      onPressed: onBack ?? () => Navigator.pop(context),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: fgColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    actions: [
      ...?extraActions,
      if (showLanguage) ...[
        if (extraActions != null && extraActions.isNotEmpty) const SizedBox(width: 8),
        Center(
          child: GlobeLanguagePicker(iconColor: fgColor),
        ),
      ],
      if (showNotification) ...[
        const SizedBox(width: 6),
        NotificationBell(iconColor: fgColor),
      ],
      const SizedBox(width: 14),
    ],
  );
}
