import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/news_filter_provider.dart';

/// Filter bar for news feed with category chips and grouped toggle
class NewsFilterBar extends ConsumerWidget {
  const NewsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(newsFilterProvider);
    final availableCategories = ref.watch(availableCategoriesProvider);
    final filterStats = ref.watch(filterStatsProvider);

    // Don't show if no news
    if (filterStats.totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter stats and clear button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                filterState.hasActiveFilters
                    ? '${filterStats.filteredCount} of ${filterStats.totalCount} news'
                    : '${filterStats.totalCount} news',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              if (filterStats.groupedCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${filterStats.groupedCount} grouped',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              if (filterState.hasActiveFilters)
                SizedBox(
                  height: 32,
                  child: TextButton.icon(
                    onPressed: () => ref.read(newsFilterProvider.notifier).clearFilters(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
              else
                SizedBox(height: 32),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Filter chips row
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              // Grouped only toggle chip
              _FilterChip(
                label: 'Multi-source only',
                icon: Icons.compare_arrows,
                isSelected: filterState.showGroupedOnly,
                onTap: () => ref.read(newsFilterProvider.notifier).toggleGroupedOnly(),
                selectedColor: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),

              // Divider
              Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(vertical: 7), color: AppColors.border),
              const SizedBox(width: AppSpacing.sm),

              // Category chips
              ...availableCategories.map((category) {
                final isSelected = filterState.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterChip(
                    label: category.displayWithEmoji,
                    isSelected: isSelected,
                    onTap: () {
                      final notifier = ref.read(newsFilterProvider.notifier);
                      if (isSelected) {
                        notifier.setCategory(null); // Deselect
                      } else {
                        notifier.setCategory(category);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Individual filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;

    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppBorderRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? color : AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
