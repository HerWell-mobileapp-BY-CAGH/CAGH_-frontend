import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/appearance_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class AppearanceAccessibilityScreen extends StatefulWidget {
  const AppearanceAccessibilityScreen({super.key});

  @override
  State<AppearanceAccessibilityScreen> createState() => _AppearanceAccessibilityScreenState();
}

class _AppearanceAccessibilityScreenState extends State<AppearanceAccessibilityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.accentYellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.appearanceAccessibility,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Theme'),
            const SizedBox(height: 10),
            _buildGroupedCard([
              _buildRadioTile<ThemeMode>(
                title: 'System Default',
                value: ThemeMode.system,
                groupValue: AppearanceService.currentThemeMode.value,
                onChanged: (val) {
                  if (val != null) {
                    AppearanceService.setThemeMode(val);
                    setState(() {});
                  }
                },
              ),
              _buildDivider(),
              _buildRadioTile<ThemeMode>(
                title: 'Light Mode',
                value: ThemeMode.light,
                groupValue: AppearanceService.currentThemeMode.value,
                onChanged: (val) {
                  if (val != null) {
                    AppearanceService.setThemeMode(val);
                    setState(() {});
                  }
                },
              ),
              _buildDivider(),
              _buildRadioTile<ThemeMode>(
                title: 'Dark Mode',
                value: ThemeMode.dark,
                groupValue: AppearanceService.currentThemeMode.value,
                onChanged: (val) {
                  if (val != null) {
                    AppearanceService.setThemeMode(val);
                    setState(() {});
                  }
                },
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionHeader('Text Size'),
            const SizedBox(height: 10),
            _buildGroupedCard(
              AppearanceService.textScaleOptions.entries.map((entry) {
                final isLast = entry.key == AppearanceService.textScaleOptions.keys.last;
                return Column(
                  children: [
                    _buildRadioTile<double>(
                      title: entry.key,
                      value: entry.value,
                      groupValue: AppearanceService.currentTextScale.value,
                      onChanged: (val) {
                        if (val != null) {
                          AppearanceService.setTextScale(val);
                          setState(() {});
                        }
                      },
                    ),
                    if (!isLast) _buildDivider(),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 16,
      endIndent: 16,
    );
  }
}
