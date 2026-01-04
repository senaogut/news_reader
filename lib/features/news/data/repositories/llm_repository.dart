import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/news_article.dart';
import '../models/news_category.dart';
import '../models/article_cluster.dart';
import '../../../../core/services/prompt_service.dart';

/// Repository for LLM-based summarization
abstract class LlmRepository {
  /// Generate a brief summary for cards (1-2 sentences)
  Future<String> generateBriefSummary(String content);

  /// Generate a detailed summary for article detail screen
  Future<String> generateDetailedSummary(String content);

  /// Generate a combined summary from multiple articles
  Future<String> generateCombinedSummary(List<NewsArticle> articles);

  /// Process article cluster with summaries for each article + group summary
  Future<ClusterSummaryResult> processCluster(ArticleCluster cluster);

  /// Batch process multiple clusters concurrently
  Future<List<ClusterSummaryResult>> batchProcessClusters(List<ArticleCluster> clusters);
}

/// Result of processing an article cluster
class ClusterSummaryResult {
  final ArticleCluster cluster;
  final Map<String, ArticleSummary> articleSummaries; // sourceId -> summary
  final String? groupSummary; // null for single-article clusters
  final NewsCategory category; // AI-determined category for the cluster

  const ClusterSummaryResult({
    required this.cluster,
    required this.articleSummaries,
    this.groupSummary,
    this.category = NewsCategory.other,
  });
}

/// Summary for a single article
class ArticleSummary {
  final String briefSummary;
  final String detailedSummary;
  final NewsCategory category;

  const ArticleSummary({required this.briefSummary, required this.detailedSummary, this.category = NewsCategory.other});
}

/// Gemini-based implementation with concurrent processing
class GeminiLlmRepository implements LlmRepository {
  late final GenerativeModel _model;
  final PromptService _promptService;

  GeminiLlmRepository({PromptService? promptService}) : _promptService = promptService ?? PromptService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Gemini 2.5 Flash - With billing enabled, concurrent processing is fine
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 4096, topP: 0.95),
    );
  }

  @override
  Future<String> generateBriefSummary(String content) async {
    final article = NewsArticle(
      id: 'temp',
      title: '',
      content: content,
      url: '',
      sourceId: '',
      sourceName: '',
      publishedAt: DateTime.now(),
      scrapedAt: DateTime.now(),
      category: '',
      briefSummary: '',
      summary: '',
    );

    final result = await processCluster(ArticleCluster(articles: [article], similarityScore: 1.0));

    return result.articleSummaries.values.first.briefSummary;
  }

  @override
  Future<String> generateDetailedSummary(String content) async {
    final article = NewsArticle(
      id: 'temp',
      title: '',
      content: content,
      url: '',
      sourceId: '',
      sourceName: '',
      publishedAt: DateTime.now(),
      scrapedAt: DateTime.now(),
      category: '',
      briefSummary: '',
      summary: '',
    );

    final result = await processCluster(ArticleCluster(articles: [article], similarityScore: 1.0));

    return result.articleSummaries.values.first.detailedSummary;
  }

  @override
  Future<String> generateCombinedSummary(List<NewsArticle> articles) async {
    if (articles.isEmpty) return 'No articles to summarize.';

    final cluster = ArticleCluster(articles: articles, similarityScore: 0.8);

    final result = await processCluster(cluster);
    return result.groupSummary ?? 'No summary available.';
  }

  @override
  Future<ClusterSummaryResult> processCluster(ArticleCluster cluster) async {
    try {
      if (cluster.articles.isEmpty) {
        return _createFallbackResult(cluster);
      }

      String prompt;
      if (cluster.isMultiSource) {
        prompt = _promptService.groupedArticlesPrompt(cluster.articles);
      } else {
        prompt = _promptService.singleArticlePrompt(cluster.articles.first);
      }

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        developer.log('❌ Empty response from LLM');
        return _createFallbackResult(cluster);
      }

      // Parse JSON response - clean control characters first
      final jsonResponse = _extractAndCleanJson(responseText);

      Map<String, dynamic> data;
      try {
        data = json.decode(jsonResponse) as Map<String, dynamic>;
      } catch (parseError) {
        developer.log('❌ JSON Parse Error. Full response:\n$responseText', error: parseError);
        developer.log('❌ Extracted JSON that failed:\n$jsonResponse', error: parseError);

        // Try to salvage partial response if possible
        data = _tryRecoverPartialJson(jsonResponse);

        // If recovery failed, use fallback
        if (data.isEmpty) {
          developer.log('❌ Partial recovery also failed, using fallback');
          return _createFallbackResult(cluster);
        } else {
          developer.log('⚠️ Recovered partial JSON with ${data.keys.length} keys');
        }
      }

      // Build article summaries map with safe null handling
      final articleSummaries = <String, ArticleSummary>{};

      // Parse category from response (shared for all articles in cluster)
      final categoryStr = data['category'] as String?;
      final category = NewsCategory.fromString(categoryStr);

      if (cluster.isMultiSource) {
        // Multi-source cluster - match by sourceId from response to cluster articles
        final articlesData = data['articles'] as List<dynamic>?;
        if (articlesData != null) {
          for (final articleData in articlesData) {
            final dataMap = articleData as Map<String, dynamic>;
            final sourceId = dataMap['sourceId'] as String?;

            if (sourceId != null) {
              // Find matching article in cluster by sourceId
              final matchingArticle = cluster.articles.firstWhere(
                (a) => a.sourceId.toLowerCase() == sourceId.toLowerCase(),
                orElse: () => cluster.articles.first,
              );

              articleSummaries[matchingArticle.sourceId] = ArticleSummary(
                briefSummary: dataMap['briefSummary'] as String? ?? 'AI özeti kullanılamıyor',
                detailedSummary: dataMap['detailedSummary'] as String? ?? 'AI özeti kullanılamıyor',
                category: category,
              );
            }
          }
        }

        // Fill in any missing articles with fallback
        for (final article in cluster.articles) {
          if (!articleSummaries.containsKey(article.sourceId)) {
            articleSummaries[article.sourceId] = ArticleSummary(
              briefSummary: 'Özet kısmen oluşturuldu',
              detailedSummary: 'Bu kaynak için AI özeti tamamlanamadı.',
              category: category,
            );
          }
        }

        return ClusterSummaryResult(
          cluster: cluster,
          articleSummaries: articleSummaries,
          groupSummary: data['groupSummary'] as String? ?? 'Grup özeti kullanılamıyor',
          category: category,
        );
      } else {
        // Single article
        final article = cluster.articles.first;
        articleSummaries[article.sourceId] = ArticleSummary(
          briefSummary: data['briefSummary'] as String? ?? 'AI özeti kullanılamıyor',
          detailedSummary: data['detailedSummary'] as String? ?? 'AI özeti kullanılamıyor',
          category: category,
        );

        return ClusterSummaryResult(
          cluster: cluster,
          articleSummaries: articleSummaries,
          groupSummary: null,
          category: category,
        );
      }
    } catch (e, stack) {
      developer.log('❌ Unexpected error in processCluster: $e', error: e, stackTrace: stack);
      return _createFallbackResult(cluster);
    }
  }

  /// Creates a fallback result when AI processing fails completely
  ClusterSummaryResult _createFallbackResult(ArticleCluster cluster) {
    final articleSummaries = <String, ArticleSummary>{};

    for (final article in cluster.articles) {
      articleSummaries[article.sourceId] = const ArticleSummary(
        briefSummary: 'AI özeti oluşturulamadı',
        detailedSummary: 'Bu makale için AI özeti şu anda kullanılamıyor. Lütfen tam makaleyi okuyun.',
        category: NewsCategory.other,
      );
    }

    return ClusterSummaryResult(
      cluster: cluster,
      articleSummaries: articleSummaries,
      groupSummary: cluster.isMultiSource ? 'Grup özeti oluşturulamadı' : null,
      category: NewsCategory.other,
    );
  }

  @override
  Future<List<ClusterSummaryResult>> batchProcessClusters(List<ArticleCluster> clusters) async {
    developer.log('Processing ${clusters.length} articles with AI (concurrent)...');

    // Process ALL clusters concurrently with Future.wait!
    // 90 RPM capacity means we can handle up to 90 articles at once
    final results = await Future.wait(clusters.map((cluster) => processCluster(cluster)));

    return results;
  }

  /// Extracts JSON from response text and cleans control characters
  String _extractAndCleanJson(String text) {
    String jsonText = text.trim();

    // Step 1: Remove markdown code blocks if present (```json ... ``` or ``` ... ```)
    // Try multiple patterns to catch variations
    final patterns = [
      RegExp(r'```json\s*([\s\S]*?)\s*```', multiLine: true),
      RegExp(r'```\s*([\s\S]*?)\s*```', multiLine: true),
      RegExp(r'`\s*([\s\S]*?)\s*`', multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(jsonText);
      if (match != null) {
        jsonText = match.group(1)!.trim();
        break;
      }
    }

    // Step 2: If still no valid JSON, try to extract JSON object
    if (!jsonText.startsWith('{')) {
      final jsonStart = jsonText.indexOf('{');
      final jsonEnd = jsonText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonText = jsonText.substring(jsonStart, jsonEnd + 1);
      }
    }

    // Step 3: Fix unescaped newlines and control characters inside JSON strings
    // This is the KEY fix - Gemini returns literal newlines in strings which breaks JSON
    // Step 3: Fix unescaped quotes and control characters inside JSON strings
    jsonText = _fixUnescapedQuotes(jsonText);

    // Step 4: Final cleanup - remove any leading/trailing whitespace
    jsonText = jsonText.trim();

    return jsonText;
  }

  /// Fixes unescaped double quotes inside JSON string values
  /// AI often returns: {"key": "text with "quoted" words"}
  /// Should be: {"key": "text with \"quoted\" words"}
  String _fixUnescapedQuotes(String json) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < json.length) {
      final char = json[i];

      // Look for start of a JSON string value (after : or in array)
      if (char == '"') {
        // Check if this is a key or value start
        // Find what comes before this quote (skip whitespace)
        int prevNonSpace = i - 1;
        while (prevNonSpace >= 0 &&
            (json[prevNonSpace] == ' ' || json[prevNonSpace] == '\n' || json[prevNonSpace] == '\t')) {
          prevNonSpace--;
        }

        final prevChar = prevNonSpace >= 0 ? json[prevNonSpace] : '';
        final isValueStart = prevChar == ':' || prevChar == ',' || prevChar == '[';

        if (isValueStart) {
          // This is the start of a string VALUE - need to find the real end
          buffer.write(char); // Write opening quote
          i++;

          // Find the end of this string value
          final valueEnd = _findStringValueEnd(json, i);
          final stringContent = json.substring(i, valueEnd);

          // Escape any unescaped quotes and control chars in the content
          buffer.write(_escapeStringContent(stringContent));
          buffer.write('"'); // Write closing quote
          i = valueEnd + 1; // Skip past closing quote
          continue;
        }
      }

      buffer.write(char);
      i++;
    }

    return buffer.toString();
  }

  /// Find the end of a JSON string value by looking for structural characters
  /// Returns the index of the closing quote
  int _findStringValueEnd(String json, int start) {
    int i = start;
    bool escaped = false;

    while (i < json.length) {
      final char = json[i];

      if (escaped) {
        escaped = false;
        i++;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        i++;
        continue;
      }

      if (char == '"') {
        // Check what comes after this quote (skip whitespace)
        int nextNonSpace = i + 1;
        while (nextNonSpace < json.length &&
            (json[nextNonSpace] == ' ' || json[nextNonSpace] == '\n' || json[nextNonSpace] == '\t')) {
          nextNonSpace++;
        }

        if (nextNonSpace >= json.length) {
          // End of JSON - this is the closing quote
          return i;
        }

        final nextChar = json[nextNonSpace];
        // If followed by JSON structural character, this is the real end
        if (nextChar == ',' || nextChar == '}' || nextChar == ']' || nextChar == ':') {
          return i;
        }
        // Otherwise it's an embedded quote - continue searching
      }

      i++;
    }

    // Fallback: return end of string
    return json.length;
  }

  /// Escape content inside a JSON string value
  String _escapeStringContent(String content) {
    final buffer = StringBuffer();
    bool escaped = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        buffer.write(char);
        continue;
      }

      switch (char) {
        case '"':
          buffer.write('\\"'); // Escape the quote
          break;
        case '\n':
          buffer.write('\\n');
          break;
        case '\r':
          buffer.write('\\r');
          break;
        case '\t':
          buffer.write('\\t');
          break;
        case '\b':
          buffer.write('\\b');
          break;
        case '\f':
          buffer.write('\\f');
          break;
        default:
          final code = char.codeUnitAt(0);
          if (code < 32) {
            // Skip other control characters
            continue;
          }
          buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// Attempts to recover usable data from truncated/malformed JSON
  /// Handles both single article format and multi-source articles array format
  Map<String, dynamic> _tryRecoverPartialJson(String brokenJson) {
    try {
      // Check if this is a multi-source response (has "articles" array)
      if (brokenJson.contains('"articles"')) {
        return _recoverMultiSourceJson(brokenJson);
      } else {
        return _recoverSingleArticleJson(brokenJson);
      }
    } catch (e) {
      developer.log('❌ Failed to recover partial JSON: $e');
    }
    return {};
  }

  /// Recovers data from truncated single article JSON
  Map<String, dynamic> _recoverSingleArticleJson(String brokenJson) {
    final briefMatch = RegExp(r'"briefSummary"\s*:\s*"([^"]*(?:\\.[^"]*)*)', multiLine: true).firstMatch(brokenJson);

    if (briefMatch == null) return {};

    final briefSummary = briefMatch.group(1)?.trim() ?? 'Özet kısmen oluşturuldu.';

    final detailedMatch = RegExp(
      r'"detailedSummary"\s*:\s*"([^"]*(?:\\.[^"]*)*)',
      multiLine: true,
    ).firstMatch(brokenJson);

    final detailedSummary = detailedMatch?.group(1)?.trim() ?? briefSummary;

    // Try to extract category
    final categoryMatch = RegExp(r'"category"\s*:\s*"([^"]*)"', multiLine: true).firstMatch(brokenJson);

    return {
      'briefSummary': _unescapeRecoveredText(briefSummary),
      'detailedSummary': _unescapeRecoveredText(detailedSummary),
      'category': categoryMatch?.group(1)?.trim(),
    };
  }

  /// Recovers data from truncated multi-source articles array JSON
  Map<String, dynamic> _recoverMultiSourceJson(String brokenJson) {
    final articles = <Map<String, dynamic>>[];

    // Try to extract category first (it's before articles array in our prompt)
    final categoryMatch = RegExp(r'"category"\s*:\s*"([^"]*)"', multiLine: true).firstMatch(brokenJson);

    // Find all article objects using sourceId as anchor
    final sourceIdPattern = RegExp(r'"sourceId"\s*:\s*"([^"]+)"', multiLine: true);

    final matches = sourceIdPattern.allMatches(brokenJson).toList();

    for (int i = 0; i < matches.length; i++) {
      final sourceId = matches[i].group(1) ?? '';
      if (sourceId.isEmpty) continue;

      // Extract the section for this article (from this sourceId to the next one or end)
      final startPos = matches[i].start;
      final endPos = (i + 1 < matches.length) ? matches[i + 1].start : brokenJson.length;
      final articleSection = brokenJson.substring(startPos, endPos);

      // Extract briefSummary and detailedSummary from this section
      final briefMatch = RegExp(r'"briefSummary"\s*:\s*"([^"]*(?:\\.[^"]*)*)').firstMatch(articleSection);

      final detailedMatch = RegExp(r'"detailedSummary"\s*:\s*"([^"]*(?:\\.[^"]*)*)').firstMatch(articleSection);

      // Only add if we have at least briefSummary
      if (briefMatch != null) {
        final brief = _unescapeRecoveredText(briefMatch.group(1)?.trim() ?? '');
        final detailed = detailedMatch != null ? _unescapeRecoveredText(detailedMatch.group(1)?.trim() ?? '') : brief;

        articles.add({
          'sourceId': sourceId,
          'briefSummary': brief.isNotEmpty ? brief : 'Özet kısmen oluşturuldu.',
          'detailedSummary': detailed.isNotEmpty ? detailed : brief,
        });
      }
    }

    if (articles.isEmpty) return {};

    // Try to extract groupSummary
    final groupMatch = RegExp(r'"groupSummary"\s*:\s*"([^"]*(?:\\.[^"]*)*)', multiLine: true).firstMatch(brokenJson);

    final result = <String, dynamic>{'articles': articles, 'category': categoryMatch?.group(1)?.trim()};

    if (groupMatch != null) {
      result['groupSummary'] = _unescapeRecoveredText(groupMatch.group(1)?.trim() ?? '');
    } else {
      // Generate a fallback group summary from the first article's brief summary
      result['groupSummary'] = articles.isNotEmpty
          ? articles.first['briefSummary'] as String
          : 'Grup özeti kısmen oluşturuldu.';
    }

    developer.log('⚠️ Recovered ${articles.length} articles from truncated JSON');
    return result;
  }

  /// Unescape recovered text and clean up truncation artifacts
  String _unescapeRecoveredText(String text) {
    var result = text.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t').replaceAll(r'\"', '"').replaceAll(r'\\', '\\');

    // Remove trailing backslash (truncation artifact)
    while (result.endsWith('\\') || result.endsWith(' \\')) {
      result = result.substring(0, result.length - 1).trimRight();
    }

    // Remove incomplete words at the end (if ends with space + partial word)
    if (result.isNotEmpty && !result.endsWith('.') && !result.endsWith('!') && !result.endsWith('?')) {
      // Find last complete sentence
      final lastPeriod = result.lastIndexOf('.');
      final lastExclaim = result.lastIndexOf('!');
      final lastQuestion = result.lastIndexOf('?');
      final lastSentenceEnd = [lastPeriod, lastExclaim, lastQuestion].reduce((a, b) => a > b ? a : b);

      if (lastSentenceEnd > result.length ~/ 2) {
        // Only truncate if we keep at least half the content
        result = result.substring(0, lastSentenceEnd + 1);
      }
    }

    return result.trim();
  }
}

/// Mock implementation of LlmRepository
class MockLlmRepository implements LlmRepository {
  @override
  Future<String> generateBriefSummary(String content) async {
    return '';
  }

  @override
  Future<String> generateDetailedSummary(String content) async {
    return '';
  }

  @override
  Future<String> generateCombinedSummary(List<NewsArticle> articles) async {
    if (articles.isEmpty) {
      return 'No articles to summarize.';
    }
    return '';
  }

  @override
  Future<ClusterSummaryResult> processCluster(ArticleCluster cluster) async {
    final articleSummaries = <String, ArticleSummary>{};
    for (var article in cluster.articles) {
      articleSummaries[article.sourceId] = const ArticleSummary(briefSummary: '', detailedSummary: '');
    }

    return ClusterSummaryResult(
      cluster: cluster,
      articleSummaries: articleSummaries,
      groupSummary: cluster.isMultiSource ? '' : null,
    );
  }

  @override
  Future<List<ClusterSummaryResult>> batchProcessClusters(List<ArticleCluster> clusters) async {
    return Future.wait(clusters.map((cluster) => processCluster(cluster)));
  }
}
