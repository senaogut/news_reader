import 'dart:async';
import 'dart:isolate';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';

import '../models/news_article.dart';
import '../models/news_source.dart';
import '../models/scraping_config.dart';

/// Data class for passing fetch results between isolates
/// Must use only primitive types that can cross isolate boundaries
class FetchResult {
  final String url;
  final String html;
  final bool success;
  final String? error;
  final Map<String, String> metadata;

  const FetchResult({
    required this.url,
    required this.html,
    required this.success,
    this.error,
    this.metadata = const {},
  });
}

/// Data class for parsed article data (isolate-safe)
/// Uses only primitives that can cross isolate boundaries
class ParsedArticleData {
  final String id;
  final String title;
  final String url;
  final String? imageUrl;
  final String content;
  final String category;
  final String? author;
  final List<String> keywords;
  final String? publishedAtIso;
  final String? modifiedAtIso;

  const ParsedArticleData({
    required this.id,
    required this.title,
    required this.url,
    this.imageUrl,
    required this.content,
    required this.category,
    this.author,
    this.keywords = const [],
    this.publishedAtIso,
    this.modifiedAtIso,
  });

  /// Convert to NewsArticle (must be done on main isolate)
  NewsArticle toNewsArticle({
    required String sourceId,
    required String sourceName,
  }) {
    return NewsArticle(
      id: id,
      sourceId: sourceId,
      sourceName: sourceName,
      title: title,
      url: url,
      imageUrl: imageUrl,
      content: content,
      briefSummary: '',
      summary: '',
      publishedAt: publishedAtIso != null
          ? DateTime.tryParse(publishedAtIso!) ?? DateTime.now()
          : DateTime.now(),
      modifiedAt: modifiedAtIso != null ? DateTime.tryParse(modifiedAtIso!) : null,
      scrapedAt: DateTime.now(),
      category: category,
      author: author,
      keywords: keywords,
    );
  }
}

/// Service for TRUE parallel scraping using Isolates
/// 
/// Key differences from concurrent approach:
/// 1. ALL HTTP requests launched simultaneously (no batching)
/// 2. HTML parsing runs in separate Isolates (true multi-core parallelism)
/// 3. Results collected as they complete (not waiting for batches)
class ParallelScraperService {
  final Dio _dio;

  ParallelScraperService({Dio? dio})
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
            );

  /// Fetch a single URL and return the result
  Future<FetchResult> fetchUrl(String url, {Map<String, String>? metadata}) async {
    try {
      final response = await _dio.get(url);
      return FetchResult(
        url: url,
        html: response.data as String,
        success: true,
        metadata: metadata ?? {},
      );
    } catch (e) {
      return FetchResult(
        url: url,
        html: '',
        success: false,
        error: e.toString(),
        metadata: metadata ?? {},
      );
    }
  }

  /// Fetch ALL URLs in TRUE parallel (no batching)
  Future<List<FetchResult>> fetchAllUrls(List<String> urls) async {
    if (urls.isEmpty) return [];

    dev.log('🚀 TRUE PARALLEL: Fetching ${urls.length} URLs simultaneously...', name: 'ParallelScraper');
    final stopwatch = Stopwatch()..start();

    // Launch ALL requests at once - no batching!
    final results = await Future.wait(
      urls.map((url) => fetchUrl(url)),
      eagerError: false,
    );

    stopwatch.stop();
    final successCount = results.where((r) => r.success).length;
    dev.log(
      '🏁 Fetched $successCount/${urls.length} URLs in ${stopwatch.elapsedMilliseconds}ms',
      name: 'ParallelScraper',
    );

    return results;
  }

  /// Fetch URLs with metadata in TRUE parallel
  Future<List<FetchResult>> fetchAllUrlsWithMetadata(
    List<Map<String, String>> urlsWithMetadata,
  ) async {
    if (urlsWithMetadata.isEmpty) return [];

    dev.log('🚀 TRUE PARALLEL: Fetching ${urlsWithMetadata.length} URLs...', name: 'ParallelScraper');
    final stopwatch = Stopwatch()..start();

    // Launch ALL at once
    final results = await Future.wait(
      urlsWithMetadata.map((data) => fetchUrl(
        data['url']!,
        metadata: data,
      )),
      eagerError: false,
    );

    stopwatch.stop();
    final successCount = results.where((r) => r.success).length;
    dev.log(
      '🏁 Fetched $successCount/${urlsWithMetadata.length} in ${stopwatch.elapsedMilliseconds}ms',
      name: 'ParallelScraper',
    );

    return results;
  }

  /// Parse HTML in a TRUE separate Isolate (multi-core parallel)
  /// The parseFunction must be a TOP-LEVEL or STATIC function
  static Future<ParsedArticleData?> parseHtmlInIsolate({
    required String html,
    required String url,
    required ParsedArticleData? Function(String html, String url) parseFunction,
  }) async {
    try {
      // Run parsing in a separate isolate for true parallelism
      return await Isolate.run(() {
        return parseFunction(html, url);
      });
    } catch (e) {
      dev.log('❌ Isolate parse error for $url: $e', name: 'ParallelScraper');
      return null;
    }
  }

  /// Parse multiple HTMLs in TRUE parallel using Isolates
  /// Each parse runs on a separate core
  static Future<List<ParsedArticleData?>> parseAllInIsolates({
    required List<FetchResult> fetchResults,
    required ParsedArticleData? Function(String html, String url) parseFunction,
  }) async {
    final successfulFetches = fetchResults.where((r) => r.success).toList();
    if (successfulFetches.isEmpty) return [];

    dev.log('🔄 TRUE PARALLEL: Parsing ${successfulFetches.length} pages in Isolates...', name: 'ParallelScraper');
    final stopwatch = Stopwatch()..start();

    // Launch ALL parsing in separate Isolates simultaneously
    final results = await Future.wait(
      successfulFetches.map((result) => parseHtmlInIsolate(
        html: result.html,
        url: result.url,
        parseFunction: parseFunction,
      )),
      eagerError: false,
    );

    stopwatch.stop();
    final successCount = results.where((r) => r != null).length;
    dev.log(
      '🏁 Parsed $successCount/${successfulFetches.length} pages in ${stopwatch.elapsedMilliseconds}ms',
      name: 'ParallelScraper',
    );

    return results;
  }

  /// Parse on main thread (for when Isolate overhead isn't worth it)
  static ParsedArticleData? parseHtmlOnMainThread({
    required String html,
    required String url,
    required ParsedArticleData? Function(String html, String url) parseFunction,
  }) {
    try {
      return parseFunction(html, url);
    } catch (e) {
      dev.log('❌ Parse error for $url: $e', name: 'ParallelScraper');
      return null;
    }
  }

  /// Complete scraping pipeline: Fetch + Parse in TRUE parallel
  /// 
  /// This is the main entry point for scrapers to use.
  /// 1. Fetches ALL URLs simultaneously (no batching)
  /// 2. Parses ALL HTML in separate Isolates (true multi-core)
  /// 3. Returns NewsArticle list
  Future<List<NewsArticle>> scrapeArticlesParallel({
    required List<Map<String, String>> articleLinks,
    required NewsSource source,
    required ScrapingConfig config,
    required ParsedArticleData? Function(String html, String url) parseFunction,
  }) async {
    final maxArticles = config.getMaxArticlesFor(source.maxArticles);
    final linksToFetch = articleLinks.take(maxArticles).toList();

    if (linksToFetch.isEmpty) return [];

    dev.log('📰 ${source.name}: Scraping ${linksToFetch.length} articles in TRUE parallel...', name: 'ParallelScraper');
    final totalStopwatch = Stopwatch()..start();

    // STEP 1: Fetch ALL URLs simultaneously (no batching!)
    final fetchResults = await fetchAllUrlsWithMetadata(linksToFetch);

    // STEP 2: Parse ALL HTML in parallel
    List<ParsedArticleData?> parseResults;
    
    if (config.useIsolatesForParsing) {
      // TRUE PARALLEL: Use Isolates for multi-core parsing
      parseResults = await parseAllInIsolates(
        fetchResults: fetchResults,
        parseFunction: parseFunction,
      );
    } else {
      // Concurrent but single-threaded parsing (still all at once, no batching)
      parseResults = await Future.wait(
        fetchResults.where((r) => r.success).map((result) async {
          return parseHtmlOnMainThread(
            html: result.html,
            url: result.url,
            parseFunction: parseFunction,
          );
        }),
        eagerError: false,
      );
    }

    // STEP 3: Convert to NewsArticle objects
    final articles = parseResults
        .whereType<ParsedArticleData>()
        .map((data) => data.toNewsArticle(
              sourceId: source.id,
              sourceName: source.name,
            ))
        .toList();

    totalStopwatch.stop();
    dev.log(
      '✅ ${source.name}: ${articles.length} articles in ${totalStopwatch.elapsedMilliseconds}ms (TRUE PARALLEL)',
      name: 'ParallelScraper',
    );

    return articles;
  }

  /// Scrape with streaming results (for progressive UI updates)
  Stream<NewsArticle> scrapeArticlesStream({
    required List<Map<String, String>> articleLinks,
    required NewsSource source,
    required ScrapingConfig config,
    required ParsedArticleData? Function(String html, String url) parseFunction,
  }) async* {
    final maxArticles = config.getMaxArticlesFor(source.maxArticles);
    final linksToFetch = articleLinks.take(maxArticles).toList();

    if (linksToFetch.isEmpty) return;

    dev.log('📰 ${source.name}: Streaming ${linksToFetch.length} articles...', name: 'ParallelScraper');

    // Launch all fetches
    final futures = linksToFetch.map((linkData) async {
      final fetchResult = await fetchUrl(linkData['url']!, metadata: linkData);
      if (!fetchResult.success) return null;

      // Parse (in isolate if configured)
      ParsedArticleData? parsed;
      if (config.useIsolatesForParsing) {
        parsed = await parseHtmlInIsolate(
          html: fetchResult.html,
          url: fetchResult.url,
          parseFunction: parseFunction,
        );
      } else {
        parsed = parseHtmlOnMainThread(
          html: fetchResult.html,
          url: fetchResult.url,
          parseFunction: parseFunction,
        );
      }

      return parsed?.toNewsArticle(
        sourceId: source.id,
        sourceName: source.name,
      );
    }).toList();

    // Yield articles as they complete
    for (final future in futures) {
      final article = await future;
      if (article != null) {
        yield article;
      }
    }
  }
}
