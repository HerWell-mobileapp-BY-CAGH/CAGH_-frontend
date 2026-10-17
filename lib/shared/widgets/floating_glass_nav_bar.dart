import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class FloatingNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool showBadge;

  FloatingNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.showBadge = false,
  });
}

class FloatingGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<FloatingNavBarItem> items;
  final ValueChanged<int> onTabSelected;
  final Color backgroundColor;
  final Color activeCapsuleColor;
  final Color activeItemColor;
  final Color inactiveItemColor;

  const FloatingGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTabSelected,
    this.backgroundColor = AppColors.frostedMint,
    this.activeCapsuleColor = AppColors.primaryGreen,
    this.activeItemColor = Colors.white,
    this.inactiveItemColor = AppColors.sageGrey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgContainerColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? AppColors.darkBorder
        : const Color(0xFFE2E8F0).withValues(alpha: 0.85);
    final unselectedColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final tabWidth = totalWidth / items.length;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(end: selectedIndex.toDouble()),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, animPosition, _) {
                final cx = (animPosition + 0.5) * tabWidth;
                final activeIndex = selectedIndex.clamp(0, items.length - 1);
                final activeItem = items[activeIndex];

                return SizedBox(
                  width: totalWidth,
                  height: 82,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Organic Droplet Mound & Floating Pill Canvas
                      CustomPaint(
                        size: Size(totalWidth, 82),
                        painter: _DropletNavBarPainter(
                          activePosition: animPosition,
                          itemCount: items.length,
                          backgroundColor:
                              bgContainerColor.withValues(alpha: isDark ? 0.94 : 0.97),
                          borderColor: borderColor,
                          activeColor: activeColor,
                          isDark: isDark,
                        ),
                      ),

                      // 2. Inactive Tab Icons & Horizontal Baseline Labels
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final dist = (animPosition - index).abs();
                            final iconOpacity = (dist * 2.2).clamp(0.0, 1.0);
                            final textColor = Color.lerp(
                              unselectedColor,
                              activeColor,
                              (1.0 - dist).clamp(0.0, 1.0),
                            )!;
                            final isCurrentTab = dist < 0.45;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => onTabSelected(index),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 4),
                                    // Resting Icon Area (fades out as droplet glides over)
                                    SizedBox(
                                      height: 28,
                                      child: Center(
                                        child: Opacity(
                                          opacity: iconOpacity,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                item.icon,
                                                size: 22,
                                                color: unselectedColor,
                                              ),
                                              if (item.showBadge && iconOpacity > 0.5)
                                                Positioned(
                                                  right: -3,
                                                  top: -2,
                                                  child: Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentYellow,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: bgContainerColor,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Label (perfectly aligned baseline across all tabs)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 11,
                                            fontWeight: isCurrentTab
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            letterSpacing: isCurrentTab ? 0.2 : 0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // 3. Floating Compressed Droplet Bead (Sliding Active Element)
                      Positioned(
                        left: cx - 23,
                        top: 2,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Outer Translucent Droplet Halo
                                Container(
                                  width: 46,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isDark
                                          ? [
                                              activeColor.withValues(alpha: 0.32),
                                              activeColor.withValues(alpha: 0.10),
                                            ]
                                          : [
                                              activeColor.withValues(alpha: 0.20),
                                              activeColor.withValues(alpha: 0.05),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: activeColor.withValues(
                                        alpha: isDark ? 0.45 : 0.25,
                                      ),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withValues(
                                          alpha: isDark ? 0.35 : 0.18,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),

                                // Inner Jewel Bead
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? const [
                                              Color(0xFF63C76F),
                                              Color(0xFF388E3C),
                                            ]
                                          : const [
                                              Color(0xFF3D7530),
                                              Color(0xFF224419),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withValues(
                                          alpha: isDark ? 0.55 : 0.40,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      activeItem.activeIcon ?? activeItem.icon,
                                      key: ValueKey<int>(activeIndex),
                                      size: 19,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.32),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Active Notification Badge
                                if (activeItem.showBadge)
                                  Positioned(
                                    right: 2,
                                    top: 1,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentYellow,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: bgContainerColor,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// CustomPainter that renders the smooth floating pill bar with an organic
/// liquid water-droplet wave/mound dynamically cresting above the active tab.
class _DropletNavBarPainter extends CustomPainter {
  final double activePosition;
  final int itemCount;
  final Color backgroundColor;
  final Color borderColor;
  final Color activeColor;
  final bool isDark;

  _DropletNavBarPainter({
    required this.activePosition,
    required this.itemCount,
    required this.backgroundColor,
    required this.borderColor,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tabWidth = w / itemCount;
    final cx = (activePosition + 0.5) * tabWidth;

    const y0 = 16.0;
    const yTop = 2.0;
    const r = 26.0;

    // 1. Base Floating Pill Path
    final pillPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y0, w, h - y0),
          const Radius.circular(r),
        ),
      );

    // 2. Liquid Droplet Wave / Mound Path
    final moundPath = Path()
      ..moveTo(cx - 38, y0 + 1)
      ..cubicTo(cx - 24, y0, cx - 18, yTop, cx, yTop)
      ..cubicTo(cx + 18, yTop, cx + 24, y0, cx + 38, y0 + 1)
      ..close();

    // 3. Union to create the organic fluid silhouette
    final combinedPath = Path.combine(PathOperation.union, pillPath, moundPath);

    // 4. Multi-Layer Floating Shadows
    final ambientShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.40 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(combinedPath.shift(const Offset(0, 5)), ambientShadowPaint);

    final auraGlowPaint = Paint()
      ..color = activeColor.withValues(alpha: isDark ? 0.14 : 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(combinedPath.shift(const Offset(0, 1)), auraGlowPaint);

    // 5. Fill Body
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(combinedPath, fillPaint);

    // 6. Frosted Glass Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(combinedPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DropletNavBarPainter oldDelegate) {
    return oldDelegate.activePosition != activePosition ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDark != isDark;
  }
}
