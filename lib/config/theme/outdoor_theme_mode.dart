import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Guild Modernist High-Contrast Outdoor Sunlight Theme.
/// Designed for Ustads and workers operating outdoors under bright Pakistan sunlight
/// where standard subtle dark/light contrast ratios become illegible.
class OutdoorThemeColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  static const Color subText = Color(0xFF1A1D2B);
  static const Color border = Color(0xFF0A0E1A);
  static const Color primary = Color(0xFF002B88);
  static const Color primaryContainer = Color(0xFFE3EDFF);
  static const Color accentAmber = Color(0xFF9A4200);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF006C3E);
  static const Color cardBg = Color(0xFFF2F5FF);
}

/// Riverpod 3.x Notifier for toggling Outdoor High-Contrast Mode
class OutdoorModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    HapticFeedback.lightImpact();
    state = !state;
  }

  void setOutdoorMode(bool value) {
    state = value;
  }
}

final isOutdoorModeProvider =
    NotifierProvider<OutdoorModeNotifier, bool>(OutdoorModeNotifier.new);

class OutdoorThemeMode {
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: OutdoorThemeColors.background,
      colorScheme: const ColorScheme.light(
        primary: OutdoorThemeColors.primary,
        onPrimary: Colors.white,
        primaryContainer: OutdoorThemeColors.primaryContainer,
        onPrimaryContainer: OutdoorThemeColors.text,
        surface: OutdoorThemeColors.background,
        onSurface: OutdoorThemeColors.text,
        error: OutdoorThemeColors.error,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: OutdoorThemeColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(
            color: OutdoorThemeColors.border,
            width: 2.0,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: OutdoorThemeColors.background,
        foregroundColor: OutdoorThemeColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading2.copyWith(
          color: OutdoorThemeColors.text,
          fontWeight: FontWeight.w900,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headlineLg.copyWith(
          color: OutdoorThemeColors.text,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: AppTextStyles.heading2.copyWith(
          color: OutdoorThemeColors.text,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: AppTextStyles.heading3.copyWith(
          color: OutdoorThemeColors.text,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: AppTextStyles.bodyStrong.copyWith(
          color: OutdoorThemeColors.text,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: AppTextStyles.bodyPrimary.copyWith(
          color: OutdoorThemeColors.subText,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OutdoorThemeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.xl,
            vertical: AppDimensions.lg,
          ),
          textStyle: AppTextStyles.bodyStrong.copyWith(
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            side: const BorderSide(
              color: OutdoorThemeColors.border,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
