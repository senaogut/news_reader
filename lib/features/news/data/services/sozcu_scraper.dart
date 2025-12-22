import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/news_article.dart';
import '../models/news_source.dart';
import '../models/scraping_config.dart';
import 'parallel_scraper_service.dart';
import 'scraper_parsing_functions.dart';

/// Scraper specifically designed for sozcu.com.tr
/// Now uses TRUE parallel scraping with Isolates
class SozcuScraper {
  final Dio _dio;
  final ParallelScraperService _parallelService;

  /// Base URL for Sözcü
  static const String baseUrl = 'https://www.sozcu.com.tr';

  /// Source ID for Sözcü
  static const String sourceId = 'sozcu';

  /// Source name for display
  static const String sourceName = 'Sözcü';

  /// Number of concurrent article fetches (legacy mode only)
  static const int _concurrentFetches = 5;

  SozcuScraper({Dio? dio, ParallelScraperService? parallelService})
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

  /// Scrape articles from Sözcü main page
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
      parseFunction: parseSozcuArticle, // TOP-LEVEL function
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

    // 1. Look for swiper slides containing article links
    final swiperSlides = document.querySelectorAll('.swiper-slide a[href]');

    articleElements = swiperSlides.where((el) {
      final href = el.attributes['href'] ?? '';
      final hasSozcuDomain = href.contains('sozcu.com.tr');
      final hasPattern = RegExp(r'-p\d{6}').hasMatch(href);
      return hasSozcuDomain && hasPattern;
    }).toList();

    // 2. Fallback: Look for any article links with -p pattern
    if (articleElements.isEmpty) {
      final allLinks = document.querySelectorAll('a[href]');
      articleElements = allLinks.where((el) {
        final href = el.attributes['href'] ?? '';
        return RegExp(r'sozcu\.com\.tr/.*-p\d{6}').hasMatch(href) || 
            RegExp(r'^/.*-p\d{6}$').hasMatch(href);
      }).toList();
    }

    // 3. Ultimate fallback: Any link containing article-like paths
    if (articleElements.isEmpty) {
      final allLinks = document.querySelectorAll('a[href*="sozcu.com.tr"]');
      articleElements = allLinks.where((el) {
        final href = el.attributes['href'] ?? '';
        return !href.contains('/video/') &&
            !href.contains('/foto-galeri/') &&
            !href.contains('/yazarlar/') &&
            href.split('/').length > 4;
      }).toList();
    }

    for (final element in articleElements) {
      if (links.length >= maxCount) break;

      var url = element.attributes['href'];
      if (url == null || url.isEmpty) continue;

      url = _normalizeUrl(url);

      if (seenUrls.contains(url)) continue;

      if (url.contains('/video/') ||
          url.contains('/galeri/') ||
          url.contains('/foto-galeri/') ||
          url.contains('/kategori/') ||
          url.contains('/etiket/') ||
          url.contains('/yazar/') ||
          url.contains('/yazarlar/') ||
          url == baseUrl ||
          url == '$baseUrl/') {
        continue;
      }

      final hasPattern = RegExp(r'-p\d{6}$').hasMatch(url);
      if (!hasPattern) continue;

      var title = element.attributes['title'] ?? element.text.trim();
      title = title.replaceAll(RegExp(r'\s*-\s*Sözcü\s*$'), '').trim();

      if (title.isEmpty || title.length < 10) continue;

      final imgElement = element.querySelector('img');
      var imageUrl = imgElement?.attributes['src'] ?? imgElement?.attributes['data-src'] ?? '';
      if (imageUrl.isNotEmpty) {
        imageUrl = _normalizeUrl(imageUrl);
      }

      final category = 'Genel';
      final articleId = _extractArticleIdFromUrl(url);

      seenUrls.add(url);
      links.add({
        'url': url,
        'title': title,
        'articleId': articleId,
        'category': category,
        'imageUrl': imageUrl,
      });
    }

    return links;
  }

  /// Extract article ID from URL
  String _extractArticleIdFromUrl(String url) {
    final numberMatch = RegExp(r'-p(\d{6})$').firstMatch(url);
    if (numberMatch != null) {
      return numberMatch.group(1)!;
    }
    final fallbackMatch = RegExp(r'-(\d+)').allMatches(url).lastOrNull;
    if (fallbackMatch != null) {
      return fallbackMatch.group(1)!;
    }
    return url.hashCode.abs().toString();
  }

  /// Scrape full article details (legacy mode fallback)
  Future<NewsArticle?> _scrapeArticleDetail({
    required String url,
    required NewsSource source,
  }) async {
    try {
      final response = await _dio.get(url);
      final parsed = parseSozcuArticle(response.data, url);
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
      id: data['articleId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
