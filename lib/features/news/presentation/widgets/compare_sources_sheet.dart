import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/grouped_news.dart';
import '../../data/models/news_article.dart';
import '../screens/article_detail_screen.dart';

/// Bottom sheet for comparing multiple articles on the same topic
class CompareSourcesSheet extends StatelessWidget {
  final GroupedNews groupedNews;

  const CompareSourcesSheet({super.key, required this.groupedNews});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xl)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.containerBg, borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.compare_arrows, color: AppColors.primary, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'Compare Sources',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${groupedNews.sourceCount} sources covering this story',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Articles list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: groupedNews.articles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final article = groupedNews.articles[index];
                    return _SourceComparisonCard(
                      article: article,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceComparisonCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _SourceComparisonCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                    ),
                    child: Text(
                      article.sourceName,
                      style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  article.summary,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Metadata
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatTime(article.publishedAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
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
