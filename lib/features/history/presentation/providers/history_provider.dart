import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/summary_history.dart';
import '../../data/repositories/history_repository.dart';

/// Provider for HistoryRepository
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return MockHistoryRepository();
});

/// Notifier for managing history
class HistoryNotifier extends AsyncNotifier<List<SummaryHistory>> {
  @override
  Future<List<SummaryHistory>> build() async {
    final repository = ref.watch(historyRepositoryProvider);
    return repository.getHistory();
  }

  Future<void> addHistory(SummaryHistory history) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.addHistory(history);
    ref.invalidateSelf();
  }

  Future<void> deleteHistory(String id) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.deleteHistory(id);
    ref.invalidateSelf();
  }

  Future<void> clearHistory() async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.clearHistory();
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for history notifier
final historyNotifierProvider = AsyncNotifierProvider<HistoryNotifier, List<SummaryHistory>>(() {
  return HistoryNotifier();
});
