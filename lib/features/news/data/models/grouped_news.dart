import 'news_article.dart';
import 'news_category.dart';

/// Represents a group of similar news articles from different sources
class GroupedNews {
  final String id;
  final String mainTitle;
  final List<NewsArticle> articles;
  final String briefGroupedSummary; // Short summary for cards
  final String groupedSummary; // Detailed summary
  final DateTime latestPublishedAt;
  final NewsCategory category; // AI-determined category
  final String? primaryImageUrl;

  const GroupedNews({
    required this.id,
    required this.mainTitle,
    required this.articles,
    required this.briefGroupedSummary,
    required this.groupedSummary,
    required this.latestPublishedAt,
    required this.category,
    this.primaryImageUrl,
  });

  /// Get all unique sources for this grouped news
  List<String> get sources => articles.map((a) => a.sourceName).toSet().toList();

  /// Get source count
  int get sourceCount => sources.length;

  /// Get the primary article (usually the first one or most recent)
  NewsArticle get primaryArticle => articles.first;

  /// Get category display name with emoji
  String get categoryDisplay => category.displayWithEmoji;

  GroupedNews copyWith({
    String? id,
    String? mainTitle,
    List<NewsArticle>? articles,
    String? briefGroupedSummary,
    String? groupedSummary,
    DateTime? latestPublishedAt,
    NewsCategory? category,
    String? primaryImageUrl,
  }) {
    return GroupedNews(
      id: id ?? this.id,
      mainTitle: mainTitle ?? this.mainTitle,
      articles: articles ?? this.articles,
      briefGroupedSummary: briefGroupedSummary ?? this.briefGroupedSummary,
      groupedSummary: groupedSummary ?? this.groupedSummary,
      latestPublishedAt: latestPublishedAt ?? this.latestPublishedAt,
      category: category ?? this.category,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
    );
  }
}
