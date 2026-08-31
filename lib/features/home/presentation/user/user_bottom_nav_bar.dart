import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';

class UserBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int index)? onTabSelected;

  UserBottomNavBar({
    super.key,
    this.selectedIndex = 1, // Default to Consult tab (1)
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: AppLocalizations.of(context)!.home,
      ),
      FloatingNavBarItem(
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services_rounded,
        label: AppLocalizations.of(context)!.consult,
      ),
      FloatingNavBarItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: AppLocalizations.of(context)!.learn,
      ),
      FloatingNavBarItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: AppLocalizations.of(context)!.aiNearby,
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: AppLocalizations.of(context)!.profile,
      ),
    ];

    return FloatingGlassNavBar(
      selectedIndex: selectedIndex,
      items: items,
      onTabSelected: (index) {
        if (onTabSelected != null) {
          onTabSelected!(index);
        } else {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
    );
  }
}
