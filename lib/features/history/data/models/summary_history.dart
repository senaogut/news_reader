import '../../../news/data/models/news_article.dart';

/// Represents a history entry for summarized news
class SummaryHistory {
  final String id;
  final List<String> sourceIds;
  final List<NewsArticle> articles;
  final DateTime createdAt;
  final String combinedSummary;

  const SummaryHistory({
    required this.id,
    required this.sourceIds,
    required this.articles,
    required this.createdAt,
    required this.combinedSummary,
  });

  SummaryHistory copyWith({
    String? id,
    List<String>? sourceIds,
    List<NewsArticle>? articles,
    DateTime? createdAt,
    String? combinedSummary,
  }) {
    return SummaryHistory(
      id: id ?? this.id,
      sourceIds: sourceIds ?? this.sourceIds,
      articles: articles ?? this.articles,
      createdAt: createdAt ?? this.createdAt,
      combinedSummary: combinedSummary ?? this.combinedSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceIds': sourceIds,
      'articles': articles.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'combinedSummary': combinedSummary,
    };
  }

  factory SummaryHistory.fromJson(Map<String, dynamic> json) {
    return SummaryHistory(
      id: json['id'] as String,
      sourceIds: (json['sourceIds'] as List).cast<String>(),
      articles: (json['articles'] as List).map((a) => NewsArticle.fromJson(a as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      combinedSummary: json['combinedSummary'] as String,
    );
  }
}
