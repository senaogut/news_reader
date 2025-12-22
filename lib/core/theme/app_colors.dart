import 'package:flutter/material.dart';

/// App color palette for News Reader - Modern Editorial theme
/// Sophisticated, muted tones for comfortable long-form reading
class AppColors {
  AppColors._();

  // Primary colors - Deep charcoal base
  static const Color primary = Color(0xFF4A3F52); // Deep plum
  static const Color primaryDark = Color(0xFF37353E); // Charcoal
  static const Color primaryLight = Color(0xFF715A5A); // Dusty rose

  // Secondary colors - Warm accents
  static const Color secondary = Color(0xFF8B7876); // Warm taupe
  static const Color secondaryDark = Color(0xFF715A5A); // Dusty rose
  static const Color secondaryLight = Color(0xFF9BA8A6); // Sage

  // Background colors - Warm, comfortable neutrals
  static const Color background = Color(0xFFF5F3F1); // Warm white
  static const Color surface = Color(0xFFFEFDFB); // Paper
  static const Color surfaceVariant = Color(0xFFE8E6E4); // Soft gray
  static const Color containerBg = Color(0xFFD3DAD9); // Cool mist

  // Text colors - Rich, readable tones
  static const Color textPrimary = Color(0xFF2A2831); // Ink
  static const Color textSecondary = Color(0xFF44444E); // Slate
  static const Color textTertiary = Color(0xFF8B7876); // Warm taupe

  // Accent colors for actions and highlights
  static const Color accentPrimary = Color(0xFFB67171); // Terracotta
  static const Color accentSecondary = Color(0xFF9BA8A6); // Sage
  static const Color accentTertiary = Color(0xFF715A5A); // Dusty rose

  // Additional colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Border colors - Subtle and refined
  static const Color border = Color(0xFFD3DAD9); // Cool mist
  static const Color borderLight = Color(0xFFE8E6E4); // Soft gray

  // Status colors - Muted to fit the palette
  static const Color success = Color(0xFF6B8E7F); // Muted green
  static const Color error = Color(0xFFB67171); // Terracotta
  static const Color warning = Color(0xFFC9A05F); // Muted gold
  static const Color info = Color(0xFF8B9AA8); // Muted blue
}
