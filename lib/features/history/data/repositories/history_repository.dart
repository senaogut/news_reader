import '../models/summary_history.dart';

/// Repository for managing summary history
abstract class HistoryRepository {
  /// Get all history entries
  Future<List<SummaryHistory>> getHistory();

  /// Add a new history entry
  Future<void> addHistory(SummaryHistory history);

  /// Delete a history entry
  Future<void> deleteHistory(String id);

  /// Clear all history
  Future<void> clearHistory();
}

/// Mock implementation of HistoryRepository
class MockHistoryRepository implements HistoryRepository {
  final List<SummaryHistory> _mockHistory = [];

  @override
  Future<List<SummaryHistory>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Return newest first
    return List.from(_mockHistory)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> addHistory(SummaryHistory history) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockHistory.add(history);
  }

  @override
  Future<void> deleteHistory(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockHistory.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> clearHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockHistory.clear();
  }
}
