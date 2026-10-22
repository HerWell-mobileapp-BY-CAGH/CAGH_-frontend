import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/learning/domain/models/learning_module.dart';

class LearningApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Fetch all published categories with their nested topics
  static Future<List<CategoryModel>> fetchCategories() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.learningCategories}');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawList = decoded is Map && decoded.containsKey('results')
            ? decoded['results'] as List<dynamic>
            : (decoded is List ? decoded : []);

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => CategoryModel.fromJson(item))
            .toList();
      } else {
        AppLogger.d('LearningApiService.fetchCategories failed: status ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.d('LearningApiService.fetchCategories error: $e');
    }
    return [];
  }

  /// Fetch all published articles, optionally filtered by category, topic, or search query
  static Future<List<ArticleModel>> fetchArticles({
    String? categoryId,
    String? topicId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }
      if (topicId != null && topicId.isNotEmpty) {
        queryParams['topic'] = topicId;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['q'] = search.trim();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.learningArticles}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawList = decoded is Map && decoded.containsKey('results')
            ? decoded['results'] as List<dynamic>
            : (decoded is List ? decoded : []);

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => ArticleModel.fromJson(item))
            .toList();
      } else {
        AppLogger.d('LearningApiService.fetchArticles failed: status ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.d('LearningApiService.fetchArticles error: $e');
    }
    return [];
  }

  /// Fetch a single article's full detail
  static Future<ArticleModel?> fetchArticleDetail(String articleId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.learningArticles}$articleId/');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return ArticleModel.fromJson(decoded);
        }
      }
    } catch (e) {
      AppLogger.d('LearningApiService.fetchArticleDetail error: $e');
    }
    return null;
  }

  /// Toggle bookmark for an article on the backend.
  /// Returns the updated bookmark status (true if bookmarked, false if removed).
  static Future<bool?> toggleBookmark(String articleId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.learningArticles}$articleId/bookmark/');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('is_bookmarked')) {
            return decoded['is_bookmarked'] == true;
          }
          if (decoded['status'] == 'bookmarked') return true;
          if (decoded['status'] == 'unbookmarked') return false;
        }
        return true;
      }
    } catch (e) {
      AppLogger.d('LearningApiService.toggleBookmark error: $e');
    }
    return null;
  }

  /// Fetch all bookmarks for the authenticated user
  static Future<List<ArticleModel>> fetchBookmarks() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.learningBookmarks}');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawList = decoded is Map && decoded.containsKey('results')
            ? decoded['results'] as List<dynamic>
            : (decoded is List ? decoded : []);

        final List<ArticleModel> articles = [];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            if (item['article_detail'] is Map<String, dynamic>) {
              articles.add(ArticleModel.fromJson(item['article_detail']));
            } else if (item['article'] is Map<String, dynamic>) {
              articles.add(ArticleModel.fromJson(item['article']));
            }
          }
        }
        return articles;
      }
    } catch (e) {
      AppLogger.d('LearningApiService.fetchBookmarks error: $e');
    }
    return [];
  }
}
