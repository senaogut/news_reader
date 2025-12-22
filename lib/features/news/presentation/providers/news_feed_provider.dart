import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_article.dart';
import '../../data/models/news_source.dart';
import '../../data/models/news_category.dart';
import '../../data/models/grouped_news.dart';
import '../../data/repositories/news_scraper_repository.dart';
import '../../data/repositories/llm_repository.dart';
import '../../data/services/article_grouper.dart';

/// Provider for NewsScraperRepository
final newsScraperRepositoryProvider = Provider<NewsScraperRepository>((ref) {
  return DefaultNewsScraperRepository();
});

/// Provider for LlmRepository
final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  return GeminiLlmRepository(); // Using real Gemini implementation
});

/// Provider for ArticleGrouper
final articleGrouperProvider = Provider<ArticleGrouper>((ref) {
  return ArticleGrouper();
});

/// State for news feed
class NewsFeedState {
  final List<NewsArticle> articles;
  final List<GroupedNews> groupedNews;
  final bool isLoading;
  final String? error;
  final String? combinedSummary;

  const NewsFeedState({
    this.articles = const [],
    this.groupedNews = const [],
    this.isLoading = false,
    this.error,
    this.combinedSummary,
  });

  NewsFeedState copyWith({
    List<NewsArticle>? articles,
    List<GroupedNews>? groupedNews,
    bool? isLoading,
    String? error,
    String? combinedSummary,
  }) {
    return NewsFeedState(
      articles: articles ?? this.articles,
      groupedNews: groupedNews ?? this.groupedNews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      combinedSummary: combinedSummary ?? this.combinedSummary,
    );
  }
}

/// Notifier for managing news feed
class NewsFeedNotifier extends Notifier<NewsFeedState> {
  @override
  NewsFeedState build() {
    return const NewsFeedState();
  }

  Future<void> fetchNews(List<NewsSource> sources) async {
    if (sources.isEmpty) {
      state = const NewsFeedState(articles: [], error: 'No news sources selected');
      return;
    }

    dev.log('Fetching news from ${sources.length} sources...', name: 'NewsFeed');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final scraperRepository = ref.read(newsScraperRepositoryProvider);
      final llmRepository = ref.read(llmRepositoryProvider);
      final articleGrouper = ref.read(articleGrouperProvider);

      // Step 1: Scrape articles from all sources
      final articles = await scraperRepository.scrapeSources(sources);

      if (articles.isEmpty) {
        state = const NewsFeedState(articles: [], isLoading: false, error: 'No articles found from selected sources');
        return;
      }

      // Step 2: Group articles by similarity (same story detection)
      final clusters = articleGrouper.groupArticles(articles);

      // Step 3: Process clusters with LLM for summaries
      // CRITICAL: This should NEVER throw - errors are handled within processCluster
      final clusterResults = await llmRepository.batchProcessClusters(clusters);

      // Step 4: Update articles with generated summaries
      // CRITICAL: Always add articles, even if summaries failed
      final updatedArticles = <NewsArticle>[];
      final groupedNews = <GroupedNews>[];

      for (final result in clusterResults) {
        try {
          if (result.cluster.isMultiSource) {
            // Multi-source cluster: Create GroupedNews
            final articlesWithSummaries = result.cluster.articles.map((article) {
              final summary = result.articleSummaries[article.sourceId];
              return article.copyWith(
                briefSummary: summary?.briefSummary ?? 'AI özeti kullanılamıyor',
                summary: summary?.detailedSummary ?? 'AI özeti kullanılamıyor',
              );
            }).toList();

            // Sort by published date (newest first)
            articlesWithSummaries.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

            groupedNews.add(
              GroupedNews(
                id: 'group_${result.cluster.articles.first.id}',
                mainTitle: result.cluster.representative.title,
                articles: articlesWithSummaries,
                briefGroupedSummary: result.groupSummary ?? 'Grup özeti kullanılamıyor',
                groupedSummary: result.groupSummary ?? 'Grup özeti kullanılamıyor',
                latestPublishedAt: articlesWithSummaries.first.publishedAt,
                category: result.category, // Use AI-determined category
                primaryImageUrl: result.cluster.representative.imageUrl,
              ),
            );

            updatedArticles.addAll(articlesWithSummaries);
          } else {
            // Single article: Also add to groupedNews so it displays in UI
            final article = result.cluster.articles.first;
            final summary = result.articleSummaries[article.sourceId];

            final updatedArticle = article.copyWith(
              briefSummary: summary?.briefSummary ?? 'AI özeti kullanılamıyor',
              summary: summary?.detailedSummary ?? 'AI özeti kullanılamıyor',
            );

            updatedArticles.add(updatedArticle);

            // CRITICAL FIX: Single articles must also be in groupedNews for UI to display them
            groupedNews.add(
              GroupedNews(
                id: 'single_${article.id}',
                mainTitle: updatedArticle.title,
                articles: [updatedArticle],
                briefGroupedSummary: updatedArticle.briefSummary,
                groupedSummary: updatedArticle.summary,
                latestPublishedAt: updatedArticle.publishedAt,
                category: result.category, // Use AI-determined category
                primaryImageUrl: updatedArticle.imageUrl,
              ),
            );
          }
        } catch (e) {
          // FALLBACK: If anything fails for this cluster, still show the articles
          dev.log('Error processing cluster result: $e', name: 'NewsFeed');
          for (final article in result.cluster.articles) {
            final fallbackArticle = article.copyWith(
              briefSummary: 'Haber yüklendi, AI özeti beklemede',
              summary: 'Bu makale için AI özeti oluşturulamadı. Lütfen tam içeriği okuyun.',
            );
            updatedArticles.add(fallbackArticle);

            // Also add to groupedNews for UI display
            groupedNews.add(
              GroupedNews(
                id: 'fallback_${article.id}',
                mainTitle: fallbackArticle.title,
                articles: [fallbackArticle],
                briefGroupedSummary: fallbackArticle.briefSummary,
                groupedSummary: fallbackArticle.summary,
                latestPublishedAt: fallbackArticle.publishedAt,
                category: NewsCategory.other, // Default category for fallback
                primaryImageUrl: fallbackArticle.imageUrl,
              ),
            );
          }
        }
      }

      // Sort grouped news by latest published time
      groupedNews.sort((a, b) => b.latestPublishedAt.compareTo(a.latestPublishedAt));

      final multiSourceGroups = groupedNews.where((g) => g.articles.length > 1).length;
      dev.log(
        '✅ ${updatedArticles.length} articles → ${groupedNews.length} groups ($multiSourceGroups multi-source)',
        name: 'NewsFeed',
      );

      state = NewsFeedState(
        articles: updatedArticles,
        groupedNews: groupedNews,
        isLoading: false,
        combinedSummary: null, // Can be generated separately if needed
      );
    } catch (error, stackTrace) {
      dev.log('Error: $error', name: 'NewsFeed', error: error, stackTrace: stackTrace);
      state = NewsFeedState(articles: [], isLoading: false, error: error.toString());
    }
  }

  void clearFeed() {
    state = const NewsFeedState();
  }
}

/// Provider for news feed notifier
final newsFeedNotifierProvider = NotifierProvider<NewsFeedNotifier, NewsFeedState>(() {
  return NewsFeedNotifier();
});
