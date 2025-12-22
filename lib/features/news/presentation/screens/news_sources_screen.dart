import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/news_source_provider.dart';
import '../widgets/news_source_card.dart';

/// Screen for managing news sources
class NewsSourcesScreen extends ConsumerWidget {
  const NewsSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(newsSourceNotifierProvider);

    return Scaffold(
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return const Center(child: Text('No news sources available'));
          }

          final enabledSources = sources.where((s) => s.isEnabled).toList();

          return CustomScrollView(
            slivers: [
              // Header with info
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select News Sources',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${enabledSources.length} of ${sources.length} sources selected',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Tap on a source to enable or disable it',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),

              // Sources grid
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final source = sources[index];
                    return NewsSourceCard(
                      source: source,
                      onToggle: () {
                        ref.read(newsSourceNotifierProvider.notifier).toggleSource(source.id, !source.isEnabled);
                      },
                    );
                  }, childCount: sources.length),
                ),
              ),
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
                'Error loading sources:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  ref.read(newsSourceNotifierProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
