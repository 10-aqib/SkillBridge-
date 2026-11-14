import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One family for the whole product: Noto Sans for Latin text, Noto Nastaliq
/// Urdu for Urdu. Each is the other's fallback, so an Urdu name inside English
/// UI (or a Latin brand name inside Urdu UI) still renders correctly.
///
/// Numbers use tabular figures ([SbTypography.numeric]) instead of a separate
/// monospace font, so prices and ratings line up without a third typeface.
abstract final class SbTypography {
  static const String latinFamily = 'Noto Sans';
  static const String urduFamily = 'Noto Nastaliq Urdu';

  /// Nastaliq has tall ascenders/descenders; Urdu needs a slightly larger size
  /// and more line height to stay legible and avoid clipping.
  static const double urduSizeDelta = 1;
  static const double urduLineHeightFactor = 1.35;

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static bool isUrdu(Locale? locale) => locale?.languageCode == 'ur';

  /// Fallback chain for any text style: Noto Sans for Latin, then Noto
  /// Nastaliq Urdu for Urdu script.
  static List<String> fallbackFamilies() => [
        GoogleFonts.notoSans().fontFamily!,
        GoogleFonts.notoNastaliqUrdu().fontFamily!,
      ];

  /// Builds the text theme for a locale. Pass [useGoogleFonts] = false in
  /// tests (no network) — the scale and metrics are unchanged.
  static TextTheme textTheme({
    required Color color,
    required Color secondaryColor,
    Locale? locale,
    bool useGoogleFonts = true,
  }) {
    final urdu = isUrdu(locale);
    String? family;
    List<String> fallback = const [];
    if (useGoogleFonts) {
      final latin = GoogleFonts.notoSans().fontFamily!;
      final nastaliq = GoogleFonts.notoNastaliqUrdu().fontFamily!;
      family = urdu ? nastaliq : latin;
      // Noto Sans first in both locales: if a screen names an unregistered
      // family (e.g. 'Inter'), Latin text must land on Noto Sans, not on
      // Nastaliq's serif Latin glyphs. Urdu glyphs then fall through to
      // Nastaliq because Noto Sans has no Arabic script.
      fallback = [latin, nastaliq];
    }

    TextStyle s(double size, double line, FontWeight w, double tracking, {Color? c}) {
      final fs = urdu ? size + urduSizeDelta : size;
      final h = (line / size) * (urdu ? urduLineHeightFactor : 1);
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: fs,
        height: h,
        fontWeight: w,
        // Letter spacing breaks Nastaliq joining — never track Urdu.
        letterSpacing: urdu ? 0 : tracking,
        color: c ?? color,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return TextTheme(
      // display — hero numbers and splash only
      displaySmall: s(32, 40, FontWeight.w700, -0.4),
      // headline — screen titles
      headlineSmall: s(24, 32, FontWeight.w700, -0.2),
      // titleLg — section titles, app bar
      titleLarge: s(20, 28, FontWeight.w600, 0),
      // title — card titles, names
      titleMedium: s(17, 24, FontWeight.w600, 0),
      titleSmall: s(15, 22, FontWeight.w600, 0),
      // body
      bodyLarge: s(16, 24, FontWeight.w400, 0),
      bodyMedium: s(14, 20, FontWeight.w400, 0),
      bodySmall: s(12, 16, FontWeight.w400, 0.1, c: secondaryColor),
      // labels — buttons, chips, field labels, badges
      labelLarge: s(14, 20, FontWeight.w600, 0.1),
      labelMedium: s(12, 16, FontWeight.w600, 0.2),
      labelSmall: s(11, 16, FontWeight.w600, 0.3),
    );
  }

  /// Prices, ratings, counts. Keeps digits aligned in lists and tables.
  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: tabular);
}
