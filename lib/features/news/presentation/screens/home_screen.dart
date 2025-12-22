import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../history/data/models/summary_history.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../providers/news_source_provider.dart';
import '../providers/news_feed_provider.dart';
import '../providers/news_filter_provider.dart';
import '../widgets/grouped_news_card.dart';
import '../widgets/compare_sources_sheet.dart';
import '../widgets/news_loading_shimmer.dart';
import '../widgets/empty_news_state.dart';
import '../widgets/news_filter_bar.dart';
import 'news_sources_screen.dart';
import 'article_detail_screen.dart';
import 'grouped_news_detail_screen.dart';

/// Main home screen of the app
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasAutoFetched = false;

  @override
  void initState() {
    super.initState();
    // Trigger auto-fetch after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFetchNews();
    });
  }

  Future<void> _autoFetchNews() async {
    dev.log('_autoFetchNews called, hasAutoFetched: $_hasAutoFetched', name: 'HomeScreen');
    if (_hasAutoFetched) return;
    _hasAutoFetched = true;

    dev.log('Reading news sources...', name: 'HomeScreen');
    final sources = await ref.read(newsSourceNotifierProvider.future);
    dev.log('Got ${sources.length} sources total', name: 'HomeScreen');
    final enabledSources = sources.where((s) => s.isEnabled).toList();
    dev.log('${enabledSources.length} sources are enabled', name: 'HomeScreen');

    for (final source in enabledSources) {
      dev.log('Enabled: ${source.name} (${source.id})', name: 'HomeScreen');
    }

    if (enabledSources.isNotEmpty) {
      dev.log('Calling fetchNews...', name: 'HomeScreen');
      await ref.read(newsFeedNotifierProvider.notifier).fetchNews(enabledSources);

      final state = ref.read(newsFeedNotifierProvider);
      if (state.articles.isNotEmpty && mounted) {
        // Save to history
        final history = SummaryHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sourceIds: enabledSources.map((s) => s.id).toList(),
          articles: state.articles,
          createdAt: DateTime.now(),
          combinedSummary: state.combinedSummary ?? '',
        );
        await ref.read(historyNotifierProvider.notifier).addHistory(history);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Reader'),
        actions: [if (_selectedIndex == 0) IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshNews)],
      ),
      body: IndexedStack(index: _selectedIndex, children: [const _NewsFeedTab(), NewsSourcesScreen(), HistoryScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.source_outlined), selectedIcon: Icon(Icons.source), label: 'Sources'),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _fetchNews,
              icon: const Icon(Icons.download),
              label: const Text('Fetch News'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            )
          : null,
    );
  }

  Future<void> _refreshNews() async {
    final sources = await ref.read(newsSourceNotifierProvider.future);
    final enabledSources = sources.where((s) => s.isEnabled).toList();

    if (enabledSources.isNotEmpty) {
      await ref.read(newsFeedNotifierProvider.notifier).fetchNews(enabledSources);
    }
  }

  Future<void> _fetchNews() async {
    final sources = await ref.read(newsSourceNotifierProvider.future);
    final enabledSources = sources.where((s) => s.isEnabled).toList();

    if (enabledSources.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one news source'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }

    final notifier = ref.read(newsFeedNotifierProvider.notifier);
    await notifier.fetchNews(enabledSources);

    final state = ref.read(newsFeedNotifierProvider);
    if (state.articles.isNotEmpty && mounted) {
      // Save to history
      final history = SummaryHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceIds: enabledSources.map((s) => s.id).toList(),
        articles: state.articles,
        createdAt: DateTime.now(),
        combinedSummary: state.combinedSummary ?? '',
      );
      await ref.read(historyNotifierProvider.notifier).addHistory(history);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${state.articles.length} articles'), backgroundColor: AppColors.success),
        );
      });
    }
  }
}

/// News feed tab widget
class _NewsFeedTab extends ConsumerWidget {
  const _NewsFeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(newsFeedNotifierProvider);
    final filteredNews = ref.watch(filteredGroupedNewsProvider);
    final filterState = ref.watch(newsFilterProvider);

    if (feedState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 3,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: NewsLoadingShimmer(),
          );
        },
      );
    }

    if (feedState.error != null) {
      return EmptyNewsState(message: 'Error: ${feedState.error}', icon: Icons.error_outline);
    }

    if (feedState.groupedNews.isEmpty) {
      return const EmptyNewsState(
        message: 'No news yet!\n\nSelect your favorite news sources and tap "Fetch News" to get started.',
        icon: Icons.article_outlined,
      );
    }

    return CustomScrollView(
      slivers: [
        // Filter bar
        const SliverToBoxAdapter(child: NewsFilterBar()),

        // Combined summary section (only show when no filters active)
        if (feedState.combinedSummary != null && !filterState.hasActiveFilters) ...[
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.primary.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'AI Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    feedState.combinedSummary!,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Empty state when filters result in no news
        if (filteredNews.isEmpty && filterState.hasActiveFilters)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list_off, size: 64, color: AppColors.textTertiary.withAlpha(128)),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'No news match your filters',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => ref.read(newsFilterProvider.notifier).clearFilters(),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Grouped news list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final groupedNews = filteredNews[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: GroupedNewsCard(
                    groupedNews: groupedNews,
                    onTap: () {
                      // If single article, go directly to detail
                      if (groupedNews.articles.length == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(article: groupedNews.articles.first),
                          ),
                        );
                      } else {
                        // Multiple articles, go to grouped news detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GroupedNewsDetailScreen(groupedNews: groupedNews)),
                        );
                      }
                    },
                    onCompareTap: groupedNews.articles.length > 1
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CompareSourcesSheet(groupedNews: groupedNews),
                            );
                          }
                        : null,
                  ),
                );
              }, childCount: filteredNews.length),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ],
    );
  }
}
