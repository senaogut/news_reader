import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import '../constants/app_constants.dart';

/// Main app theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.primary,
        onSecondary: AppColors.white,
        surface: AppColors.containerBg,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.containerBg,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.containerBg,
      ),
      // Enhanced text theme with proper fallbacks
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headline1,
        displayMedium: AppTextStyles.headline1,
        displaySmall: AppTextStyles.headline2,
        headlineLarge: AppTextStyles.headline2,
        headlineMedium: AppTextStyles.headline3,
        headlineSmall: AppTextStyles.headline4,
        titleLarge: AppTextStyles.headline4,
        titleMedium: AppTextStyles.labelLarge,
        titleSmall: AppTextStyles.labelMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      fontFamily: GoogleFonts.epilogue().fontFamily,
      scaffoldBackgroundColor: AppColors.background,

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColors.white, size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withAlpha(204),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headline4,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.buttonLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          minimumSize: const Size(AppConstraints.minButtonWidth, AppButtonSizes.large),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          elevation: 2,
          shadowColor: AppColors.primary.withAlpha(77),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTextStyles.buttonLarge,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          minimumSize: const Size(AppConstraints.minButtonWidth, AppButtonSizes.large),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.surface,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary.withAlpha(153)),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.primaryDark.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.lg)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.containerBg, thickness: 1, space: 1),

      // Additional component themes for consistency
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.containerBg,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.containerBg.withAlpha(128),
        secondarySelectedColor: AppColors.primary.withAlpha(31),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.white),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.full)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.lg)),
        titleTextStyle: AppTextStyles.headline4,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionsPadding: const EdgeInsets.all(AppSpacing.md),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.primary,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.background,
        selectedTileColor: AppColors.containerBg,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.containerBg;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),
    );
  }
}
