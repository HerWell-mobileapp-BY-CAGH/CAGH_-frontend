import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceService {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _textScaleKey = 'app_text_scale';

  /// ValueNotifier holding the current ThemeMode (system, light, dark).
  static final ValueNotifier<ThemeMode> currentThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  
  /// ValueNotifier holding the current Text Scale Factor (0.85, 1.0, 1.15, 1.30).
  static final ValueNotifier<double> currentTextScale = ValueNotifier<double>(1.0);

  static const Map<String, double> textScaleOptions = {
    'Small': 0.85,
    'Default': 1.0,
    'Large': 1.15,
    'Extra Large': 1.30,
  };

  /// Initialize appearance preferences from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme Mode
    final savedThemeStr = prefs.getString(_themeModeKey);
    if (savedThemeStr != null) {
      if (savedThemeStr == 'light') {
        currentThemeMode.value = ThemeMode.light;
      } else if (savedThemeStr == 'dark') {
        currentThemeMode.value = ThemeMode.dark;
      } else {
        currentThemeMode.value = ThemeMode.light;
      }
    } else {
      currentThemeMode.value = ThemeMode.light;
    }

    // Text Scale
    final savedTextScale = prefs.getDouble(_textScaleKey);
    if (savedTextScale != null) {
      currentTextScale.value = savedTextScale;
    }
  }

  /// Change theme mode and save
  static Future<void> setThemeMode(ThemeMode mode) async {
    currentThemeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) {
      modeStr = 'light';
    } else if (mode == ThemeMode.dark) {
      modeStr = 'dark';
    }
    await prefs.setString(_themeModeKey, modeStr);
  }

  /// Change text scale factor and save
  static Future<void> setTextScale(double scale) async {
    currentTextScale.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
  }
}
