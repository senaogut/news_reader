import 'dart:developer' as dev;

import '../models/news_article.dart';
import '../models/news_source.dart';
import '../models/scraping_config.dart';
import '../services/haberturk_scraper.dart';
import '../services/hurriyet_scraper.dart';
import '../services/ntv_scraper.dart';
import '../services/sozcu_scraper.dart';

/// Repository for scraping news from sources
abstract class NewsScraperRepository {
  /// Scrape news from a single source
  /// [config] allows customizing scraping behavior (limits, delays, etc.)
  Future<List<NewsArticle>> scrapeSource(NewsSource source, {ScrapingConfig config = ScrapingConfig.defaultConfig});

  /// Scrape news from multiple sources
  /// [config] allows customizing scraping behavior (limits, delays, etc.)
  Future<List<NewsArticle>> scrapeSources(
    List<NewsSource> sources, {
    ScrapingConfig config = ScrapingConfig.defaultConfig,
  });

  /// Scrape sources with streaming results (progressive loading)
  /// Yields cumulative results as each source completes
  Stream<List<NewsArticle>> scrapeSourcesStream(
    List<NewsSource> sources, {
    ScrapingConfig config = ScrapingConfig.defaultConfig,
  });
}

/// Real implementation of NewsScraperRepository
/// Uses TRUE parallel execution - all sources scraped simultaneously
class DefaultNewsScraperRepository implements NewsScraperRepository {
  final HaberturkScraper _haberturkScraper;
  final NtvScraper _ntvScraper;
  final SozcuScraper _sozcuScraper;
  final HurriyetScraper _hurriyetScraper;

  DefaultNewsScraperRepository({
    HaberturkScraper? haberturkScraper,
    NtvScraper? ntvScraper,
    SozcuScraper? sozcuScraper,
    HurriyetScraper? hurriyetScraper,
  }) : _haberturkScraper = haberturkScraper ?? HaberturkScraper(),
       _ntvScraper = ntvScraper ?? NtvScraper(),
       _sozcuScraper = sozcuScraper ?? SozcuScraper(),
       _hurriyetScraper = hurriyetScraper ?? HurriyetScraper();

  @override
  Future<List<NewsArticle>> scrapeSource(
    NewsSource source, {
    ScrapingConfig config = ScrapingConfig.defaultConfig,
  }) async {
    // Route to appropriate scraper based on source ID
    switch (source.id) {
      case 'haberturk':
        return _haberturkScraper.scrapeMainPage(source: source, config: config);
      case 'ntv':
        return _ntvScraper.scrapeMainPage(source: source, config: config);
      case 'sozcu':
        return _sozcuScraper.scrapeMainPage(source: source, config: config);
      case 'hurriyet':
        return _hurriyetScraper.scrapeMainPage(source: source, config: config);
      default:
        dev.log('No scraper for: ${source.id}', name: 'Scraper');
        return [];
    }
  }

  @override
  Future<List<NewsArticle>> scrapeSources(
    List<NewsSource> sources, {
    ScrapingConfig config = ScrapingConfig.defaultConfig,
  }) async {
    final enabledSources = sources.where((s) => s.isEnabled).toList();
    if (enabledSources.isEmpty) return [];

    dev.log('🚀 Parallel scraping ${enabledSources.length} sources...', name: 'Scraper');
    final stopwatch = Stopwatch()..start();

    // TRUE PARALLEL: Launch ALL sources at once with Future.wait
    // No more batching or sequential processing!
    final results = await Future.wait(
      enabledSources.map((source) async {
        try {
          final articles = await scrapeSource(source, config: config);
          dev.log('✅ ${source.name}: ${articles.length} articles', name: 'Scraper');
          return articles;
        } catch (e) {
          dev.log('❌ ${source.name} failed: $e', name: 'Scraper');
          return <NewsArticle>[];
        }
      }),
      eagerError: false, // Continue even if one source fails
    );

    final allArticles = results.expand((articles) => articles).toList();

    stopwatch.stop();
    dev.log('🏁 Scraped ${allArticles.length} articles in ${stopwatch.elapsedMilliseconds}ms', name: 'Scraper');

    return allArticles;
  }

  @override
  Stream<List<NewsArticle>> scrapeSourcesStream(
    List<NewsSource> sources, {
    ScrapingConfig config = ScrapingConfig.defaultConfig,
  }) async* {
    final enabledSources = sources.where((s) => s.isEnabled).toList();
    if (enabledSources.isEmpty) {
      yield [];
      return;
    }

    dev.log('🚀 Stream scraping ${enabledSources.length} sources...', name: 'Scraper');
    final allArticles = <NewsArticle>[];

    // Create futures for all sources
    final futures = enabledSources.map((source) async {
      try {
        final articles = await scrapeSource(source, config: config);
        dev.log('✅ ${source.name}: ${articles.length} articles', name: 'Scraper');
        return articles;
      } catch (e) {
        dev.log('❌ ${source.name} failed: $e', name: 'Scraper');
        return <NewsArticle>[];
      }
    }).toList();

    // Yield results as each source completes (for progressive UI)
    for (final future in futures) {
      final articles = await future;
      allArticles.addAll(articles);
      yield List.from(allArticles);
    }

    dev.log('🏁 Stream complete: ${allArticles.length} articles', name: 'Scraper');
  }
}

/// Alias for backward compatibility
typedef MockNewsScraperRepository = DefaultNewsScraperRepository;
