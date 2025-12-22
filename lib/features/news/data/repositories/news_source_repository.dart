import '../models/news_source.dart';
import '../../../../core/services/storage_service.dart';

/// Repository for managing news sources
abstract class NewsSourceRepository {
  /// Get all available news sources
  Future<List<NewsSource>> getAllSources();

  /// Get enabled news sources
  Future<List<NewsSource>> getEnabledSources();

  /// Toggle a news source on/off
  Future<void> toggleSource(String sourceId, bool isEnabled);

  /// Get source by ID
  NewsSource? getSourceById(String sourceId);
}

/// Implementation of NewsSourceRepository with real news sources
class DefaultNewsSourceRepository implements NewsSourceRepository {
  bool _isInitialized = false;

  /// All available news sources
  final List<NewsSource> _sources = [
    const NewsSource(
      id: 'haberturk',
      name: 'Habertürk',
      url: 'https://www.haberturk.com',
      logoUrl: 'https://im.haberturk.com/assets/images/haberturk-logo.svg',
      category: 'Genel',
      isEnabled: true,
      maxArticles: 15,
    ),
    const NewsSource(
      id: 'ntv',
      name: 'NTV',
      url: 'https://www.ntv.com.tr',
      logoUrl: 'https://images.ntv.com.tr/images/favicon.svg',
      category: 'Genel',
      isEnabled: true,
      maxArticles: 15,
    ),
    const NewsSource(
      id: 'sozcu',
      name: 'Sözcü',
      url: 'https://www.sozcu.com.tr',
      logoUrl: 'https://www.sozcu.com.tr/wp-content/themes/sozcu/assets/images/logo.svg',
      category: 'Genel',
      isEnabled: true,
      maxArticles: 15,
    ),
    const NewsSource(
      id: 'hurriyet',
      name: 'Hürriyet',
      url: 'https://www.hurriyet.com.tr',
      logoUrl: 'https://www.hurriyet.com.tr/images/logo.svg',
      category: 'Genel',
      isEnabled: true,
      maxArticles: 15,
    ),
    // Add more sources here as we implement their scrapers
  ];

  @override
  Future<List<NewsSource>> getAllSources() async {
    // Load saved state from storage on first call
    if (!_isInitialized) {
      await _loadSavedState();
      _isInitialized = true;
    }
    return List.unmodifiable(_sources);
  }

  /// Load saved enabled source IDs from storage
  Future<void> _loadSavedState() async {
    final savedIds = await StorageService.loadEnabledSourceIds();
    if (savedIds.isNotEmpty) {
      for (int i = 0; i < _sources.length; i++) {
        _sources[i] = _sources[i].copyWith(isEnabled: savedIds.contains(_sources[i].id));
      }
    }
  }

  /// Save enabled source IDs to storage
  Future<void> _saveState() async {
    final enabledIds = _sources.where((s) => s.isEnabled).map((s) => s.id).toList();
    await StorageService.saveEnabledSourceIds(enabledIds);
  }

  @override
  Future<List<NewsSource>> getEnabledSources() async {
    return _sources.where((source) => source.isEnabled).toList();
  }

  @override
  Future<void> toggleSource(String sourceId, bool isEnabled) async {
    final index = _sources.indexWhere((s) => s.id == sourceId);
    if (index != -1) {
      _sources[index] = _sources[index].copyWith(isEnabled: isEnabled);
      // Persist to storage
      await _saveState();
    }
  }

  @override
  NewsSource? getSourceById(String sourceId) {
    try {
      return _sources.firstWhere((s) => s.id == sourceId);
    } catch (_) {
      return null;
    }
  }
}

/// Alias for backward compatibility
typedef MockNewsSourceRepository = DefaultNewsSourceRepository;
