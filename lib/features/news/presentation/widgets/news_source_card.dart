import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/news_source.dart';

/// Card widget for selecting/deselecting a news source
class NewsSourceCard extends StatelessWidget {
  final NewsSource source;
  final VoidCallback onToggle;

  const NewsSourceCard({super.key, required this.source, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: source.isEnabled ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        side: BorderSide(
          color: source.isEnabled ? AppColors.primary : AppColors.border,
          width: source.isEnabled ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  color: AppColors.containerBg,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  child: CachedNetworkImage(
                    imageUrl: source.logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.newspaper, size: 32, color: AppColors.textTertiary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Name
              Text(
                source.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: source.isEnabled ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Category
              Text(source.category, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: AppSpacing.sm),

              // Status indicator
              if (source.isEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: const Text('Tap to enable', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
