import 'dart:ui';
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
    this.backgroundColor = AppColors.frostedMint, // Soft mint-tinted frosted glass with high contrast
    this.activeCapsuleColor = AppColors.primaryGreen, // Deep green active capsule
    this.activeItemColor = Colors.white,
    this.inactiveItemColor = AppColors.sageGrey, // Sleek dark sage-grey for unselected items
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgContainerColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE8ECEF);
    final unselectedColor = isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: bgContainerColor.withValues(alpha: isDark ? 0.95 : 0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 6),
                          // Icon + optional Badge
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                  size: 22,
                                  color: isSelected ? activeColor : unselectedColor,
                                ),
                              ),
                              if (item.showBadge)
                                Positioned(
                                  right: -4,
                                  top: -2,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentYellow,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Label
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? activeColor : unselectedColor,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          // Bottom indicator line (active state)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            height: 3,
                            width: isSelected ? 24 : 0,
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3),
                                topRight: Radius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
