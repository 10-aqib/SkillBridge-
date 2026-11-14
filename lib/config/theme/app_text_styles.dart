import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_bridge/config/theme/sb/sb_typography.dart';

/// Legacy text style names, now on the SkillBridge type family:
/// Noto Sans (Latin) with Noto Nastaliq Urdu as fallback, tabular figures for
/// numbers. Fonts are bundled in `assets/fonts/` (google_fonts uses them
/// offline). Sizes and weights are unchanged so existing layouts don't shift.
///
/// New code should use `Theme.of(context).textTheme` (see `SbTypography`).
class AppTextStyles {
  static TextStyle _noto({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      fontFeatures: fontFeatures,
    ).copyWith(fontFamilyFallback: SbTypography.fallbackFamilies());
  }

  // Headings & displays
  static TextStyle get displayHero => _noto(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25);
  static TextStyle get headlineLg => _noto(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25);
  static TextStyle get headlineLgMobile => _noto(fontSize: 24, fontWeight: FontWeight.w700, height: 1.33);
  static TextStyle get heading2 => _noto(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get heading3 => _noto(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  // Body & UI
  static TextStyle get bodyPrimary => _noto(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyStrong => _noto(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5);
  static TextStyle get labelCaption => _noto(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);
  static TextStyle get labelStatus => _noto(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);

  // Numbers (prices, ratings, metrics): same family, tabular figures.
  static TextStyle get dataNumeric => _noto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
        fontFeatures: SbTypography.tabular,
      );

  static TextStyle get dataNumericLg => _noto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFeatures: SbTypography.tabular,
      );

  // Backward-compatible mappings
  static TextStyle get displayLarge => displayHero;
  static TextStyle get headlineLarge => headlineLg;
  static TextStyle get headlineMedium => headlineLgMobile;
  static TextStyle get titleLarge => heading2;
  static TextStyle get titleMedium => heading3;
  static TextStyle get titleSmall => _noto(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);

  static TextStyle get bodyLarge => bodyStrong;
  static TextStyle get bodyMedium => bodyPrimary;
  static TextStyle get bodySmall => _noto(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);

  static TextStyle get labelLarge => bodyStrong;
  static TextStyle get labelMedium => labelCaption;
  static TextStyle get labelSmall => labelStatus;
  static TextStyle get caption => labelCaption;
}
