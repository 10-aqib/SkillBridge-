import 'package:flutter/material.dart';

/// Guild Modernist Stitch Design System Tokens — "Modern Trade Guild"
class AppColors {
  // Guild Modernist Core Palette (Light)
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceDim = Color(0xFFDEDFE1);
  static const Color surfaceBright = Color(0xFFFAFAFA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F6);
  static const Color surfaceContainer = Color(0xFFE5E7EB);
  static const Color surfaceContainerHigh = Color(0xFFD1D5DB);
  static const Color surfaceContainerHighest = Color(0xFF9CA3AF);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF4B5563);
  static const Color inverseSurface = Color(0xFF1F2937);
  static const Color inverseOnSurface = Color(0xFFF9FAFB);
  static const Color outline = Color(0xFF6B7280);
  static const Color outlineVariant = Color(0xFFD1D5DB);
  static const Color borderGray = outlineVariant;
  static const Color surfaceTint = Color(0xFF1353D8);

  static const Color primary = Color(0xFF003FB1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1A56DB);
  static const Color onPrimaryContainer = Color(0xFFD4DCFF);
  static const Color inversePrimary = Color(0xFFB5C4FF);

  static const Color secondary = Color(0xFF4059AA);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF8FA7FE);
  static const Color onSecondaryContainer = Color(0xFF1D3989);

  // Skill Green (Success / Verified / Available)
  static const Color tertiary = Color(0xFF005438);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF006F4B);
  static const Color onTertiaryContainer = Color(0xFF7AF3BB);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  static const Color background = Color(0xFFFAFAFA);
  static const Color onBackground = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Brand / Utility Extras
  static const Color amberWarm = Color(0xFFF59E0B);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color blueTint = Color(0xFFEFF6FF);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Backward compatibility aliases mapped to Guild Modernist tokens
  static const Color navy = primary;
  static const Color navy2 = primaryContainer;
  static const Color amber = amberWarm;
  static const Color amber2 = Color(0xFFD97706);
  static const Color cream = surface;
  static const Color white = surfaceWhite;
  static const Color ink = onSurface;
  static const Color muted = onSurfaceVariant;
  static const Color line = outlineVariant;
  static const Color green = tertiary;
  static const Color red = errorRed;

  // Dark Palette Variants (Guild Modernist Dark)
  static const Color darkBg = Color(0xFF10141D);
  static const Color darkCard = Color(0xFF1A2130);
  static const Color darkText = Color(0xFFEDF0FF);
  static const Color darkMuted = Color(0xFF9096A8);
  static const Color darkLine = Color(0xFF2C344A);
  static const Color darkGreen = Color(0xFF63DCA6);
  static const Color darkRed = Color(0xFFFF6B6B);
  static const Color darkContainer = Color(0xFF1A3B8B);
  static const Color darkAmberContainer = Color(0xFF3D2E0A);

  /// Get the 4px vertical accent bar color by trade category name
  static Color getCategoryColor(String? category) {
    if (category == null) return primary;
    final lower = category.toLowerCase();
    if (lower.contains('electric') || lower.contains('بجلی')) {
      return primary;
    } else if (lower.contains('plumb') || lower.contains('پلمبر')) {
      return tertiaryContainer;
    } else if (lower.contains('ac') || lower.contains('hv') || lower.contains('کولر')) {
      return amberWarm;
    } else if (lower.contains('carpent') || lower.contains('wood') || lower.contains('بڑھئی')) {
      return secondary;
    } else if (lower.contains('paint') || lower.contains('رنگ')) {
      return Color(0xFF7E22CE); // Deep purple accent
    } else if (lower.contains('mason') || lower.contains('construct') || lower.contains('مستری')) {
      return Color(0xFFD97706);
    } else if (lower.contains('clean') || lower.contains('صفائی')) {
      return Color(0xFF0284C7);
    }
    return primary;
  }

  // Light Color Scheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainer: surfaceWhite,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    error: errorRed,
    onError: onError,
  );

  // Dark Color Scheme
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: inversePrimary,
    onPrimary: Color(0xFF00174D),
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondaryContainer,
    onSecondary: Color(0xFF00164E),
    secondaryContainer: Color(0xFF264191),
    onSecondaryContainer: onSecondaryContainer,
    tertiary: darkGreen,
    onTertiary: Color(0xFF002113),
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    surface: darkBg,
    onSurface: darkText,
    surfaceContainer: darkCard,
    onSurfaceVariant: darkMuted,
    outline: darkLine,
    outlineVariant: Color(0xFF3F465B),
    error: darkRed,
    onError: Color(0xFF410002),
  );
}
