import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

/// Compact mini-dropdown language selector that replaces the legacy globe icon.
/// Styled as an elegant, compact rounded capsule showing the active language ('English' / 'አማርኛ')
/// with a dropdown arrow, opening a menu with both options.
class GlobeLanguagePicker extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? textColor;

  const GlobeLanguagePicker({
    super.key,
    this.iconColor,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Detect if this selector is placed on a dark/green header (e.g. iconColor is white)
    final appBarBg = theme.appBarTheme.backgroundColor;
    final bool isHeaderDark = iconColor == Colors.white ||
        (iconColor != null && iconColor!.computeLuminance() > 0.5) ||
        (appBarBg != null && appBarBg.computeLuminance() < 0.5) ||
        (appBarBg == null && (theme.colorScheme.primary.computeLuminance() < 0.5 || AppColors.primaryGreen.computeLuminance() < 0.5));

    final Color resolvedFg = textColor ??
        (isHeaderDark
            ? Colors.white
            : (isDark ? const Color(0xFF8FD883) : const Color(0xFF2C5325)));

    final Color resolvedBg = backgroundColor ??
        (isHeaderDark
            ? Colors.black.withValues(alpha: 0.22)
            : (isDark ? const Color(0xFF1E2E20) : const Color(0xFFEEF5EC)));

    final Color resolvedBorder = isHeaderDark
        ? Colors.white.withValues(alpha: 0.28)
        : (isDark ? const Color(0xFF2E4531) : const Color(0xFFD2E3D0));

    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, currentLang, _) {
        final isAmharic = currentLang == 'am';
        // Full language names: "English" and "አማርኛ" (no abbreviations)
        final displayLabel = isAmharic ? 'አማርኛ' : 'English';

        return Theme(
          data: theme.copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: isDark ? const Color(0xFF1B2B1D) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? const Color(0xFF2E4531) : const Color(0xFFE2ECE0),
                  width: 1,
                ),
              ),
              elevation: 4,
            ),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Language / ቋንቋ',
            offset: const Offset(0, 32),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onSelected: (String langCode) async {
              await LanguageService.setLanguage(langCode);
            },
            itemBuilder: (BuildContext context) => [
              _buildPopupItem(
                code: 'en',
                label: 'English',
                isSelected: !isAmharic,
                isDark: isDark,
              ),
              _buildPopupItem(
                code: 'am',
                label: 'አማርኛ',
                isSelected: isAmharic,
                isDark: isDark,
              ),
            ],
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: resolvedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: resolvedBorder, width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: resolvedFg,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 17,
                    color: resolvedFg,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupItem({
    required String code,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return PopupMenuItem<String>(
      value: code,
      height: 38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryGreen
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 14),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              color: AppColors.primaryGreen,
              size: 16,
            ),
        ],
      ),
    );
  }
}

/// Alias for new naming convention
typedef CompactLanguageSelector = GlobeLanguagePicker;
