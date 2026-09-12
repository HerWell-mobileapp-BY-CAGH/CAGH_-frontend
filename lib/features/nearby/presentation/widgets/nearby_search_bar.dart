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
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100, // Gray background
              borderRadius: BorderRadius.circular(14), // Rounded rectangle
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchHospitalsClinicsMidwives,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen, size: 22),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: onClear,
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryGreen, width: 1.5),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: AppColors.primaryGreen),
            onPressed: onFilterTapped,
          ),
        ),
      ],
    );
  }
}
