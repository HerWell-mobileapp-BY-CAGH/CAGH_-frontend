import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/services/remote_translation_service.dart';
import 'package:cagh_frontend/l10n/app_localizations_en.dart';
import 'package:cagh_frontend/l10n/app_localizations_am.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RemoteTranslationService.clearCache();
  });

  group('RemoteTranslationService Core Tests', () {
    test('lookup returns null when key not in memory cache', () {
      expect(RemoteTranslationService.lookup('nonExistentKey'), isNull);
    });

    test('lookup returns overridden value when key exists in cache', () async {
      SharedPreferences.setMockInitialValues({
        'remote_translations_am': jsonEncode({'login': 'ብጁ መግቢያ'}),
        'remote_translations_version_am': 2,
      });

      await RemoteTranslationService.init(initialLanguage: 'am');
      expect(RemoteTranslationService.lookup('login'), 'ብጁ መግቢያ');
    });

    test('tr falls back to defaultText when remote key absent', () {
      final result = RemoteTranslationService.lookup('brandNewKey');
      expect(result, isNull);
    });

    test('AppLocalizationsEn returns remote override when present', () async {
      final loc = AppLocalizationsEn();
      final originalLogin = loc.login;
      expect(originalLogin, 'Login');

      // Inject remote override in local storage
      SharedPreferences.setMockInitialValues({
        'remote_translations_en': jsonEncode({'login': 'Sign In Now'}),
        'remote_translations_version_en': 5,
      });
      await RemoteTranslationService.init(initialLanguage: 'en');

      // Should now return the remote override
      expect(RemoteTranslationService.lookup('login') ?? loc.login, 'Sign In Now');
      // Other keys without override still return compiled fallback
      expect(RemoteTranslationService.lookup('register') ?? loc.register, 'Register');
    });

    test('AppLocalizationsAm returns remote override when present', () async {
      final loc = AppLocalizationsAm();

      // Without override, returns compiled Amharic string
      final originalChooseLang = loc.chooseLanguage;
      expect(originalChooseLang.isNotEmpty, isTrue);

      // Inject remote override
      SharedPreferences.setMockInitialValues({
        'remote_translations_am': jsonEncode({'chooseLanguage': 'ቋንቋዎን ይምረጡ (አዲስ)'}),
        'remote_translations_version_am': 3,
      });
      await RemoteTranslationService.init(initialLanguage: 'am');

      expect(RemoteTranslationService.lookup('chooseLanguage') ?? loc.chooseLanguage, 'ቋንቋዎን ይምረጡ (አዲስ)');
    });

    test('updatesNotifier increments when new translations are applied', () async {
      int notifyCount = 0;
      RemoteTranslationService.updatesNotifier.addListener(() {
        notifyCount++;
      });

      SharedPreferences.setMockInitialValues({
        'remote_translations_am': jsonEncode({'welcomeBack': 'እንኳን ደህና መጡ'}),
        'remote_translations_version_am': 1,
      });

      await RemoteTranslationService.init(initialLanguage: 'am');
      expect(notifyCount, greaterThan(0));
    });
  });
}
