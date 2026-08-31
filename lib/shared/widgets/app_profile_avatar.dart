import 'package:flutter/material.dart';

/// Premium Warm Amber/Dark Avatar matching design reference
class AppProfileAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String? name;
  final IconData defaultIcon;

  const AppProfileAvatar({
    super.key,
    this.radius = 26,
    this.imageUrl,
    this.name,
    this.defaultIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    // Warm, premium dark amber/brown background matching design reference
    final bgColor = const Color(0xFF382E25);
    final iconColor = const Color(0xFFF5BE6B); // Warm golden amber icon

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (e, s) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(
        defaultIcon,
        color: iconColor,
        size: radius * 1.15,
      ),
    );
  }
}
