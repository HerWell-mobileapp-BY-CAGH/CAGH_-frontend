import 'dart:ui';
import 'package:flutter/material.dart';

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
    this.backgroundColor = const Color(0xF5F6F9F4), // Soft mint-tinted frosted glass with high contrast
    this.activeCapsuleColor = const Color(0xFF274E13), // Deep green active capsule
    this.activeItemColor = Colors.white,
    this.inactiveItemColor = const Color(0xFF4E574B), // Sleek dark sage-grey for unselected items
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFFC8E6C9).withValues(alpha: 0.85),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.16),
                    blurRadius: 26,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 14 : 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF274E13),
                                      Color(0xFF1B5E20),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF274E13).withValues(alpha: 0.38),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                    size: 22,
                                    color: isSelected ? activeItemColor : inactiveItemColor,
                                  ),
                                  if (item.showBadge)
                                    Positioned(
                                      right: -3,
                                      top: -3,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF9800), // Glowing amber notification badge
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: activeItemColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
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
