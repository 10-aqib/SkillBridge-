import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Guild Modernist Stitch Theme Data — "Modern Trade Guild"
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightScheme,
      scaffoldBackgroundColor: AppColors.backgroundGray,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading2.copyWith(
          color: AppColors.onSurface,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero,
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineLgMobile,
        titleLarge: AppTextStyles.heading2,
        titleMedium: AppTextStyles.heading3,
        titleSmall: AppTextStyles.bodyStrong,
        bodyLarge: AppTextStyles.bodyStrong,
        bodyMedium: AppTextStyles.bodyPrimary,
        bodySmall: AppTextStyles.labelCaption,
        labelLarge: AppTextStyles.bodyStrong,
        labelMedium: AppTextStyles.labelCaption,
        labelSmall: AppTextStyles.labelCaption,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 1, // Will be styled with Level 2 shadow
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg), // 16px
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 40),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd), // 12px
          ),
          textStyle: AppTextStyles.bodyStrong,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 40),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd), // 12px
          ),
          textStyle: AppTextStyles.bodyStrong,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd), // 12px
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        labelStyle: AppTextStyles.bodyPrimary.copyWith(color: AppColors.onSurfaceVariant),
        hintStyle: AppTextStyles.bodyPrimary.copyWith(color: AppColors.outline),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.darkScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading2.copyWith(
          color: AppColors.darkText,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero.copyWith(color: AppColors.darkText),
        headlineLarge: AppTextStyles.headlineLg.copyWith(color: AppColors.darkText),
        headlineMedium: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.darkText),
        titleLarge: AppTextStyles.heading2.copyWith(color: AppColors.darkText),
        titleMedium: AppTextStyles.heading3.copyWith(color: AppColors.darkText),
        titleSmall: AppTextStyles.bodyStrong.copyWith(color: AppColors.darkText),
        bodyLarge: AppTextStyles.bodyStrong.copyWith(color: AppColors.darkText),
        bodyMedium: AppTextStyles.bodyPrimary.copyWith(color: AppColors.darkText),
        bodySmall: AppTextStyles.labelCaption.copyWith(color: AppColors.darkText),
        labelLarge: AppTextStyles.bodyStrong.copyWith(color: AppColors.darkText),
        labelMedium: AppTextStyles.labelCaption.copyWith(color: AppColors.darkText),
        labelSmall: AppTextStyles.labelCaption.copyWith(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(
            color: AppColors.darkLine,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 40),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.bodyStrong,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inversePrimary,
          minimumSize: const Size(0, 40),
          side: const BorderSide(color: AppColors.inversePrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.bodyStrong,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkLine, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkLine, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.inversePrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkRed, width: 2),
        ),
        labelStyle: AppTextStyles.bodyPrimary.copyWith(color: AppColors.darkMuted),
        hintStyle: AppTextStyles.bodyPrimary.copyWith(color: AppColors.darkMuted),
      ),
    );
  }
}
