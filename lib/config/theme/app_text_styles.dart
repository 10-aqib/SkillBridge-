import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Guild Modernist Tri-Font Typography System
/// 1. Sora — display/headings (Modern, confident voice)
/// 2. Inter — body/UI (Interface labels & descriptions)
/// 3. JetBrains Mono — numeric/data (Prices, ratings, metrics)
class AppTextStyles {
  // Sora Headings & Displays
  static TextStyle get displayHero => GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700, // Bold
        height: 1.2,
      );

  static TextStyle get headlineLg => GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700, // Bold
        height: 1.2,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w600, // SemiBold
        height: 1.3,
      );

  static TextStyle get heading3 => GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w500, // Medium
        height: 1.4,
      );

  // Inter Body & UI
  static TextStyle get bodyPrimary => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400, // Regular
        height: 1.5,
      );

  static TextStyle get bodyStrong => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600, // SemiBold
        height: 1.5,
      );

  static TextStyle get labelCaption => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        height: 1.5,
      );

  static TextStyle get labelStatus => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500, // Medium
        height: 1.5,
      );

  // JetBrains Mono Numeric & Financial Metrics
  static TextStyle get dataNumeric => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get dataNumericLg => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w600, // SemiBold
        height: 1.5,
      );

  // Backward-compatible mappings
  static TextStyle get displayLarge => displayHero;
  static TextStyle get headlineLarge => headlineLg;
  static TextStyle get headlineMedium => headlineLgMobile;
  static TextStyle get titleLarge => heading2;
  static TextStyle get titleMedium => heading3;
  static TextStyle get titleSmall => GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get bodyLarge => bodyStrong;
  static TextStyle get bodyMedium => bodyPrimary;
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get labelLarge => bodyStrong;
  static TextStyle get labelMedium => labelCaption;
  static TextStyle get labelSmall => labelStatus;
  static TextStyle get caption => labelCaption;
}
