import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class ArticleSection {
  final String title;
  final String detail;

  const ArticleSection({
    required this.title,
    required this.detail,
  });

  factory ArticleSection.fromJson(Map<String, dynamic> json) {
    return ArticleSection(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'detail': detail,
      };
}

class ArticleModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String? coverImage;
  final String contentType;
  final List<ArticleSection> sections;
  final String? keyTakeawayTip;
  final int readingTimeMinutes;
  final bool isBookmarked;
  final String? topicId;
  final String? topicName;
  final String? categoryName;
  final String? nextArticleId;
  final String? nextArticleTitle;
  final String? publishedAt;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    this.coverImage,
    this.contentType = 'TEXT',
    this.sections = const [],
    this.keyTakeawayTip,
    this.readingTimeMinutes = 5,
    this.isBookmarked = false,
    this.topicId,
    this.topicName,
    this.categoryName,
    this.nextArticleId,
    this.nextArticleTitle,
    this.publishedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    List<ArticleSection> parsedSections = [];
    if (json['sections'] is List) {
      for (final sec in json['sections']) {
        if (sec is Map<String, dynamic>) {
          parsedSections.add(ArticleSection.fromJson(sec));
        }
      }
    }

    String? nextId;
    String? nextTitle;
    if (json['next_article_detail'] is Map<String, dynamic>) {
      nextId = json['next_article_detail']['id']?.toString();
      nextTitle = json['next_article_detail']['title']?.toString();
    } else if (json['next_article'] != null) {
      nextId = json['next_article']?.toString();
    }

    return ArticleModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      coverImage: json['cover_image']?.toString(),
      contentType: json['content_type']?.toString() ?? 'TEXT',
      sections: parsedSections,
      keyTakeawayTip: json['key_takeaway_tip']?.toString(),
      readingTimeMinutes: (json['reading_time_minutes'] as num?)?.toInt() ?? 5,
      isBookmarked: json['is_bookmarked'] == true,
      topicId: json['topic']?.toString(),
      topicName: json['topic_name']?.toString(),
      categoryName: json['category_name']?.toString(),
      nextArticleId: nextId,
      nextArticleTitle: nextTitle,
      publishedAt: json['published_at']?.toString(),
    );
  }

  ArticleModel copyWith({
    bool? isBookmarked,
  }) {
    return ArticleModel(
      id: id,
      title: title,
      summary: summary,
      content: content,
      coverImage: coverImage,
      contentType: contentType,
      sections: sections,
      keyTakeawayTip: keyTakeawayTip,
      readingTimeMinutes: readingTimeMinutes,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      topicId: topicId,
      topicName: topicName,
      categoryName: categoryName,
      nextArticleId: nextArticleId,
      nextArticleTitle: nextArticleTitle,
      publishedAt: publishedAt,
    );
  }
}

class TopicModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final int articlesCount;
  final int order;
  final String? categoryId;

  const TopicModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = 'circle-dot',
    this.description = '',
    this.articlesCount = 0,
    this.order = 0,
    this.categoryId,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'circle-dot',
      description: json['description']?.toString() ?? '',
      articlesCount: (json['articles_count'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      categoryId: json['category']?.toString(),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String subtitleSummary;
  final String description;
  final int topicsCount;
  final int order;
  final List<TopicModel> topics;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = 'sparkles',
    this.subtitleSummary = '',
    this.description = '',
    this.topicsCount = 0,
    this.order = 0,
    this.topics = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<TopicModel> parsedTopics = [];
    if (json['topics'] is List) {
      for (final t in json['topics']) {
        if (t is Map<String, dynamic>) {
          parsedTopics.add(TopicModel.fromJson(t));
        }
      }
    }
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'sparkles',
      subtitleSummary: json['subtitle_summary']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      topicsCount: (json['topics_count'] as num?)?.toInt() ?? parsedTopics.length,
      order: (json['order'] as num?)?.toInt() ?? 0,
      topics: parsedTopics,
    );
  }
}

class LearningTopicContent {
  final String title;
  final String readTime;
  final String summary;
  final List<String> keyPoints;
  final String detailedBody;
  final String? clinicalTip;
  final String? patientAdvice;
  final List<String>? actionChecklist;
  final ArticleModel? rawArticle;

  const LearningTopicContent({
    required this.title,
    required this.readTime,
    required this.summary,
    required this.keyPoints,
    required this.detailedBody,
    this.clinicalTip,
    this.patientAdvice,
    this.actionChecklist,
    this.rawArticle,
  });

  factory LearningTopicContent.fromArticle(ArticleModel article) {
    final keyPointsList = article.sections
        .map((s) => s.title.isNotEmpty ? '${s.title}: ${s.detail}' : s.detail)
        .toList();
    return LearningTopicContent(
      title: article.title,
      readTime: '${article.readingTimeMinutes} min read',
      summary: article.summary,
      keyPoints: keyPointsList.isNotEmpty
          ? keyPointsList
          : [article.summary],
      detailedBody: article.content,
      clinicalTip: article.keyTakeawayTip,
      patientAdvice: article.summary,
      actionChecklist: article.sections
          .map((s) => s.title)
          .where((t) => t.isNotEmpty)
          .toList(),
      rawArticle: article,
    );
  }
}

class LearningModuleItem {
  final String id;
  final String category;
  final IconData icon;
  final Color themeColor;
  final Color bgLight;
  final Color bgDark;
  final String readTime;
  final String articlesCount;
  final String userBadge;
  final String midwifeBadge;
  final String Function(AppLocalizations l10n) getTitle;
  final String Function(AppLocalizations l10n) getDesc;
  final List<String> keyTakeaways;
  final List<String> topicsCovered;
  final List<LearningTopicContent> topicContents;
  final List<ArticleModel> articles;
  final List<TopicModel> topics;

  LearningModuleItem({
    required this.id,
    required this.category,
    required this.icon,
    required this.themeColor,
    required this.bgLight,
    required this.bgDark,
    required this.readTime,
    required this.articlesCount,
    required this.userBadge,
    required this.midwifeBadge,
    required this.getTitle,
    required this.getDesc,
    required this.keyTakeaways,
    required this.topicsCovered,
    this.topicContents = const [],
    this.articles = const [],
    this.topics = const [],
  });

  LearningModuleItem copyWith({
    List<LearningTopicContent>? topicContents,
    List<ArticleModel>? articles,
    List<TopicModel>? topics,
    List<String>? topicsCovered,
    List<String>? keyTakeaways,
    String? articlesCount,
  }) {
    return LearningModuleItem(
      id: id,
      category: category,
      icon: icon,
      themeColor: themeColor,
      bgLight: bgLight,
      bgDark: bgDark,
      readTime: readTime,
      articlesCount: articlesCount ?? this.articlesCount,
      userBadge: userBadge,
      midwifeBadge: midwifeBadge,
      getTitle: getTitle,
      getDesc: getDesc,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      topicContents: topicContents ?? this.topicContents,
      articles: articles ?? this.articles,
      topics: topics ?? this.topics,
    );
  }
}
