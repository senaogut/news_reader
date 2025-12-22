import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Loading shimmer widget for news articles
class NewsLoadingShimmer extends StatelessWidget {
  const NewsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.containerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.md)),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source tag
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Title lines
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Summary lines
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
