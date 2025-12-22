import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App text styles based on the design system
class AppTextStyles {
  AppTextStyles._();

  // Base text style using Epilogue font
  static TextStyle get _baseStyle => GoogleFonts.epilogue();

  // Headlines - Stronger weights for better hierarchy
  static TextStyle get headline1 => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get headline2 => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle get headline3 => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle get headline4 => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.1,
  );

  // Body text
  static TextStyle get bodyLarge =>
      _baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);

  static TextStyle get bodyMedium =>
      _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.4);

  static TextStyle get bodySmall =>
      _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.3);

  // Labels
  static TextStyle get labelLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.015,
  );

  static TextStyle get labelMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.015,
  );

  static TextStyle get labelSmall =>
      _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: 0.01);

  // Button text
  static TextStyle get buttonLarge =>
      _baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.015);

  static TextStyle get buttonMedium =>
      _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.015);

  // Special styles
  static TextStyle get sessionCode =>
      _baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 4.0, color: AppColors.textPrimary);

  static TextStyle get caption =>
      _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.3);
}
