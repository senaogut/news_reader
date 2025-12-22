import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/news_article.dart';

/// Card widget for displaying a news article
class NewsArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;

  const NewsArticleCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.md)),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
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

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and category
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
                        _formatTime(article.publishedAt),
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    article.title,
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

                  // Summary with fallback handling
                  Text(
                    _getDisplaySummary(article.summary),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isErrorSummary(article.summary) ? AppColors.textTertiary : AppColors.textSecondary,
                      height: 1.5,
                      fontStyle: _isErrorSummary(article.summary) ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

  /// Check if summary is an error message
  bool _isErrorSummary(String summary) {
    return summary.isEmpty ||
        summary == 'Özet oluşturulamadı.' ||
        summary == 'Özet yok' ||
        summary.contains('oluşturulurken bir hata') ||
        summary.contains('kısmen oluşturuldu') ||
        summary.contains('kullanılamıyor') ||
        summary.contains('oluşturulamadı') ||
        summary.contains('beklemede');
  }

  /// Get display-friendly summary text
  String _getDisplaySummary(String summary) {
    if (summary.isEmpty) {
      return 'AI özeti oluşturuluyor...';
    } else if (summary.contains('kullanılamıyor') || summary.contains('oluşturulamadı')) {
      return 'AI özeti şu anda kullanılamıyor';
    } else if (summary.contains('beklemede')) {
      return 'Haber yüklendi • AI özeti hazırlanıyor';
    } else if (summary == 'Özet yok') {
      return 'Özet yok';
    } else if (summary.contains('oluşturulurken bir hata') || summary.contains('kısmen oluşturuldu')) {
      return summary; // Show partial summary as-is
    }
    return summary;
  }
}
