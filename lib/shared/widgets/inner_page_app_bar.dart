import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';

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
  return AppBar(
    backgroundColor: const Color(0xFF385A2E),
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
      onPressed: onBack ?? () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    actions: [
      if (showLanguage) const GlobeLanguagePicker(iconColor: Colors.white, iconSize: 22),
      if (showNotification) const NotificationBell(iconColor: Colors.white),
      if (extraActions != null) ...extraActions,
      const SizedBox(width: 4),
    ],
  );
}
