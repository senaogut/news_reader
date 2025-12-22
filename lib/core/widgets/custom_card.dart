import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Custom card widget with consistent styling
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.elevation,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.lg),
        border: border,
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: AppColors.black.withAlpha(13),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppBorderRadius.lg),
        child: card,
      );
    }

    return card;
  }
}
