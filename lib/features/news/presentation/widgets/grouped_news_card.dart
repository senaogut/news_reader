import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/grouped_news.dart';

/// Enhanced card widget for displaying grouped news with multiple sources
class GroupedNewsCard extends StatelessWidget {
  final GroupedNews groupedNews;
  final VoidCallback? onTap;
  final VoidCallback? onCompareTap;

  const GroupedNewsCard({super.key, required this.groupedNews, this.onTap, this.onCompareTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: AppColors.primary.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.lg)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay badge
            if (groupedNews.primaryImageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.lg)),
                    child: CachedNetworkImage(
                      imageUrl: groupedNews.primaryImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppColors.containerBg,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppColors.containerBg,
                        child: const Icon(Icons.image_not_supported, size: 64, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.black.withAlpha(179),
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      ),
                      child: Text(
                        groupedNews.categoryDisplay,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Multi-source indicator
                  if (groupedNews.sourceCount > 1)
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(230),
                          borderRadius: BorderRadius.circular(AppBorderRadius.full),
                          boxShadow: [
                            BoxShadow(color: AppColors.secondary.withAlpha(77), blurRadius: 8, spreadRadius: 1),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.library_books, size: 14, color: AppColors.white),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${groupedNews.sourceCount}',
                              style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sources chips
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children:
                        groupedNews.sources.take(3).map((source) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                              border: Border.all(color: AppColors.primary.withAlpha(77), width: 1),
                            ),
                            child: Text(
                              source,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList()..addAll(
                          groupedNews.sources.length > 3
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.textTertiary.withAlpha(26),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                                    ),
                                    child: Text(
                                      '+${groupedNews.sources.length - 3}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    groupedNews.mainTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Summary in expandable container
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: AppColors.secondary.withAlpha(204)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'AI Summary',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary.withAlpha(204),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          groupedNews.briefGroupedSummary,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Footer with time and action
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatTime(groupedNews.latestPublishedAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      const Spacer(),
                      if (groupedNews.sourceCount > 1)
                        TextButton.icon(
                          onPressed: onCompareTap,
                          icon: const Icon(Icons.compare_arrows, size: 14),
                          label: const Text('Compare', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
