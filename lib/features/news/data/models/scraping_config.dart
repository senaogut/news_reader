/// Configuration for web scraping behavior
class ScrapingConfig {
  /// Maximum number of articles to fetch per source (overrides source default)
  final int? maxArticlesPerSource;

  /// Delay between HTTP requests in milliseconds (to be respectful to servers)
  final int requestDelayMs;

  /// Timeout for HTTP requests in seconds
  final int requestTimeoutSeconds;

  /// Whether to fetch full article content (slower) or just metadata (faster)
  final bool fetchFullContent;

  /// Maximum number of sources to scrape concurrently
  final int maxConcurrentSources;

  /// Whether to use TRUE parallel mode (all articles at once, no batching)
  /// When false, uses batched concurrent mode (5 at a time with delays)
  final bool useTrueParallel;

  /// Whether to use Isolates for CPU-intensive HTML parsing
  /// This provides true multi-core parallelism for parsing
  final bool useIsolatesForParsing;

  const ScrapingConfig({
    this.maxArticlesPerSource,
    this.requestDelayMs = 500, // 500ms delay between requests
    this.requestTimeoutSeconds = 30,
    this.fetchFullContent = true,
    this.maxConcurrentSources = 3,
    this.useTrueParallel = true, // Default to TRUE parallel mode
    this.useIsolatesForParsing = true, // Default to using Isolates
  });

  /// Default configuration for normal usage
  static const ScrapingConfig defaultConfig = ScrapingConfig();

  /// Quick fetch - fewer articles, no full content
  static const ScrapingConfig quickFetch = ScrapingConfig(
    maxArticlesPerSource: 5,
    fetchFullContent: false,
    requestDelayMs: 200,
    useTrueParallel: true,
    useIsolatesForParsing: false, // Not needed for quick mode
  );

  /// Full fetch - more articles with full content
  static const ScrapingConfig fullFetch = ScrapingConfig(
    maxArticlesPerSource: 20,
    fetchFullContent: true,
    requestDelayMs: 1000, // Be more respectful when fetching more
    useTrueParallel: true,
    useIsolatesForParsing: true,
  );

  /// Legacy mode - batched concurrent (old behavior)
  static const ScrapingConfig legacyMode = ScrapingConfig(
    useTrueParallel: false,
    useIsolatesForParsing: false,
  );

  ScrapingConfig copyWith({
    int? maxArticlesPerSource,
    int? requestDelayMs,
    int? requestTimeoutSeconds,
    bool? fetchFullContent,
    int? maxConcurrentSources,
    bool? useTrueParallel,
    bool? useIsolatesForParsing,
  }) {
    return ScrapingConfig(
      maxArticlesPerSource: maxArticlesPerSource ?? this.maxArticlesPerSource,
      requestDelayMs: requestDelayMs ?? this.requestDelayMs,
      requestTimeoutSeconds: requestTimeoutSeconds ?? this.requestTimeoutSeconds,
      fetchFullContent: fetchFullContent ?? this.fetchFullContent,
      maxConcurrentSources: maxConcurrentSources ?? this.maxConcurrentSources,
      useTrueParallel: useTrueParallel ?? this.useTrueParallel,
      useIsolatesForParsing: useIsolatesForParsing ?? this.useIsolatesForParsing,
    );
  }

  /// Get the effective max articles for a source
  /// Uses config override if set, otherwise uses source default
  int getMaxArticlesFor(int sourceDefault) {
    return maxArticlesPerSource ?? sourceDefault;
  }
}
