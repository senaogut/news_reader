import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/news_article.dart';
import '../models/news_source.dart';
import '../models/scraping_config.dart';
import 'parallel_scraper_service.dart';
import 'scraper_parsing_functions.dart';

/// Scraper specifically designed for haberturk.com
/// Now uses TRUE parallel scraping with Isolates
class HaberturkScraper {
  final Dio _dio;
  final ParallelScraperService _parallelService;

  /// Base URL for Habertürk
  static const String baseUrl = 'https://www.haberturk.com';

  /// Source ID for Habertürk
  static const String sourceId = 'haberturk';

  /// Source name for display
  static const String sourceName = 'Habertürk';

  /// Number of concurrent article fetches (legacy mode only)
  static const int _concurrentFetches = 5;

  HaberturkScraper({Dio? dio, ParallelScraperService? parallelService})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Accept':
                      'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                  'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
                },
              ),
            ),
        _parallelService = parallelService ?? ParallelScraperService();

  /// Scrape articles from Habertürk main page
  /// Uses TRUE parallel fetching with Isolates when config.useTrueParallel is true
  Future<List<NewsArticle>> scrapeMainPage({
    required NewsSource source,
    required ScrapingConfig config,
  }) async {
    final maxArticles = config.getMaxArticlesFor(source.maxArticles);

    try {
      // Fetch main page
      final response = await _dio.get(baseUrl);
      final document = html_parser.parse(response.data);

      // Extract article links from the main page
      final articleLinks = _extractArticleLinks(document, maxArticles);

      if (articleLinks.isEmpty) {
        return [];
      }

      if (!config.fetchFullContent) {
        // Quick mode: just use main page data (no parallel needed)
        return articleLinks
            .map((data) => _createArticleFromMainPageData(data, source))
            .whereType<NewsArticle>()
            .toList();
      }

      // Choose parallel strategy based on config
      if (config.useTrueParallel) {
        // TRUE PARALLEL: All at once with Isolates
        return _scrapeWithTrueParallel(articleLinks, source, config);
      } else {
        // LEGACY: Batched concurrent mode
        return _scrapeWithBatchedConcurrent(articleLinks, source, config);
      }
    } catch (e) {
      dev.log('❌ ${source.name} failed: $e', name: 'Scraper');
      rethrow;
    }
  }

  /// TRUE PARALLEL mode: Fetch and parse ALL articles simultaneously
  Future<List<NewsArticle>> _scrapeWithTrueParallel(
    List<Map<String, String>> articleLinks,
    NewsSource source,
    ScrapingConfig config,
  ) async {
    return _parallelService.scrapeArticlesParallel(
      articleLinks: articleLinks,
      source: source,
      config: config,
      parseFunction: parseHaberturkArticle, // TOP-LEVEL function
    );
  }

  /// LEGACY batched concurrent mode (for comparison/fallback)
  Future<List<NewsArticle>> _scrapeWithBatchedConcurrent(
    List<Map<String, String>> articleLinks,
    NewsSource source,
    ScrapingConfig config,
  ) async {
    final maxArticles = config.getMaxArticlesFor(source.maxArticles);
    final articles = <NewsArticle>[];
    final linksToFetch = articleLinks.take(maxArticles).toList();

    for (int i = 0; i < linksToFetch.length; i += _concurrentFetches) {
      final batch = linksToFetch.skip(i).take(_concurrentFetches).toList();

      final results = await Future.wait(
        batch.map((articleData) async {
          try {
            return await _scrapeArticleDetail(
              url: articleData['url']!,
              source: source,
            );
          } catch (e) {
            return null;
          }
        }),
        eagerError: false,
      );

      articles.addAll(results.whereType<NewsArticle>());

      if (i + _concurrentFetches < linksToFetch.length) {
        await Future.delayed(Duration(milliseconds: config.requestDelayMs ~/ 2));
      }
    }

    dev.log('${source.name}: ${articles.length} articles (legacy mode)', name: 'Scraper');
    return articles;
  }

  /// Normalize URL: convert relative URLs to absolute
  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  /// Extract article links from the main page HTML
  List<Map<String, String>> _extractArticleLinks(Document document, int maxCount) {
    final links = <Map<String, String>>[];
    final seenUrls = <String>{};

    List<Element> articleElements = [];

    // 1. Primary: Articles from main slider swiper
    final mainSliderSection = document.querySelector('section[data-type="mainSlider"]');
    if (mainSliderSection != null) {
      articleElements = mainSliderSection.querySelectorAll('.swiper-slide a.gtm-tracker[data-newsid]');
    }

    // 2. Fallback: Articles from secondary news swiper
    if (articleElements.isEmpty) {
      final secondarySection = document.querySelector('section[data-type="secondaryNews"]');
      if (secondarySection != null) {
        articleElements = secondarySection.querySelectorAll('.swiper-slide a.gtm-tracker[data-newsid]');
      }
    }

    // 3. Fallback: Any swiper slides with gtm-tracker links
    if (articleElements.isEmpty) {
      articleElements = document.querySelectorAll('.swiper-slide a.gtm-tracker[data-newsid]');
    }

    // 4. Fallback: Any link with data-newslist attribute
    if (articleElements.isEmpty) {
      articleElements = document.querySelectorAll('a.gtm-tracker[data-newslist][data-newsid]');
    }

    // 5. Final fallback: any link with data-newsid attribute
    if (articleElements.isEmpty) {
      articleElements = document.querySelectorAll('a[data-newsid][href]');
    }

    for (final element in articleElements) {
      if (links.length >= maxCount) break;

      var url = element.attributes['href'];
      final title = element.attributes['title'] ?? 
          element.attributes['data-newsname'] ?? 
          element.text.trim();
      final newsId = element.attributes['data-newsid'] ?? '';
      final category = element.attributes['data-newscategory'] ?? 'Genel';
      final newsVariant = element.attributes['data-newsvariant'] ?? '';

      if (url == null || url.isEmpty) continue;

      url = _normalizeUrl(url);

      if (seenUrls.contains(url)) continue;

      // Skip ads
      if (category == 'İlandır' || url.contains('adsp.haberturk.com')) {
        continue;
      }

      // Skip non-article URLs
      if (url.contains('/video/') ||
          url.contains('/galeri/') ||
          url.contains('/foto-galeri/') ||
          url.contains('/ekonomi/piyasa/') ||
          url.contains('/kripto-para/') ||
          url.contains('/tummansetler')) {
        continue;
      }

      // Skip if URL doesn't look like a news article
      final articlePattern = RegExp(r'/[a-z0-9-]+-\d{6,}');
      if (!articlePattern.hasMatch(url)) continue;

      final imgElement = element.querySelector('img');
      var imageUrl = imgElement?.attributes['src'] ?? imgElement?.attributes['data-src'] ?? '';
      if (imageUrl.isNotEmpty) {
        imageUrl = _normalizeUrl(imageUrl);
      }

      seenUrls.add(url);
      links.add({
        'url': url,
        'title': title,
        'newsId': newsId,
        'category': category,
        'imageUrl': imageUrl,
        'variant': newsVariant,
      });
    }

    return links;
  }

  /// Scrape full article details (legacy mode fallback)
  Future<NewsArticle?> _scrapeArticleDetail({
    required String url,
    required NewsSource source,
  }) async {
    try {
      final response = await _dio.get(url);
      final parsed = parseHaberturkArticle(response.data, url);
      return parsed?.toNewsArticle(
        sourceId: source.id,
        sourceName: source.name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create article from main page data without fetching full content
  NewsArticle? _createArticleFromMainPageData(Map<String, String> data, NewsSource source) {
    final title = data['title'] ?? '';
    if (title.isEmpty) return null;

    return NewsArticle(
      id: data['newsId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sourceId: source.id,
      sourceName: source.name,
      title: title,
      url: data['url'] ?? '',
      imageUrl: data['imageUrl'],
      content: '',
      briefSummary: '',
      summary: '',
      publishedAt: DateTime.now(),
      scrapedAt: DateTime.now(),
      category: data['category'] ?? 'Genel',
    );
  }
}
