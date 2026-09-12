import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType? type,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    SnackBarType resolvedType;
    if (type != null) {
      resolvedType = type;
    } else if (isError) {
      resolvedType = SnackBarType.error;
    } else if (isSuccess) {
      resolvedType = SnackBarType.success;
    } else {
      final lower = message.toLowerCase();
      if (lower.contains('success') || lower.contains('confirmed') || lower.contains('approved') || lower.contains('verified')) {
        resolvedType = SnackBarType.success;
      } else if (lower.contains('fail') || lower.contains('error') || lower.contains('denied') || lower.contains('invalid')) {
        resolvedType = SnackBarType.error;
      } else if (lower.contains('declined') || lower.contains('cancelled') || lower.contains('canceled') || lower.contains('warning')) {
        resolvedType = SnackBarType.warning;
      } else {
        resolvedType = SnackBarType.info;
      }
    }

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) {
      // Fallback if overlay not available
      _showFallbackSnackBar(context, message, resolvedType, duration);
      return;
    }

    Color backgroundColor;
    IconData icon;
    Color iconColor = Colors.white;

    switch (resolvedType) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF315E26); // Primary Green
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = AppColors.errorRed; // Red
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = AppColors.accentOrange; // Orange
        icon = Icons.warning_amber_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = AppColors.accentBlue; // Blue
        icon = Icons.info_outline;
        break;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void _showFallbackSnackBar(
    BuildContext context,
    String message,
    SnackBarType type,
    Duration duration,
  ) {
    Color backgroundColor;
    IconData icon;
    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF315E26);
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = AppColors.errorRed;
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = AppColors.accentOrange;
        icon = Icons.warning_amber_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = AppColors.accentBlue;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    _timer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismissed();
      });
    } else {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -5) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
