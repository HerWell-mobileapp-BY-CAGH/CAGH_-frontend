import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class GlobeLanguagePicker extends StatelessWidget {
  final Color iconColor;
  final double iconSize;

  const GlobeLanguagePicker({
    super.key,
    this.iconColor = const Color(0xFF385A2E), // AppColors.primaryGreen
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, currentLang, _) {
        return PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.language, color: iconColor, size: iconSize),
          tooltip: 'Change Language / ቋንቋ ይምረጡ',
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (String langCode) async {
            await LanguageService.setLanguage(langCode);
          },
          itemBuilder: (BuildContext context) => LanguageService.supportedLanguages.map((lang) {
            final isSelected = currentLang == lang.code;
            return PopupMenuItem<String>(
              value: lang.code,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${lang.nativeName} (${lang.name})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primaryGreen : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
