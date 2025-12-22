import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/news_article.dart';

/// Screen showing detailed view of an article
class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.containerBg,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.containerBg,
                        child: const Icon(Icons.image_not_supported, size: 64, color: AppColors.textTertiary),
                      ),
                    )
                  : Container(
                      color: AppColors.containerBg,
                      child: const Icon(Icons.article, size: 64, color: AppColors.textTertiary),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and metadata
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                        ),
                        child: Text(
                          article.sourceName,
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(article.category, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      const Spacer(),
                      Text(
                        _formatDate(article.publishedAt),
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // AI Summary section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.secondary.withAlpha(77)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'AI Summary',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          article.summary,
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Full content section
                  const Text(
                    'Full Article',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    article.content,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.7),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: article.url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)),
                            );
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Copy Link'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: article.summary));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Summary copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Summary'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
