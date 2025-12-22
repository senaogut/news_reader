import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_source.dart';
import '../../data/repositories/news_source_repository.dart';

/// Provider for NewsSourceRepository
final newsSourceRepositoryProvider = Provider<NewsSourceRepository>((ref) {
  return DefaultNewsSourceRepository();
});

/// Provider for all news sources
final newsSourcesProvider = FutureProvider<List<NewsSource>>((ref) async {
  final repository = ref.watch(newsSourceRepositoryProvider);
  return repository.getAllSources();
});

/// Provider for enabled news sources
final enabledNewsSourcesProvider = FutureProvider<List<NewsSource>>((ref) async {
  final repository = ref.watch(newsSourceRepositoryProvider);
  return repository.getEnabledSources();
});

/// Notifier for managing news sources with actions
class NewsSourceNotifier extends AsyncNotifier<List<NewsSource>> {
  @override
  Future<List<NewsSource>> build() async {
    final repository = ref.watch(newsSourceRepositoryProvider);
    return repository.getAllSources();
  }

  Future<void> toggleSource(String sourceId, bool isEnabled) async {
    // Optimistically update the UI immediately
    state.whenData((sources) {
      final updatedSources = sources.map((source) {
        if (source.id == sourceId) {
          return source.copyWith(isEnabled: isEnabled);
        }
        return source;
      }).toList();
      state = AsyncValue.data(updatedSources);
    });

    // Update the repository and persist to storage
    final repository = ref.read(newsSourceRepositoryProvider);
    await repository.toggleSource(sourceId, isEnabled);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for news source notifier
final newsSourceNotifierProvider = AsyncNotifierProvider<NewsSourceNotifier, List<NewsSource>>(() {
  return NewsSourceNotifier();
});
