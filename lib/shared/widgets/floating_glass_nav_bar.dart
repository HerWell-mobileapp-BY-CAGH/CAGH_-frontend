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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
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
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                    size: 20,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                  if (item.showBadge)
                                    Positioned(
                                      right: -3,
                                      top: -3,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accentYellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
