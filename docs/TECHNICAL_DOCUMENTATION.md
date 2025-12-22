# Smart Reader - Complete Technical Documentation

> **Version:** 2.0.0  
> **Last Updated:** December 2025  
> **Status:** Production-ready with real web scraping and AI summarization

---

## 📖 Project Overview

**Smart Reader** is a production-ready Flutter news aggregation application that:
- Scrapes real-time news from 4 major Turkish news websites
- Uses **Google Gemini AI** to generate intelligent summaries
- Groups similar stories from different sources
- Categorizes news using AI-powered classification

---

## 🏗️ Complete Architecture

```
lib/
├── main.dart                           # App entry point with ProviderScope
│
├── core/                               # Shared resources
│   ├── constants/
│   │   └── app_constants.dart          # Spacing, sizing constants
│   ├── services/
│   │   ├── prompt_service.dart         # LLM prompt generation ✅
│   │   └── storage_service.dart        # Local storage for preferences
│   ├── theme/
│   │   ├── app_colors.dart             # Color palette
│   │   ├── app_text_styles.dart        # Typography
│   │   └── app_theme.dart              # Material theme
│   └── widgets/                        # Reusable UI components
│
└── features/
    ├── news/                           # 📰 Main feature
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── news_source.dart        # Source configuration
    │   │   │   ├── news_article.dart       # Article model
    │   │   │   ├── grouped_news.dart       # Grouped articles
    │   │   │   ├── article_cluster.dart    # Clustering model
    │   │   │   ├── news_category.dart      # 13 predefined categories
    │   │   │   └── scraping_config.dart    # Scraping settings
    │   │   ├── repositories/
    │   │   │   ├── news_source_repository.dart   # Source management
    │   │   │   ├── news_scraper_repository.dart  # Scraping orchestration
    │   │   │   └── llm_repository.dart           # AI integration ✅
    │   │   └── services/
    │   │       ├── haberturk_scraper.dart    # ✅ Real scraper
    │   │       ├── hurriyet_scraper.dart     # ✅ Real scraper
    │   │       ├── ntv_scraper.dart          # ✅ Real scraper
    │   │       ├── sozcu_scraper.dart        # ✅ Real scraper
    │   │       ├── article_grouper.dart      # Same-story detection
    │   │       └── parallel_scraper_service.dart  # Isolate support
    │   │
    │   └── presentation/
    │       ├── providers/
    │       │   ├── news_source_provider.dart
    │       │   └── news_feed_provider.dart
    │       ├── screens/
    │       └── widgets/
    │
    └── history/                        # 📚 History feature
        ├── data/
        └── presentation/
```

---

## 🔧 Web Scraping System

### Overview

The app uses **Dio** for HTTP requests and **html** package for HTML parsing. Each news source has a dedicated scraper class.

### Supported News Sources

| Source | URL | Scraper Class | Status |
|--------|-----|---------------|--------|
| **Habertürk** | haberturk.com | `HaberturkScraper` | ✅ Active |
| **NTV** | ntv.com.tr | `NtvScraper` | ✅ Active |
| **Sözcü** | sozcu.com.tr | `SozcuScraper` | ✅ Active |
| **Hürriyet** | hurriyet.com.tr | `HurriyetScraper` | ✅ Active |

### How Web Scraping Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    NewsScraperRepository                         │
│                    scrapeSources()                               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
     ┌────────────┐   ┌────────────┐   ┌────────────┐
     │ Habertürk  │   │    NTV     │   │   Sözcü    │  ... (parallel)
     │  Scraper   │   │  Scraper   │   │  Scraper   │
     └────────────┘   └────────────┘   └────────────┘
              │               │               │
              ▼               ▼               ▼
     ┌────────────────────────────────────────────┐
     │           Future.wait() (TRUE PARALLEL)    │
     │   All sources scraped simultaneously!      │
     └────────────────────────────────────────────┘
```

### Scraping Process (Per Source)

1. **Fetch Main Page**: Download HTML from news website homepage
2. **Extract Article Links**: Use CSS selectors to find article URLs
3. **Filter URLs**: Skip videos, galleries, non-article pages
4. **Fetch Article Pages**: Concurrent fetching (5 articles at a time)
5. **Parse Content**: Extract title, content, image, author, date
6. **Build Models**: Create `NewsArticle` objects

### Scraper Implementation Details

```dart
// Example: HaberturkScraper
class HaberturkScraper {
  final Dio _dio;
  static const String baseUrl = 'https://www.haberturk.com';
  static const int _concurrentFetches = 5;

  Future<List<NewsArticle>> scrapeMainPage({
    required NewsSource source, 
    required ScrapingConfig config
  }) async {
    // 1. Fetch main page
    final response = await _dio.get(baseUrl);
    final document = html_parser.parse(response.data);
    
    // 2. Extract article links using CSS selectors
    final articleLinks = _extractArticleLinks(document, maxCount);
    
    // 3. Fetch articles in parallel batches
    for (int i = 0; i < articleLinks.length; i += _concurrentFetches) {
      final results = await Future.wait(
        batch.map((link) => _scrapeArticleDetail(url: link['url']!))
      );
      articles.addAll(results.whereType<NewsArticle>());
    }
    
    return articles;
  }
}
```

### CSS Selectors Used

| Source | Selector Strategy |
|--------|-------------------|
| **Habertürk** | `a.gtm-tracker[href][data-newsid]`, fallback to `a[data-newsid]` |
| **NTV** | `a[href*="/turkiye/"]`, `a[href*="/dunya/"]`, etc. by category |
| **Hürriyet** | `.home-carousel .swiper-slide a[href]` with 8-digit ID pattern |
| **Sözcü** | `a[href]` with `-pXXXXXX` URL pattern |

### Content Extraction

Each scraper extracts:
- **Title**: From `og:title` meta tag or `<h1>`
- **Description**: From `description` meta tag
- **Author**: From `articleAuthor` or `author` meta tags
- **Date**: From `datePublished` / `dateModified` meta tags
- **Image**: From `og:image` meta tag
- **Content**: From article body containers (`.cms-container`, `.news-content`, etc.)
- **Keywords**: From `keywords` meta tag

### HTTP Configuration

```dart
Dio(BaseOptions(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  headers: {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...',
    'Accept': 'text/html,application/xhtml+xml,application/xml...',
    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
  },
))
```

### Scraping Configuration

```dart
class ScrapingConfig {
  final int? maxArticlesPerSource;     // Default: 15 per source
  final int requestDelayMs;            // Default: 500ms
  final int requestTimeoutSeconds;     // Default: 30s
  final bool fetchFullContent;         // Default: true
  final int maxConcurrentSources;      // Default: 3
}

// Presets
ScrapingConfig.defaultConfig  // Balanced
ScrapingConfig.quickFetch     // 5 articles, no full content
ScrapingConfig.fullFetch      // 20 articles, full content
```

---

## 🤖 AI Summarization System

### Overview

The app uses **Google Gemini 2.5 Flash** API for intelligent summarization and categorization.

### API Configuration

```dart
class GeminiLlmRepository implements LlmRepository {
  static const String _apiKey = 'YOUR_API_KEY';
  
  late final GenerativeModel _model;
  
  GeminiLlmRepository() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,      // Low for factual summaries
        maxOutputTokens: 4096,
        topP: 0.95,
      ),
    );
  }
}
```

### LLM Repository Interface

```dart
abstract class LlmRepository {
  /// Generate brief summary (1-2 sentences) for news cards
  Future<String> generateBriefSummary(String content);

  /// Generate detailed summary for article detail screen
  Future<String> generateDetailedSummary(String content);

  /// Generate combined summary from multiple articles
  Future<String> generateCombinedSummary(List<NewsArticle> articles);

  /// Process article cluster with summaries + category
  Future<ClusterSummaryResult> processCluster(ArticleCluster cluster);

  /// Batch process multiple clusters concurrently
  Future<List<ClusterSummaryResult>> batchProcessClusters(List<ArticleCluster> clusters);
}
```

### AI Processing Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Scraped Articles│────▶│ ArticleGrouper  │────▶│ Article Clusters│
│    (raw data)   │     │  (same-story)   │     │  (grouped)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                              ┌────────────────────────────────────┐
                              │        LlmRepository               │
                              │     batchProcessClusters()         │
                              │                                    │
                              │  ┌──────────────────────────────┐  │
                              │  │   Future.wait() (PARALLEL)   │  │
                              │  │   All clusters processed at  │  │
                              │  │   once via Gemini API        │  │
                              │  └──────────────────────────────┘  │
                              └────────────────────────────────────┘
                                                        │
                                                        ▼
                              ┌────────────────────────────────────┐
                              │        For each cluster:           │
                              │  • Brief summary per article       │
                              │  • Detailed summary per article    │
                              │  • Group summary (if multi-source) │
                              │  • AI-determined category          │
                              └────────────────────────────────────┘
```

### Prompt Service

The `PromptService` generates optimized Turkish prompts:

```dart
class PromptService {
  /// For grouped articles (same story, multiple sources)
  String groupedArticlesPrompt(List<NewsArticle> articles) {
    return '''Aynı haberi ${articles.length} farklı kaynaktan özetle ve kategorize et.

$articlesText

KATEGORİLER: $_categoryList

SADECE JSON dön (``` KULLANMA). KISA TUT:

{
  "category": "kategori_id",
  "groupSummary": "Birleşik özet (max 40 kelime)",
  "articles": [
    {"sourceId": "id", "briefSummary": "1 cümle", "detailedSummary": "2 cümle"}
  ]
}''';
  }

  /// For single articles
  String singleArticlePrompt(NewsArticle article) {
    return '''Haberi özetle ve kategorize et:
Başlık: ${article.title}
İçerik: $truncatedContent

KATEGORİLER: $_categoryList

SADECE JSON dön:
{"category": "id", "briefSummary": "...", "detailedSummary": "..."}''';
  }
}
```

### JSON Response Handling

The LLM repository includes robust JSON parsing:

```dart
// Clean control characters and extract JSON
String _extractAndCleanJson(String text) {
  // Remove markdown code blocks
  // Fix unescaped quotes inside strings
  // Handle truncated responses
}

// Recover partial data from broken JSON
Map<String, dynamic> _tryRecoverPartialJson(String brokenJson) {
  // Extract whatever data we can salvage
}
```

---

## 📊 News Categorization

### 13 Predefined Categories

```dart
enum NewsCategory {
  politics('politics', 'Siyaset', '🏛️'),
  economy('economy', 'Ekonomi', '💰'),
  world('world', 'Dünya', '🌍'),
  sports('sports', 'Spor', '⚽'),
  technology('technology', 'Teknoloji', '💻'),
  health('health', 'Sağlık', '🏥'),
  culture('culture', 'Kültür & Sanat', '🎭'),
  science('science', 'Bilim', '🔬'),
  entertainment('entertainment', 'Magazin', '🎬'),
  education('education', 'Eğitim', '📚'),
  environment('environment', 'Çevre', '🌱'),
  crime('crime', 'Asayiş', '🚔'),
  other('other', 'Diğer', '📰');
}
```

### Categorization Methods

1. **AI-Based (Primary)**: Gemini analyzes content and returns category ID
2. **Keyword Fallback**: If AI fails, `NewsCategory.fromString()` uses keyword matching:

```dart
static NewsCategory fromString(String? value) {
  if (_matches(value, ['siyaset', 'politics', 'meclis', 'cumhurbaşkan'])) {
    return NewsCategory.politics;
  }
  if (_matches(value, ['ekonomi', 'economy', 'borsa', 'dolar', 'euro'])) {
    return NewsCategory.economy;
  }
  // ... more patterns
}
```

---

## 🔗 Article Grouping (Same-Story Detection)

### Overview

The `ArticleGrouper` service groups articles from **different sources** that cover the **same news story**.

### Algorithm

```dart
class ArticleGrouper {
  static const double _similarityThreshold = 0.35;

  double _calculateSimilarity(NewsArticle a, NewsArticle b) {
    // Never group articles from same source
    if (a.sourceId == b.sourceId) return 0.0;

    // Multi-factor similarity scoring:
    final titleSimilarity = _calculateTitleSimilarity(a.title, b.title);     // 30%
    final entitySimilarity = _calculateEntityOverlap(a.title, b.title);      // 35%
    final keywordSimilarity = _calculateKeywordOverlap(a.title, b.title);    // 25%
    final categoryBonus = _calculateCategoryBonus(a.category, b.category);   // 10%

    return (titleSimilarity * 0.30) + 
           (entitySimilarity * 0.35) + 
           (keywordSimilarity * 0.25) + 
           (categoryBonus * 0.10);
  }
}
```

### Similarity Factors

| Factor | Weight | Method |
|--------|--------|--------|
| Title Words | 30% | Jaccard similarity of word sets |
| Named Entities | 35% | Overlap of proper nouns, names |
| Keywords | 25% | Common significant words |
| Category | 10% | Bonus if same category |

### Output Structure

```dart
class ArticleCluster {
  final List<NewsArticle> articles;
  final double similarityScore;
  
  bool get isMultiSource => articles.length > 1;
  NewsArticle get representative => articles.first;
}
```

---

## 📦 Dependencies & Technologies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 3.0.3 | State management with Notifiers |
| `dio` | 5.4.3+1 | HTTP client for web scraping |
| `html` | 0.15.6 | HTML DOM parsing |
| `google_generative_ai` | 0.4.6 | Gemini AI API client |
| `cached_network_image` | 3.4.1 | Image caching |
| `google_fonts` | 6.2.1 | Typography (Epilogue) |

### Storage Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | 2.4.2 | SQLite for history persistence |
| `flutter_secure_storage` | 9.2.4 | Secure API key storage |

---

## ⚙️ State Management (Riverpod 3.0)

### Provider Architecture

```dart
// Repository Providers (Dependency Injection)
final newsScraperRepositoryProvider = Provider<NewsScraperRepository>((ref) {
  return DefaultNewsScraperRepository();
});

final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  return GeminiLlmRepository();  // Real Gemini implementation
});

// State Notifiers
final newsFeedNotifierProvider = NotifierProvider<NewsFeedNotifier, NewsFeedState>(() {
  return NewsFeedNotifier();
});
```

### Complete Data Flow

```
User taps "Fetch News"
        │
        ▼
NewsFeedNotifier.fetchNews(enabledSources)
        │
        ├──▶ NewsScraperRepository.scrapeSources()
        │           │
        │           ▼
        │    [Parallel scraping: Habertürk, NTV, Sözcü, Hürriyet]
        │           │
        │           ▼
        │    List<NewsArticle> (raw articles)
        │
        ├──▶ ArticleGrouper.groupArticles()
        │           │
        │           ▼
        │    List<ArticleCluster> (grouped by same story)
        │
        ├──▶ LlmRepository.batchProcessClusters()
        │           │
        │           ▼
        │    [Parallel AI: summaries + categories for all clusters]
        │           │
        │           ▼
        │    List<ClusterSummaryResult>
        │
        ▼
NewsFeedState updated → UI rebuilds with GroupedNews cards
```

---

## 🎨 UI Components

### Screen Structure

| Screen | Purpose |
|--------|---------|
| `HomeScreen` | 3-tab navigation (Feed, Sources, History) |
| `NewsSourcesScreen` | Toggle news sources on/off |
| `ArticleDetailScreen` | Single article with AI summary |
| `GroupedNewsDetailScreen` | Multi-source story comparison |
| `HistoryScreen` | Past fetch sessions |

### Key Widgets

| Widget | Purpose |
|--------|---------|
| `GroupedNewsCard` | News card with source badges, AI summary |
| `NewsLoadingShimmer` | Skeleton loading animation |
| `CompareSourcesSheet` | Bottom sheet for source comparison |

---

## 🔐 API Keys & Security

### Current Setup

The Gemini API key is currently hardcoded (for development):

```dart
static const String _apiKey = 'AIzaSy...';
```

### Planned Security

- Store API keys in `flutter_secure_storage`
- Use environment variables for CI/CD
- Implement key rotation

---

## 📈 Performance Optimizations

### Parallel Processing

1. **Source Scraping**: All 4 sources scraped simultaneously with `Future.wait()`
2. **Article Fetching**: 5 articles fetched concurrently within each source
3. **AI Processing**: All clusters processed in parallel via Gemini API

### Rate Limiting

- **Scraping**: 500ms delay between batches (configurable)
- **Gemini API**: 90 RPM capacity with Gemini 2.5 Flash

### Caching

- Images cached via `cached_network_image`
- Source preferences saved to local storage

---

## ✅ Current Status

### Implemented ✅

- [x] Real web scraping (4 Turkish news sources)
- [x] Parallel source scraping
- [x] Gemini AI integration (summaries + categories)
- [x] Article grouping (same-story detection)
- [x] 13-category classification
- [x] Turkish-optimized prompts
- [x] JSON response recovery (handles partial responses)
- [x] Full UI with loading states
- [x] Source preferences persistence
- [x] History tracking (in-memory)

### Planned 📋

- [ ] SQLite persistence for history
- [ ] Secure API key storage
- [ ] Dark mode
- [ ] Pull-to-refresh
- [ ] Offline reading mode
- [ ] More news sources (international)

---

## 🚀 Getting Started

```bash
# Clone & Install
git clone https://github.com/senaogut/smart_reader.git
cd smart_reader
flutter pub get

# Run
flutter run
```

### API Key Setup

Replace the Gemini API key in `lib/features/news/data/repositories/llm_repository.dart`:

```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY';
```

---

*Documentation generated December 2025*
