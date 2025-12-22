import 'news_article.dart';

/// Represents a cluster of related articles covering the same story
class ArticleCluster {
  final List<NewsArticle> articles;
  final double similarityScore;

  const ArticleCluster({required this.articles, required this.similarityScore});

  /// Returns unique source IDs from all articles in the cluster
  Set<String> get sourceIds => articles.map((a) => a.sourceId).toSet();

  /// Returns the first article (used as representative)
  NewsArticle get representative => articles.first;

  /// Whether this cluster has multiple articles
  bool get isMultiSource => articles.length > 1;

  ArticleCluster copyWith({List<NewsArticle>? articles, double? similarityScore}) {
    return ArticleCluster(
      articles: articles ?? this.articles,
      similarityScore: similarityScore ?? this.similarityScore,
    );
  }
}
