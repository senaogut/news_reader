import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_category.dart';
import '../../data/models/grouped_news.dart';
import 'news_feed_provider.dart';

/// State for news filtering (local only, no backend calls)
class NewsFilterState {
  final NewsCategory? selectedCategory; // null = all categories
  final bool showGroupedOnly; // true = only show multi-source news

  const NewsFilterState({this.selectedCategory, this.showGroupedOnly = false});

  NewsFilterState copyWith({NewsCategory? selectedCategory, bool? showGroupedOnly, bool clearCategory = false}) {
    return NewsFilterState(
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      showGroupedOnly: showGroupedOnly ?? this.showGroupedOnly,
    );
  }

  /// Check if any filter is active
  bool get hasActiveFilters => selectedCategory != null || showGroupedOnly;
}

/// Notifier for managing news filters
class NewsFilterNotifier extends Notifier<NewsFilterState> {
  @override
  NewsFilterState build() {
    return const NewsFilterState();
  }

  /// Set category filter
  void setCategory(NewsCategory? category) {
    state = state.copyWith(selectedCategory: category, clearCategory: category == null);
  }

  /// Toggle grouped only filter
  void toggleGroupedOnly() {
    state = state.copyWith(showGroupedOnly: !state.showGroupedOnly);
  }

  /// Set grouped only filter
  void setGroupedOnly(bool value) {
    state = state.copyWith(showGroupedOnly: value);
  }

  /// Clear all filters
  void clearFilters() {
    state = const NewsFilterState();
  }
}

/// Provider for news filter notifier
final newsFilterProvider = NotifierProvider<NewsFilterNotifier, NewsFilterState>(() {
  return NewsFilterNotifier();
});

/// Provider that returns filtered grouped news based on current filters
final filteredGroupedNewsProvider = Provider<List<GroupedNews>>((ref) {
  final feedState = ref.watch(newsFeedNotifierProvider);
  final filterState = ref.watch(newsFilterProvider);

  List<GroupedNews> filtered = feedState.groupedNews;

  // Apply category filter
  if (filterState.selectedCategory != null) {
    filtered = filtered.where((news) => news.category == filterState.selectedCategory).toList();
  }

  // Apply grouped only filter
  if (filterState.showGroupedOnly) {
    filtered = filtered.where((news) => news.articles.length > 1).toList();
  }

  return filtered;
});

/// Provider that returns available categories from current news (for filter chips)
final availableCategoriesProvider = Provider<List<NewsCategory>>((ref) {
  final feedState = ref.watch(newsFeedNotifierProvider);

  // Get unique categories from current news
  final categories = feedState.groupedNews.map((news) => news.category).toSet().toList();

  // Sort by display name
  categories.sort((a, b) => a.displayName.compareTo(b.displayName));

  return categories;
});

/// Provider for filter stats (for showing counts)
final filterStatsProvider = Provider<FilterStats>((ref) {
  final feedState = ref.watch(newsFeedNotifierProvider);
  final filtered = ref.watch(filteredGroupedNewsProvider);

  return FilterStats(
    totalCount: feedState.groupedNews.length,
    filteredCount: filtered.length,
    groupedCount: feedState.groupedNews.where((n) => n.articles.length > 1).length,
  );
});

/// Stats about current filter state
class FilterStats {
  final int totalCount;
  final int filteredCount;
  final int groupedCount;

  const FilterStats({required this.totalCount, required this.filteredCount, required this.groupedCount});
}
