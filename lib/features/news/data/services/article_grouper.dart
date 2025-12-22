import 'dart:developer' as developer;
import 'dart:math' as math;
import '../models/news_article.dart';
import '../models/article_cluster.dart';

/// Service for article grouping based on same-story detection
/// Groups articles from DIFFERENT sources that cover the same news story
class ArticleGrouper {
  // Lowered threshold - Turkish titles are often paraphrased differently
  static const double _similarityThreshold = 0.35;

  /// Groups articles into clusters based on strict same-story criteria
  /// Never groups articles from the same source
  /// Returns both multi-source clusters and ungrouped single articles
  List<ArticleCluster> groupArticles(List<NewsArticle> articles) {
    final clusters = <ArticleCluster>[];
    final processed = <String>{};

    for (int i = 0; i < articles.length; i++) {
      if (processed.contains(articles[i].id)) continue;

      final cluster = [articles[i]];
      processed.add(articles[i].id);

      // Find similar articles from DIFFERENT sources only
      for (int j = i + 1; j < articles.length; j++) {
        if (processed.contains(articles[j].id)) continue;

        // Critical: Never group articles from the same source
        if (articles[i].sourceId == articles[j].sourceId) continue;

        final similarity = _calculateSimilarity(articles[i], articles[j]);

        if (similarity >= _similarityThreshold) {
          cluster.add(articles[j]);
          processed.add(articles[j].id);
        }
      }

      // Create cluster (even if single article)
      clusters.add(ArticleCluster(articles: cluster, similarityScore: cluster.length > 1 ? _similarityThreshold : 1.0));
    }

    final multiSourceCount = clusters.where((c) => c.isMultiSource).length;
    developer.log(
      'Grouped ${articles.length} articles: $multiSourceCount multi-source, ${clusters.length - multiSourceCount} single',
    );

    return clusters;
  }

  /// Calculates similarity score between two articles
  /// Uses multiple signals: title words, named entities, keywords, category
  double _calculateSimilarity(NewsArticle a, NewsArticle b) {
    // 1. Jaccard title similarity (30% weight)
    final titleSimilarity = _calculateTitleSimilarity(a.title, b.title);

    // 2. Named entity overlap - proper nouns, names (35% weight)
    final entitySimilarity = _calculateEntityOverlap(a.title, b.title);

    // 3. Keyword overlap (25% weight)
    final keywordSimilarity = _calculateKeywordOverlap(a.title, b.title);

    // 4. Category match bonus (10% weight)
    final categoryBonus = _calculateCategoryBonus(a.category, b.category);

    final score =
        (titleSimilarity * 0.30) + (entitySimilarity * 0.35) + (keywordSimilarity * 0.25) + (categoryBonus * 0.10);

    return score;
  }

  /// Calculates overlap of named entities (capitalized words, likely proper nouns)
  double _calculateEntityOverlap(String title1, String title2) {
    final entities1 = _extractNamedEntities(title1);
    final entities2 = _extractNamedEntities(title2);

    if (entities1.isEmpty && entities2.isEmpty) return 0.0;
    if (entities1.isEmpty || entities2.isEmpty) return 0.0;

    final intersection = entities1.intersection(entities2).length;
    final minCount = math.min(entities1.length, entities2.length);

    // If ANY named entity matches, that's a strong signal
    return minCount > 0 ? intersection / minCount : 0.0;
  }

  /// Extracts likely named entities (proper nouns, names, places)
  Set<String> _extractNamedEntities(String title) {
    final entities = <String>{};

    // Split by spaces, keeping original case first
    final words = title.split(RegExp(r'\s+'));

    for (final word in words) {
      // Skip short words and common prefixes
      if (word.length < 3) continue;

      // Clean punctuation but keep the word
      final cleaned = word.replaceAll(RegExp(r"[^\w\sıİğĞüÜşŞöÖçÇ']"), '');
      if (cleaned.isEmpty) continue;

      // Likely a named entity if starts with uppercase
      // (Turkish proper nouns, names, places, organizations)
      if (cleaned[0] == cleaned[0].toUpperCase() && cleaned[0] != cleaned[0].toLowerCase()) {
        // Normalize for comparison
        entities.add(_normalizeTurkish(cleaned));
      }
    }

    // Also extract quoted terms as entities
    final quotedPattern = RegExp(r'''["'][^"']+["']''');
    for (final match in quotedPattern.allMatches(title)) {
      final quoted = match.group(0)!.replaceAll(RegExp(r'''["']'''), '').trim();
      if (quoted.length >= 3) {
        entities.add(_normalizeTurkish(quoted));
      }
    }

    return entities;
  }

  /// Category matching bonus
  double _calculateCategoryBonus(String? cat1, String? cat2) {
    if (cat1 == null || cat2 == null) return 0.0;
    if (cat1.isEmpty || cat2.isEmpty) return 0.0;

    final norm1 = _normalizeTurkish(cat1);
    final norm2 = _normalizeTurkish(cat2);

    if (norm1 == norm2) return 1.0;

    // Partial match for related categories
    if (norm1.contains(norm2) || norm2.contains(norm1)) return 0.5;

    return 0.0;
  }

  /// Calculates title similarity using Jaccard similarity with Turkish normalization
  double _calculateTitleSimilarity(String title1, String title2) {
    final words1 = _normalizeAndTokenize(title1);
    final words2 = _normalizeAndTokenize(title2);

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Calculates keyword overlap focusing on important terms
  double _calculateKeywordOverlap(String title1, String title2) {
    final keywords1 = _extractKeywords(title1);
    final keywords2 = _extractKeywords(title2);

    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;

    final commonKeywords = keywords1.intersection(keywords2);
    final maxKeywords = keywords1.length > keywords2.length ? keywords1.length : keywords2.length;

    return maxKeywords > 0 ? commonKeywords.length / maxKeywords : 0.0;
  }

  /// Normalizes Turkish characters to ASCII equivalents
  String _normalizeTurkish(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
  }

  /// Normalizes Turkish text and tokenizes into words
  Set<String> _normalizeAndTokenize(String text) {
    final normalized = _normalizeTurkish(text)
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2) // Filter short words
        .toSet();

    return normalized;
  }

  /// Extracts important keywords from title
  Set<String> _extractKeywords(String title) {
    final words = _normalizeAndTokenize(title);

    // Comprehensive Turkish stop words including journalism terms
    const stopWords = {
      // Common words
      'bir', 'bu', 've', 'icin', 'ile', 'daha', 'sonra', 'var', 'yok',
      'olan', 'gibi', 'kadar', 'cok', 'sey', 'her', 'ama', 'veya',
      'cunku', 'ancak', 'gore', 'karsi', 'bile', 'boyle', 'simdi',
      'den', 'dan', 'ten', 'tan', 'nin', 'nun', 'ler', 'lar',
      // Journalism common terms
      'haber', 'haberler', 'son', 'dakika', 'gundem', 'yeni',
      'aciklama', 'aciklamasi', 'duyuru', 'gelisme', 'detay',
      'haberi', 'haberleri', 'bugun', 'dun', 'yarin',
      // Verbs commonly used
      'oldu', 'olacak', 'yapti', 'yapildi', 'dedi', 'soyledi',
      'acikladi', 'paylasti', 'duyurdu', 'bildirdi', 'belirtti',
      'konustu', 'anlatti', 'geldi', 'gitti', 'kaldi', 'cikti',
    };

    // Filter stop words, keep words with 3+ chars
    return words.where((word) => !stopWords.contains(word) && word.length >= 3).toSet();
  }
}
