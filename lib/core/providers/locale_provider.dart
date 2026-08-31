import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/language_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _init();
  }

  Future<void> _init() async {
    await LanguageService.init();
    state = Locale(LanguageService.currentLanguage.value);
  }

  Future<void> setLocale(String languageCode) async {
    await LanguageService.setLanguage(languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
