import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../news/presentation/widgets/empty_news_state.dart';
import '../../../news/presentation/screens/article_detail_screen.dart';
import '../providers/history_provider.dart';

/// Screen showing history of summarized news
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);

    return Scaffold(
      body: historyAsync.when(
        data: (historyList) {
          if (historyList.isEmpty) {
            return const EmptyNewsState(
              message: 'No history yet!\n\nYour summarized news will appear here after you fetch news.',
              icon: Icons.history_outlined,
            );
          }

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'History',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${historyList.length} saved summaries',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (historyList.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear History'),
                                content: const Text('Are you sure you want to clear all history?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref.read(historyNotifierProvider.notifier).clearHistory();
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        ),
                    ],
                  ),
                ),
              ),

              // History list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final history = historyList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                      child: InkWell(
                        onTap: () {
                          _showHistoryDetail(context, history);
                        },
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Metadata
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textTertiary),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    _formatDate(history.createdAt),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${history.articles.length} articles',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: AppColors.error,
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete History'),
                                          content: const Text('Are you sure you want to delete this history entry?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        await ref.read(historyNotifierProvider.notifier).deleteHistory(history.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Summary preview
                              Text(
                                history.combinedSummary,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // View more button
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    _showHistoryDetail(context, history);
                                  },
                                  child: const Text('View Details'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: historyList.length),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading history:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDetail(BuildContext context, history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.containerBg, borderRadius: BorderRadius.circular(2)),
                ),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Header
                      Text(
                        _formatDate(history.createdAt),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${history.articles.length} articles from ${history.sourceIds.length} sources',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Combined summary
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
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
                                  'Combined Summary',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              history.combinedSummary,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Articles list
                      const Text(
                        'Articles',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ...history.articles.map((article) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(article.sourceName),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
