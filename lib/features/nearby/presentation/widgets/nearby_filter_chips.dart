import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class NearbyFilterChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const NearbyFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  String _getLocalizedCategory(BuildContext context, String cat) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return cat;
    switch (cat) {
      case 'All': return l10n.all;
      case 'Hospitals': return l10n.hospitals;
      case 'Clinics': return l10n.clinics;
      case 'Pharmacies': return l10n.pharmacies;
      case 'Health Centers': return l10n.healthCenters;
      default: return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          final isEmergency = category == AppLocalizations.of(context)!.emergency;
          
          final unselectedTextColor = isEmergency
              ? Colors.red
              : (isDark ? AppColors.darkPrimary : AppColors.primaryGreen);

          final chipSelectedColor = isEmergency
              ? Colors.red
              : (isDark ? AppColors.darkButtonGreen : AppColors.primaryGreen);

          final chipBg = isEmergency
              ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50)
              : (isDark ? AppColors.darkSurfaceVariant : Colors.white);

          final chipBorderColor = isSelected
              ? Colors.transparent
              : (isEmergency
                  ? Colors.red.shade300
                  : (isDark ? AppColors.darkBorder : AppColors.primaryGreen.withValues(alpha: 0.3)));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _getLocalizedCategory(context, category),
                style: TextStyle(
                  color: isSelected ? Colors.white : unselectedTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => onSelected(category),
              selectedColor: chipSelectedColor,
              backgroundColor: chipBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: chipBorderColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
