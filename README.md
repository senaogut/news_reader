# News Reader - News Aggregator & Summarizer

A Flutter app that aggregates news from multiple sources, scrapes their content, and provides AI-powered summaries.

## Features

- 📰 **Multi-Source News Aggregation**: Select from multiple news sources
- 🔍 **Web Scraping**: Fetches and scrapes news articles using HTML parser
- 🤖 **AI Summarization**: LLM-powered article and combined news summaries
- 📚 **Reading History**: Saves and manages your reading history
- 🎨 **Beautiful UI**: Clean, modern interface with smooth animations

## Architecture

The app follows a **simplified Clean Architecture** pattern:

```
lib/
├── core/                          # Shared resources
│   ├── constants/                 # App-wide constants
│   ├── theme/                     # Theme configuration
│   └── widgets/                   # Shared widgets
│
└── features/
    └── news/                      # News feature module
        ├── data/                  # Data layer
        │   ├── models/            # Data models
        │   │   ├── news_source.dart
        │   │   ├── news_article.dart
        │   │   └── summary_history.dart
        │   └── repositories/      # Data repositories (mock implementations)
        │       ├── news_source_repository.dart
        │       ├── news_scraper_repository.dart
        │       ├── llm_repository.dart
        │       └── history_repository.dart
        │
        └── presentation/          # Presentation layer
            ├── providers/         # Riverpod state management
            │   ├── news_source_provider.dart
            │   ├── news_feed_provider.dart
            │   └── history_provider.dart
            ├── screens/           # Screen widgets
            │   ├── home_screen.dart
            │   ├── news_sources_screen.dart
            │   ├── article_detail_screen.dart
            │   └── history_screen.dart
            └── widgets/           # Feature-specific widgets
                ├── news_article_card.dart
                ├── news_source_card.dart
                ├── news_loading_shimmer.dart
                └── empty_news_state.dart
```

## State Management

The app uses **Riverpod 3.0** for state management:

- `AsyncNotifier` for async data (news sources, history)
- `Notifier` for synchronous state (news feed)
- Provider-based dependency injection

## Current Implementation (Mock Data)

All repositories currently return **mock data with simulated delays**:

### News Sources
- 5 pre-configured news sources (TechCrunch, BBC News, The Verge, Reuters, Wired)
- Toggle sources on/off
- Categories: Technology, General, Business

### News Scraping
- Simulates fetching 3 articles per source
- Mock article content with lorem ipsum
- Realistic publish dates and metadata

### LLM Summarization
- Mock article summaries
- Combined multi-article summary
- ~1-2 second delay to simulate API calls

### History
- Saves fetch sessions with timestamp
- Lists all articles and combined summary
- Delete individual entries or clear all

## UI/UX Highlights

### Home Screen
- Bottom navigation with 3 tabs
- Floating action button to fetch news
- Combined AI summary card
- Scrollable article feed
- Loading shimmer effects

### Sources Screen
- Grid layout of news sources
- Visual indicators for enabled/disabled state
- Tap to toggle
- Source count display

### Article Detail
- Full-screen article view
- Hero image
- AI summary section
- Full article content
- Copy link/summary actions

### History Screen
- Chronological list of fetch sessions
- Expandable detail view (bottom sheet)
- Individual article access
- Delete/clear functionality

## Future Enhancements

### Phase 1: Real Data Integration
- [ ] Replace mock repositories with real implementations
- [ ] Implement HTML scraping with `html` package
- [ ] Integrate LLM API (OpenAI, Gemini, etc.)
- [ ] Add local SQL database (SQLite) for history

### Phase 2: Advanced Features
- [ ] Customizable scraping selectors per source
- [ ] Multiple summarization modes (brief, detailed, bullet points)
- [ ] Search and filter history
- [ ] Export summaries
- [ ] Dark mode
- [ ] Pull-to-refresh

### Phase 3: User Experience
- [ ] Onboarding flow
- [ ] Settings screen
- [ ] Notification for new articles
- [ ] Offline reading mode
- [ ] Share functionality

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^3.0.3  # State management
  dio: ^5.4.3+1             # HTTP client (for scraping)
  html: ^0.15.6             # HTML parsing
  google_fonts: ^6.2.1      # Typography
```

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on device/simulator
flutter run
```

## Design Principles

1. **Separation of Concerns**: Clear separation between data and presentation layers
2. **Single Responsibility**: Each class has one clear purpose
3. **Dependency Injection**: Riverpod providers manage dependencies
4. **Immutability**: Models use `copyWith` pattern
5. **Type Safety**: Strong typing throughout
6. **Testability**: Mock repositories enable easy testing

## Color Scheme

- **Primary**: Deep Blue (#2563EB) - Intelligence and trust
- **Secondary**: Purple (#7C3AED) - AI/tech feel
- **Background**: Light Gray (#F8FAFC) - Clean, professional
- **Text**: Slate tones for hierarchy

## Notes

- All async operations use proper loading/error states
- UI provides feedback for all user actions
- Smooth animations and transitions throughout
- Responsive to different screen sizes
- Follows Material Design 3 guidelines
