import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class NearbySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTapped;

  const NearbySearchBar({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onChanged,
    required this.onFilterTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textDark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchHospitalsClinicsMidwives,
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                    size: 22,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                          ),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
            ),
            onPressed: onFilterTapped,
          ),
        ),
      ],
    );
  }
}
