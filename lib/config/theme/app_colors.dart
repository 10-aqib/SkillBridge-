import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

/// Legacy colour names, now backed by the SkillBridge design tokens
/// (`lib/config/theme/sb/sb_tokens.dart`).
///
/// Every constant keeps its name and stays `const`, so existing screens compile
/// unchanged while they migrate. New code should read `context.sb.<role>`
/// instead: those values follow light/dark automatically, these do not.
class AppColors {
  // ── Surfaces (light) ──
  static const Color surface = Color(0xFFF7F8F6); // canvas
  static const Color surfaceDim = Color(0xFFEEF1EE); // surfaceSunken
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F8F6);
  static const Color surfaceContainer = Color(0xFFEEF1EE);
  static const Color surfaceContainerHigh = Color(0xFFDCE3E8);
  static const Color surfaceContainerHighest = Color(0xFFB4C0CA);
  static const Color onSurface = Color(0xFF18232F); // text
  static const Color onSurfaceVariant = Color(0xFF596779); // textSecondary
  static const Color inverseSurface = Color(0xFF18232F);
  static const Color inverseOnSurface = Color(0xFFF7F8F6);
  static const Color outline = Color(0xFF7D8995); // borderInput (3:1)
  static const Color outlineVariant = Color(0xFFDCE3E8); // border
  static const Color borderGray = outlineVariant;
  static const Color surfaceTint = Color(0x00000000);

  // ── Primary: ink blue ──
  static const Color primary = SbBrand.inkBlue; // #174A8B
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF123D73); // primaryHover
  static const Color onPrimaryContainer = Color(0xFFE7EEF7);
  static const Color inversePrimary = Color(0xFF8FB6EC); // dark-theme primary

  static const Color secondary = Color(0xFF3D6FB0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE7EEF7); // primarySubtle
  static const Color onSecondaryContainer = Color(0xFF123D73);

  // ── Trust teal (success / verified / available) ──
  static const Color tertiary = SbBrand.trustTeal; // #167A63
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF0E5545);
  static const Color onTertiaryContainer = Color(0xFFE2F2ED);

  // ── Error ──
  static const Color error = Color(0xFFB42318);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFCE8E6);
  static const Color onErrorContainer = Color(0xFF8F1C13);

  static const Color background = SbBrand.warmCanvas; // #F7F8F6
  static const Color onBackground = Color(0xFF18232F);
  static const Color surfaceVariant = Color(0xFFEEF1EE);

  // ── Brand / utility extras ──
  /// Craft amber. Fills and icons only — never small text on white.
  static const Color amberWarm = SbBrand.craftAmber; // #E4A33A
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = SbBrand.warmCanvas;
  static const Color textMuted = Color(0xFF596779);
  static const Color errorRed = error;
  static const Color blueTint = Color(0xFFE7EEF7); // primarySubtle
  /// Warning text/icon colour (5.9:1 on white).
  static const Color warningOrange = Color(0xFF8A5A00);
  static const Color successGreen = SbBrand.trustTeal;
  static const Color primaryLight = Color(0xFF3D6FB0);

  // ── Backward-compatibility aliases ──
  static const Color navy = primary;
  static const Color navy2 = primaryContainer;
  static const Color amber = amberWarm;
  static const Color amber2 = Color(0xFF6E4708); // onAccentSubtle (readable amber)
  static const Color cream = surface;
  static const Color white = surfaceWhite;
  static const Color ink = onSurface;
  static const Color muted = onSurfaceVariant;
  static const Color line = outlineVariant;
  static const Color green = tertiary;
  static const Color red = errorRed;

  // ── Dark palette ──
  static const Color darkBg = Color(0xFF0F151B); // canvas
  static const Color darkCard = Color(0xFF161E26); // surface
  static const Color darkText = Color(0xFFE8EDF1);
  static const Color darkMuted = Color(0xFFA4B1BE);
  static const Color darkLine = Color(0xFF2A3642);
  static const Color darkGreen = Color(0xFF5CC4A6);
  static const Color darkRed = Color(0xFFF2A39C);
  static const Color darkContainer = Color(0xFF1A2D45); // primarySubtle (dark)
  static const Color darkAmberContainer = Color(0xFFF0B85A); // accent (dark)

  /// Accent bar / icon colour for a trade category (English or Urdu name).
  /// Uses the same stable tone as `SbCategoryTone.forCategory`.
  static Color getCategoryColor(String? category) {
    if (category == null) return primary;
    return SbCategoryTone.forCategory(category).lightFg;
  }

  // ── Material colour schemes (kept for any direct users; the app theme is SbTheme) ──
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: Color(0xFFE7EEF7),
    onPrimaryContainer: Color(0xFF123D73),
    secondary: tertiary,
    onSecondary: onTertiary,
    secondaryContainer: Color(0xFFE2F2ED),
    onSecondaryContainer: tertiaryContainer,
    tertiary: amberWarm,
    onTertiary: Color(0xFF18232F),
    tertiaryContainer: Color(0xFFFBF0DC),
    onTertiaryContainer: amber2,
    surface: surfaceWhite,
    onSurface: onSurface,
    surfaceContainer: surfaceWhite,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    error: error,
    onError: onError,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: inversePrimary,
    onPrimary: Color(0xFF0C2747),
    primaryContainer: darkContainer,
    onPrimaryContainer: Color(0xFFC3D8F5),
    secondary: darkGreen,
    onSecondary: Color(0xFF06241C),
    secondaryContainer: Color(0xFF12302A),
    onSecondaryContainer: Color(0xFF8FDCC5),
    tertiary: darkAmberContainer,
    onTertiary: Color(0xFF1F1606),
    tertiaryContainer: Color(0xFF33270F),
    onTertiaryContainer: Color(0xFFF5CF8E),
    surface: darkCard,
    onSurface: darkText,
    surfaceContainer: darkCard,
    onSurfaceVariant: darkMuted,
    outline: Color(0xFF6E7B88),
    outlineVariant: darkLine,
    error: darkRed,
    onError: Color(0xFF3D0B07),
  );
}
