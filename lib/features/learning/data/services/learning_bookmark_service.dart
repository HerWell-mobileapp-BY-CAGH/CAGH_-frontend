import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/features/learning/data/services/learning_api_service.dart';

class LearningBookmarkService {
  static const String _bookmarksKey = 'bookmarked_learning_modules';
  static final ValueNotifier<Set<String>> bookmarksNotifier = ValueNotifier<Set<String>>({});
  static bool _isInitialized = false;

  /// Load and initialize bookmarks from SharedPreferences, then sync with backend
  static Future<Set<String>> init() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarksKey) ?? [];
    final set = list.toSet();
    bookmarksNotifier.value = set;
    _isInitialized = true;

    // Background sync with backend bookmarks
    _syncWithBackend();

    return set;
  }

  static Future<void> _syncWithBackend() async {
    try {
      final backendBookmarks = await LearningApiService.fetchBookmarks();
      if (backendBookmarks.isNotEmpty) {
        final current = Set<String>.from(bookmarksNotifier.value);
        for (final b in backendBookmarks) {
          current.add(b.id);
        }
        bookmarksNotifier.value = current;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_bookmarksKey, current.toList());
      }
    } catch (_) {}
  }

  /// Get current bookmarked module IDs
  static Future<Set<String>> getBookmarkedIds() async {
    if (!_isInitialized) {
      return await init();
    }
    return bookmarksNotifier.value;
  }

  /// Check if a specific module is bookmarked
  static bool isBookmarkedSync(String moduleId) {
    return bookmarksNotifier.value.contains(moduleId);
  }

  static Future<bool> isBookmarked(String moduleId) async {
    final ids = await getBookmarkedIds();
    return ids.contains(moduleId);
  }

  /// Toggle bookmark status. Returns true if bookmarked, false if removed.
  static Future<bool> toggleBookmark(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = Set<String>.from(bookmarksNotifier.value);
    bool isNowBookmarked = false;

    if (current.contains(moduleId)) {
      current.remove(moduleId);
      isNowBookmarked = false;
    } else {
      current.add(moduleId);
      isNowBookmarked = true;
    }

    bookmarksNotifier.value = current;
    await prefs.setStringList(_bookmarksKey, current.toList());

    // Fire and forget backend sync
    LearningApiService.toggleBookmark(moduleId).catchError((_) => null);

    return isNowBookmarked;
  }

  /// Explicitly add a bookmark
  static Future<void> addBookmark(String moduleId) async {
    if (bookmarksNotifier.value.contains(moduleId)) return;
    final prefs = await SharedPreferences.getInstance();
    final current = Set<String>.from(bookmarksNotifier.value)..add(moduleId);
    bookmarksNotifier.value = current;
    await prefs.setStringList(_bookmarksKey, current.toList());
    LearningApiService.toggleBookmark(moduleId).catchError((_) => null);
  }

  /// Explicitly remove a bookmark
  static Future<void> removeBookmark(String moduleId) async {
    if (!bookmarksNotifier.value.contains(moduleId)) return;
    final prefs = await SharedPreferences.getInstance();
    final current = Set<String>.from(bookmarksNotifier.value)..remove(moduleId);
    bookmarksNotifier.value = current;
    await prefs.setStringList(_bookmarksKey, current.toList());
    LearningApiService.toggleBookmark(moduleId).catchError((_) => null);
  }
}
