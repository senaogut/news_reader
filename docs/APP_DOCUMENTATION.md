# Smart Reader - Complete Application Documentation

> **Version:** 1.0.0  
> **Last Updated:** December 2025  
> **Status:** Real news scraping implemented, LLM integration pending

## 📖 Overview

**Smart Reader** is a Flutter-based news aggregator application that scrapes real-time news from Turkish news websites and provides AI-powered summarization. The app aggregates articles from multiple sources, groups similar stories together, and displays them in a modern, reading-optimized interface.

---

## 🏗️ Architecture

The project follows a **Simplified Clean Architecture** pattern optimized for Flutter with Riverpod state management.

### Directory Structure

```
lib/
├── main.dart                           # App entry point with ProviderScope
│
├── core/                               # Shared resources across all features
│   ├── core.dart                       # Barrel export file
│   ├── constants/
│   │   └── app_constants.dart          # Spacing, sizing, and layout constants
│   ├── services/
│   │   ├── prompt_service.dart         # LLM prompt templates (TODO)
│   │   └── storage_service.dart        # Local storage abstraction (TODO)
│   ├── theme/
│   │   ├── app_colors.dart             # Color palette (Warm Editorial theme)
│   │   ├── app_text_styles.dart        # Typography definitions
│   │   └── app_theme.dart              # Material theme configuration
│   └── widgets/
│       ├── custom_button.dart          # Reusable button component
│       ├── custom_card.dart            # Reusable card component
│       ├── empty_state.dart            # Generic empty state widget
│       └── loading_overlay.dart        # Loading overlay component
│
└── features/
    │
    ├── news/                           # 📰 Main news aggregation feature
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── news_source.dart        # News source definition
    │   │   │   ├── news_article.dart       # Scraped article model
    │   │   │   ├── grouped_news.dart       # Grouped articles model
    │   │   │   └── scraping_config.dart    # Scraping behavior config
    │   │   ├── repositories/
    │   │   │   ├── news_source_repository.dart   # Source management
    │   │   │   ├── news_scraper_repository.dart  # Scraping orchestration
    │   │   │   └── llm_repository.dart           # LLM integration (Mock)
    │   │   └── services/
    │   │       └── haberturk_scraper.dart        # ✅ Real scraper for Habertürk
    │   │
    │   └── presentation/
    │       ├── providers/
    │       │   ├── news_source_provider.dart     # Source state management
    │       │   └── news_feed_provider.dart       # Feed state & scraping logic
    │       ├── screens/
    │       │   ├── home_screen.dart              # Main screen with 3 tabs
    │       │   ├── news_sources_screen.dart      # Source selection
    │       │   ├── article_detail_screen.dart    # Single article view
    │       │   └── grouped_news_detail_screen.dart # Multi-source story view
    │       └── widgets/
    │           ├── grouped_news_card.dart        # News card with source badges
    │           ├── news_article_card.dart        # Individual article card
    │           ├── news_source_card.dart         # Source toggle card
    │           ├── news_loading_shimmer.dart     # Skeleton loading animation
    │           ├── empty_news_state.dart         # Empty feed state
    │           └── compare_sources_sheet.dart    # Bottom sheet for comparison
    │
    └── history/                        # 📚 Reading history feature
        ├── data/
        │   ├── models/
        │   │   └── summary_history.dart          # History entry model
        │   └── repositories/
        │       └── history_repository.dart       # History persistence (Mock)
        │
        └── presentation/
            ├── providers/
            │   └── history_provider.dart         # History state management
            └── screens/
                └── history_screen.dart           # History list view
```

---

## 📊 Data Models

### NewsSource
Represents a news website that can be scraped.

```dart
class NewsSource {
  final String id;           // Unique identifier (e.g., 'haberturk')
  final String name;         // Display name
  final String url;          // Website URL
  final String logoUrl;      // Source logo
  final String category;     // News category
  final bool isEnabled;      // User toggle state
  final int maxArticles;     // Max articles per scrape (default: 15)
}
```

### NewsArticle
A single scraped news article with full metadata.

```dart
class NewsArticle {
  final String id;
  final String sourceId;
  final String sourceName;
  final String title;
  final String url;
  final String? imageUrl;
  final String content;           // Full article body
  final String briefSummary;      // 1-2 sentence summary (AI-generated)
  final String summary;           // Detailed summary (AI-generated)
  final DateTime publishedAt;
  final DateTime? modifiedAt;
  final DateTime scrapedAt;
  final String category;
  final String? author;
  final List<String> keywords;
}
```

### GroupedNews
Similar articles from multiple sources grouped together.

```dart
class GroupedNews {
  final String id;
  final String mainTitle;
  final List<NewsArticle> articles;
  final String briefGroupedSummary;
  final String groupedSummary;
  final DateTime latestPublishedAt;
  final String category;
  final String? primaryImageUrl;
  
  // Computed properties
  List<String> get sources;       // Unique source names
  int get sourceCount;            // Number of sources
  NewsArticle get primaryArticle; // First/main article
}
```

### ScrapingConfig
Controls scraping behavior for performance tuning.

```dart
class ScrapingConfig {
  final int? maxArticlesPerSource;     // Override per-source max
  final int requestDelayMs;            // Delay between requests (default: 500ms)
  final int requestTimeoutSeconds;     // HTTP timeout (default: 30s)
  final bool fetchFullContent;         // Fetch article body or just metadata
  final int maxConcurrentSources;      // Parallel source limit (default: 3)
  
  // Presets
  static const ScrapingConfig defaultConfig;
  static const ScrapingConfig quickFetch;   // Faster, less content
  static const ScrapingConfig fullFetch;    // More articles, full content
}
```

### SummaryHistory
Saved fetch session for history feature.

```dart
class SummaryHistory {
  final String id;
  final List<String> sourceIds;
  final List<NewsArticle> articles;
  final DateTime createdAt;
  final String combinedSummary;
}
```

---

## ⚙️ State Management (Riverpod 3.0)

### Provider Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer                                 │
│  (ConsumerWidget / ConsumerStatefulWidget)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Notifier Providers                            │
│                                                                  │
│  ┌───────────────────────┐    ┌─────────────────────────────┐  │
│  │ NewsSourceNotifier    │    │ NewsFeedNotifier            │  │
│  │ (AsyncNotifier)       │    │ (Notifier)                  │  │
│  │                       │    │                             │  │
│  │ - toggleSource()      │    │ - fetchNews()               │  │
│  │ - updateMaxArticles() │    │ - groupSimilarArticles()    │  │
│  └───────────────────────┘    └─────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────┐                                      │
│  │ HistoryNotifier       │                                      │
│  │ (AsyncNotifier)       │                                      │
│  │                       │                                      │
│  │ - addHistory()        │                                      │
│  │ - deleteHistory()     │                                      │
│  │ - clearHistory()      │                                      │
│  └───────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Repository Providers                           │
│                                                                  │
│  newsSourceRepositoryProvider → DefaultNewsSourceRepository      │
│  newsScraperRepositoryProvider → DefaultNewsScraperRepository    │
│  llmRepositoryProvider → MockLlmRepository                       │
│  historyRepositoryProvider → MockHistoryRepository               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Services Layer                              │
│                                                                  │
│  ┌─────────────────────────┐                                    │
│  │ HaberturkScraper        │  ← Real implementation ✅           │
│  │ - scrapeMainPage()      │                                    │
│  │ - scrapeArticleDetail() │                                    │
│  └─────────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `newsSourceNotifierProvider` | AsyncNotifier | Manage source list & toggle states |
| `newsFeedNotifierProvider` | Notifier | Fetch news, manage feed state |
| `historyNotifierProvider` | AsyncNotifier | CRUD operations on history |
| `newsScraperRepositoryProvider` | Provider | DI for scraper repository |
| `llmRepositoryProvider` | Provider | DI for LLM repository |

---

## 🔧 How It Works

### News Fetching Flow

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────────────┐
│  User taps   │────▶│ NewsFeedNotifier │────▶│ NewsScraperRepository │
│ "Fetch News" │     │   fetchNews()    │     │    scrapeSources()   │
└──────────────┘     └─────────────────┘     └──────────────────────┘
                                                        │
                                                        ▼
                            ┌────────────────────────────────────┐
                            │  For each enabled source:          │
                            │  ┌────────────────────────────────┐│
                            │  │ HaberturkScraper               ││
                            │  │ 1. Fetch main page HTML        ││
                            │  │ 2. Parse article links         ││
                            │  │ 3. (Optional) Fetch full body  ││
                            │  │ 4. Extract metadata            ││
                            │  └────────────────────────────────┘│
                            └────────────────────────────────────┘
                                                        │
                                                        ▼
                            ┌────────────────────────────────────┐
                            │  LlmRepository                     │
                            │  generateCombinedSummary()         │
                            │  (Currently returns mock/empty)    │
                            └────────────────────────────────────┘
                                                        │
                                                        ▼
                            ┌────────────────────────────────────┐
                            │  Group similar articles            │
                            │  by title similarity               │
                            └────────────────────────────────────┘
                                                        │
                                                        ▼
                            ┌────────────────────────────────────┐
                            │  Update NewsFeedState              │
                            │  Save to HistoryRepository         │
                            │  UI rebuilds with new data         │
                            └────────────────────────────────────┘
```

### Habertürk Scraper Details

The `HaberturkScraper` is the first **real implementation** of web scraping:

1. **Main Page Fetch**: Downloads HTML from `https://www.haberturk.com`
2. **Link Extraction**: Uses CSS selectors to find article links
   - Primary: `a.gtm-tracker[href][data-newsid]`
   - Fallback: Links matching article URL patterns
3. **Article Scraping**: For each link (if `fetchFullContent: true`):
   - Fetch article page HTML
   - Extract title, content, image, author, date from meta tags
   - Parse article body from `.cms-container` or `article[property="articleBody"]`
4. **Respectful Scraping**: Configurable delays between requests

---

## 🎨 UI/UX Design

### Color Palette (Warm Editorial Theme)

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#4A3F52` | Deep plum - main actions |
| Secondary | `#8B7876` | Warm taupe - secondary elements |
| Background | `#F5F3F1` | Warm white - page background |
| Surface | `#FEFDFC` | Paper - card backgrounds |
| Text Primary | `#2A2831` | Ink - main text |
| Accent | `#B67171` | Terracotta - highlights |

### Navigation Structure

```
┌───────────────────────────────────────────────────┐
│                   AppBar                           │
│  "News Reader"                     [Refresh]       │
├───────────────────────────────────────────────────┤
│                                                    │
│  ┌─────────────────────────────────────────────┐  │
│  │           IndexedStack (3 tabs)             │  │
│  │                                             │  │
│  │  Tab 0: News Feed (GroupedNewsCards)        │  │
│  │  Tab 1: News Sources (Source toggles)       │  │
│  │  Tab 2: History (Past fetch sessions)       │  │
│  │                                             │  │
│  └─────────────────────────────────────────────┘  │
│                                                    │
│                        [FAB: Fetch News]           │
│                                                    │
├───────────────────────────────────────────────────┤
│  [Home]        [Sources]        [History]          │
│  NavigationBar                                     │
└───────────────────────────────────────────────────┘
```

### Widget Components

| Widget | Purpose |
|--------|---------|
| `GroupedNewsCard` | Main news card with image, category badge, source count |
| `NewsArticleCard` | Individual article in detail screens |
| `NewsSourceCard` | Toggle card for source selection |
| `NewsLoadingShimmer` | Skeleton loading animation |
| `EmptyNewsState` | Empty feed placeholder |
| `CompareSourcesSheet` | Bottom sheet for multi-source comparison |

---

## 📦 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 3.0.3 | State management (Notifiers, Providers) |
| `dio` | 5.4.3+1 | HTTP client for web scraping |
| `html` | 0.15.6 | HTML parsing for scraper |
| `cached_network_image` | 3.4.1 | Cached image loading with placeholders |
| `google_fonts` | 6.2.1 | Custom typography (Epilogue font) |

### Storage (Not Yet Used)

| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | 2.4.2 | Local SQLite database (for history) |
| `flutter_secure_storage` | 9.2.4 | Secure key storage (for API keys) |

---

## ✅ Implementation Status

### Completed ✅

- [x] Project architecture and folder structure
- [x] Core theme system (colors, typography, spacing)
- [x] Riverpod state management setup
- [x] News source management (toggle on/off)
- [x] **Real web scraper for Habertürk** (HTML parsing with Dio)
- [x] Scraping configuration (quick/full fetch modes)
- [x] Article grouping by title similarity
- [x] Home screen with 3-tab navigation
- [x] Article detail screens (single & grouped)
- [x] Source comparison bottom sheet
- [x] Loading shimmer animations
- [x] History tracking (in-memory)

### In Progress 🚧

- [ ] Add more news source scrapers (BBC Türkçe, NTV, etc.)

### Planned (TODO) 📋

- [ ] **LLM Integration**: Replace `MockLlmRepository` with real API
  - OpenAI GPT or Google Gemini
  - Brief summary generation
  - Detailed summary generation
  - Multi-article combined summary
- [ ] **Prompt Service**: Create prompt templates in `prompt_service.dart`
- [ ] **Database Persistence**: Replace `MockHistoryRepository` with SQLite
- [ ] **Error Handling**: Add retry logic, offline mode
- [ ] **API Key Management**: Secure storage for LLM API keys
- [ ] **Dark Mode**: Theme switching support
- [ ] **Settings Screen**: User preferences
- [ ] **Pull-to-Refresh**: Gesture-based refresh

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- macOS/Windows/Linux for development

### Installation

```bash
# Clone repository
git clone https://github.com/senaogut/smart_reader.git
cd smart_reader

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running on Different Platforms

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Chrome (Web)
flutter run -d chrome

# macOS Desktop
flutter run -d macos
```

---

## 📝 Code Conventions

### File Naming
- `snake_case.dart` for all Dart files
- Feature folders in `lowercase`
- Model files: `*_model.dart` or descriptive name
- Repository files: `*_repository.dart`
- Provider files: `*_provider.dart`

### State Updates
- Always use `copyWith` for immutable state updates
- Never mutate state directly
- Handle all `AsyncValue` cases (loading, error, data)

### Widget Structure
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Read state
    final state = ref.watch(myProvider);
    
    // 2. Handle loading/error
    if (state.isLoading) return LoadingWidget();
    
    // 3. Build UI with data
    return ...;
  }
}
```

---

## 🔗 Key Files Reference

| File | Description |
|------|-------------|
| `lib/main.dart` | App entry point |
| `lib/core/theme/app_colors.dart` | Color definitions |
| `lib/features/news/data/services/haberturk_scraper.dart` | Real scraper implementation |
| `lib/features/news/presentation/providers/news_feed_provider.dart` | Core news fetching logic |
| `lib/features/news/presentation/screens/home_screen.dart` | Main UI screen |

---

*Documentation generated from codebase analysis - December 2025*
