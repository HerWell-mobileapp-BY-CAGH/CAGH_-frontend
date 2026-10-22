import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';

/// Service responsible for fetching, caching, and serving dynamic remote translations
/// managed by the Django backend.
class RemoteTranslationService {
  static const String _storageKeyPrefix = 'remote_translations_';
  static const String _versionKeyPrefix = 'remote_translations_version_';
  static const String _etagKeyPrefix = 'remote_translations_etag_';

  /// In-memory cache of current remote translations for the active language.
  static Map<String, String> _memoryCache = <String, String>{};

  /// Current translation version cached for the active language.
  static int _currentVersion = 0;

  /// Current active language code.
  static String _currentLanguage = 'en';

  /// Notifier that increments whenever new translations are fetched and applied,
  /// causing the app UI to rebuild dynamically without APK rebuild or restart.
  static final ValueNotifier<int> updatesNotifier = ValueNotifier<int>(0);

  /// Synchronous lookup for a translation key from the downloaded remote cache.
  /// Returns null if the key has not been overridden by the backend.
  static String? lookup(String key) {
    final val = _memoryCache[key];
    if (val != null && val.trim().isNotEmpty) {
      return val;
    }
    return null;
  }

  /// Helper to lookup dynamic remote translation, falling back to optional default text
  /// or key name. Useful for new remote-only strings before they exist in ARB.
  static String tr(BuildContext context, String key, {String? defaultText}) {
    try {
      Localizations.localeOf(context);
    } catch (_) {}
    return lookup(key) ?? defaultText ?? key;
  }

  /// Initialize service on app startup.
  /// Loads cached translations from local storage synchronously/immediately so the app
  /// can start offline or render with remote overrides instantly, then kicks off a
  /// background check with the Django API.
  static Future<void> init({String initialLanguage = 'en'}) async {
    _currentLanguage = initialLanguage.toLowerCase().trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      _loadFromLocalCache(prefs, _currentLanguage);
    } catch (e) {
      AppLogger.d('RemoteTranslationService: Error loading initial local cache: $e');
    }

    // Background sync without blocking app initialization
    unawaited(syncTranslations(_currentLanguage));
  }

  /// Reads stored translations from SharedPreferences into memory.
  static void _loadFromLocalCache(SharedPreferences prefs, String lang) {
    try {
      final jsonStr = prefs.getString('$_storageKeyPrefix$lang');
      final version = prefs.getInt('$_versionKeyPrefix$lang') ?? 0;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          _memoryCache = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          _currentVersion = version;
          _currentLanguage = lang;
          updatesNotifier.value++;
          AppLogger.d('RemoteTranslationService: Loaded ${_memoryCache.length} cached translations for $lang (v$version).');
        }
      } else {
        _memoryCache = <String, String>{};
        _currentVersion = 0;
      }
    } catch (e) {
      AppLogger.d('RemoteTranslationService: Cache decode error for $lang: $e');
      _memoryCache = <String, String>{};
      _currentVersion = 0;
    }
  }

  /// Fetch remote translations from Django for the requested language.
  /// Uses ETag and Version conditional checks to avoid downloading unchanged translations.
  static Future<bool> syncTranslations(String langCode, {bool force = false}) async {
    final lang = langCode.toLowerCase().trim();
    final prefs = await SharedPreferences.getInstance();

    // If switching language in-memory, load existing local cache for that language first
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      _loadFromLocalCache(prefs, lang);
      updatesNotifier.value++;
    }

    final cachedVersion = force ? 0 : (_currentVersion);
    final cachedEtag = force ? '' : (prefs.getString('$_etagKeyPrefix$lang') ?? '');

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.translations}?lang=$lang${cachedVersion > 0 ? '&version=$cachedVersion' : ''}',
      );

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (cachedEtag.isNotEmpty) {
        headers['If-None-Match'] = cachedEtag;
      }

      // Add auth token if available (endpoints allow public read, but pass auth if present)
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      // 304 Not Modified: Client cache is current
      if (response.statusCode == 304) {
        AppLogger.d('RemoteTranslationService: Translations for $lang are up-to-date (HTTP 304).');
        return true;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final bool isUpToDate = data['up_to_date'] == true;
        final int version = data['version'] as int? ?? 1;

        if (isUpToDate) {
          AppLogger.d('RemoteTranslationService: Translations for $lang are up-to-date (v$version).');
          return true;
        }

        final rawMap = data['translations'];
        if (rawMap is Map) {
          final Map<String, String> newMap = rawMap.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );

          _memoryCache = newMap;
          _currentVersion = version;
          _currentLanguage = lang;

          // Save to local cache
          await prefs.setString('$_storageKeyPrefix$lang', jsonEncode(newMap));
          await prefs.setInt('$_versionKeyPrefix$lang', version);

          final etag = response.headers['etag'];
          if (etag != null && etag.isNotEmpty) {
            await prefs.setString('$_etagKeyPrefix$lang', etag);
          }

          // Trigger UI rebuild
          updatesNotifier.value++;
          AppLogger.d(
            'RemoteTranslationService: Synced ${newMap.length} translations for $lang (v$version).',
          );
          return true;
        }
      }

      AppLogger.d('RemoteTranslationService: Unexpected response status ${response.statusCode}');
      return false;
    } on SocketException catch (_) {
      AppLogger.d('RemoteTranslationService: Device is offline. Using local cached translations.');
      return false;
    } on TimeoutException catch (_) {
      AppLogger.d('RemoteTranslationService: Translation sync timed out. Using local cache.');
      return false;
    } catch (e) {
      AppLogger.d('RemoteTranslationService: Error syncing translations: $e');
      return false;
    }
  }

  /// Syncs user language preference with Django backend if authenticated.
  static Future<void> syncUserPreference(String lang) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.languageSelect}');
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'language': lang.toLowerCase().trim()}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.d('RemoteTranslationService: Optional preference sync notice: $e');
    }
  }

  /// Clears local remote translations cache (e.g. on logout or debug reset).
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final lang in ['en', 'am']) {
      await prefs.remove('$_storageKeyPrefix$lang');
      await prefs.remove('$_versionKeyPrefix$lang');
      await prefs.remove('$_etagKeyPrefix$lang');
    }
    _memoryCache.clear();
    _currentVersion = 0;
    updatesNotifier.value++;
  }
}
