import 'package:flutter/material.dart';

/// SkillBridge design tokens — "Local expertise, made easier to trust."
///
/// Mirrors `design/tokens/skillbridge.tokens.json`. Change both together and
/// run `node design/tools/check-contrast.mjs`.
///
/// Screens read colours through `context.sb` (see [SbColors]) instead of
/// hardcoded hex values, so light, dark and future high-contrast modes stay in
/// step automatically.
abstract final class SbBrand {
  static const Color inkBlue = Color(0xFF174A8B);
  static const Color craftAmber = Color(0xFFE4A33A);
  static const Color trustTeal = Color(0xFF167A63);
  static const Color warmCanvas = Color(0xFFF7F8F6);
}

/// Semantic colour roles. Use the role that describes *why* the colour is
/// there (e.g. `success` for verified), not the hue.
@immutable
class SbColors extends ThemeExtension<SbColors> {
  const SbColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceRaised,
    required this.text,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.borderStrong,
    required this.borderInput,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.primarySubtle,
    required this.onPrimarySubtle,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.onAccentSubtle,
    required this.success,
    required this.onSuccess,
    required this.successSubtle,
    required this.onSuccessSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.onWarningSubtle,
    required this.error,
    required this.onError,
    required this.errorSubtle,
    required this.onErrorSubtle,
    required this.focusRing,
    required this.scrim,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color surfaceRaised;
  final Color text;
  final Color textSecondary;

  /// Disabled controls and placeholder-like decoration only. Never for
  /// readable content: it does not meet 4.5:1.
  final Color textDisabled;
  final Color border;
  final Color borderStrong;

  /// Outline of text fields and other inputs (meets 3:1 non-text contrast).
  final Color borderInput;
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;
  final Color primarySubtle;
  final Color onPrimarySubtle;

  /// Craft amber. Decorative highlights and fills only — never small text on
  /// a light surface. Put [onAccent] on top of it.
  final Color accent;
  final Color onAccent;
  final Color accentSubtle;
  final Color onAccentSubtle;
  final Color success;
  final Color onSuccess;
  final Color successSubtle;
  final Color onSuccessSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color onWarningSubtle;
  final Color error;
  final Color onError;
  final Color errorSubtle;
  final Color onErrorSubtle;
  final Color focusRing;
  final Color scrim;

  static const SbColors light = SbColors(
    canvas: Color(0xFFF7F8F6),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEEF1EE),
    surfaceRaised: Color(0xFFFFFFFF),
    text: Color(0xFF18232F),
    textSecondary: Color(0xFF596779),
    textDisabled: Color(0xFF8C97A3),
    border: Color(0xFFDCE3E8),
    borderStrong: Color(0xFFB4C0CA),
    borderInput: Color(0xFF7D8995),
    primary: Color(0xFF174A8B),
    primaryHover: Color(0xFF123D73),
    onPrimary: Color(0xFFFFFFFF),
    primarySubtle: Color(0xFFE7EEF7),
    onPrimarySubtle: Color(0xFF123D73),
    accent: Color(0xFFE4A33A),
    onAccent: Color(0xFF18232F),
    accentSubtle: Color(0xFFFBF0DC),
    onAccentSubtle: Color(0xFF6E4708),
    success: Color(0xFF167A63),
    onSuccess: Color(0xFFFFFFFF),
    successSubtle: Color(0xFFE2F2ED),
    onSuccessSubtle: Color(0xFF0E5545),
    warning: Color(0xFF8A5A00),
    warningSubtle: Color(0xFFFDF2DD),
    onWarningSubtle: Color(0xFF6B4500),
    error: Color(0xFFB42318),
    onError: Color(0xFFFFFFFF),
    errorSubtle: Color(0xFFFCE8E6),
    onErrorSubtle: Color(0xFF8F1C13),
    focusRing: Color(0xFF174A8B),
    scrim: Color(0xFF0B1218),
  );

  static const SbColors dark = SbColors(
    canvas: Color(0xFF0F151B),
    surface: Color(0xFF161E26),
    surfaceSunken: Color(0xFF0B1116),
    surfaceRaised: Color(0xFF1D2731),
    text: Color(0xFFE8EDF1),
    textSecondary: Color(0xFFA4B1BE),
    textDisabled: Color(0xFF6C7986),
    border: Color(0xFF2A3642),
    borderStrong: Color(0xFF3D4B58),
    borderInput: Color(0xFF6E7B88),
    primary: Color(0xFF8FB6EC),
    primaryHover: Color(0xFFA9C7F1),
    onPrimary: Color(0xFF0C2747),
    primarySubtle: Color(0xFF1A2D45),
    onPrimarySubtle: Color(0xFFC3D8F5),
    accent: Color(0xFFF0B85A),
    onAccent: Color(0xFF1F1606),
    accentSubtle: Color(0xFF33270F),
    onAccentSubtle: Color(0xFFF5CF8E),
    success: Color(0xFF5CC4A6),
    onSuccess: Color(0xFF06241C),
    successSubtle: Color(0xFF12302A),
    onSuccessSubtle: Color(0xFF8FDCC5),
    warning: Color(0xFFE9B65C),
    warningSubtle: Color(0xFF33270F),
    onWarningSubtle: Color(0xFFF5CF8E),
    error: Color(0xFFF2A39C),
    onError: Color(0xFF3D0B07),
    errorSubtle: Color(0xFF3A1714),
    onErrorSubtle: Color(0xFFF7C2BD),
    focusRing: Color(0xFF8FB6EC),
    scrim: Color(0xFF000000),
  );

  /// Background/foreground pair for a status tone.
  SbTonePair tone(SbTone tone) => switch (tone) {
        SbTone.neutral => SbTonePair(surfaceSunken, textSecondary),
        SbTone.info => SbTonePair(primarySubtle, onPrimarySubtle),
        SbTone.success => SbTonePair(successSubtle, onSuccessSubtle),
        SbTone.warning => SbTonePair(warningSubtle, onWarningSubtle),
        SbTone.error => SbTonePair(errorSubtle, onErrorSubtle),
        SbTone.accent => SbTonePair(accentSubtle, onAccentSubtle),
      };

  @override
  SbColors copyWith({
    Color? canvas,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? primary,
    Color? onPrimary,
  }) {
    return SbColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken,
      surfaceRaised: surfaceRaised,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled,
      border: border,
      borderStrong: borderStrong,
      borderInput: borderInput,
      primary: primary ?? this.primary,
      primaryHover: primaryHover,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySubtle: primarySubtle,
      onPrimarySubtle: onPrimarySubtle,
      accent: accent,
      onAccent: onAccent,
      accentSubtle: accentSubtle,
      onAccentSubtle: onAccentSubtle,
      success: success,
      onSuccess: onSuccess,
      successSubtle: successSubtle,
      onSuccessSubtle: onSuccessSubtle,
      warning: warning,
      warningSubtle: warningSubtle,
      onWarningSubtle: onWarningSubtle,
      error: error,
      onError: onError,
      errorSubtle: errorSubtle,
      onErrorSubtle: onErrorSubtle,
      focusRing: focusRing,
      scrim: scrim,
    );
  }

  @override
  SbColors lerp(ThemeExtension<SbColors>? other, double t) {
    if (other is! SbColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SbColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      textDisabled: l(textDisabled, other.textDisabled),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      borderInput: l(borderInput, other.borderInput),
      primary: l(primary, other.primary),
      primaryHover: l(primaryHover, other.primaryHover),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySubtle: l(primarySubtle, other.primarySubtle),
      onPrimarySubtle: l(onPrimarySubtle, other.onPrimarySubtle),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSubtle: l(accentSubtle, other.accentSubtle),
      onAccentSubtle: l(onAccentSubtle, other.onAccentSubtle),
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successSubtle: l(successSubtle, other.successSubtle),
      onSuccessSubtle: l(onSuccessSubtle, other.onSuccessSubtle),
      warning: l(warning, other.warning),
      warningSubtle: l(warningSubtle, other.warningSubtle),
      onWarningSubtle: l(onWarningSubtle, other.onWarningSubtle),
      error: l(error, other.error),
      onError: l(onError, other.onError),
      errorSubtle: l(errorSubtle, other.errorSubtle),
      onErrorSubtle: l(onErrorSubtle, other.onErrorSubtle),
      focusRing: l(focusRing, other.focusRing),
      scrim: l(scrim, other.scrim),
    );
  }
}

/// Status tones shared by badges, banners and state views.
enum SbTone { neutral, info, success, warning, error, accent }

@immutable
class SbTonePair {
  const SbTonePair(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

/// Restrained category tones for icon tiles. Always shown with the category
/// name; colour is never the only signal.
enum SbCategoryTone {
  ink(Color(0xFFE7EEF7), Color(0xFF174A8B), Color(0xFF1A2D45), Color(0xFF8FB6EC)),
  teal(Color(0xFFE2F2ED), Color(0xFF0E5545), Color(0xFF12302A), Color(0xFF8FDCC5)),
  amber(Color(0xFFFBF0DC), Color(0xFF6E4708), Color(0xFF33270F), Color(0xFFF5CF8E)),
  clay(Color(0xFFF8E9E2), Color(0xFF7F3418), Color(0xFF36201A), Color(0xFFF0B9A3)),
  plum(Color(0xFFF1E8F3), Color(0xFF5B2C6F), Color(0xFF2C1F33), Color(0xFFD9B8E6)),
  slate(Color(0xFFEBEFF2), Color(0xFF384654), Color(0xFF222C35), Color(0xFFC2CDD7));

  const SbCategoryTone(this.lightBg, this.lightFg, this.darkBg, this.darkFg);
  final Color lightBg;
  final Color lightFg;
  final Color darkBg;
  final Color darkFg;

  SbTonePair resolve(Brightness b) => b == Brightness.dark
      ? SbTonePair(darkBg, darkFg)
      : SbTonePair(lightBg, lightFg);

  /// Stable tone for a category label (English or Urdu). Same input, same tone.
  static SbCategoryTone forCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    bool has(List<String> keys) => keys.any(c.contains);
    if (has(['electric', 'بجلی', 'solar', 'generator', 'cctv', 'camera', 'internet'])) return ink;
    if (has(['plumb', 'پلمبر', 'water', 'geyser', 'pump', 'clean', 'صفائی'])) return teal;
    if (has(['ac', 'hvac', 'کولر', 'paint', 'رنگ'])) return amber;
    if (has(['mason', 'مستری', 'tile', 'roof', 'construct', 'weld', 'gate'])) return clay;
    if (has(['carpent', 'wood', 'بڑھئی', 'sofa', 'curtain'])) return plum;
    return slate;
  }
}

/// 4-point spacing scale (8-point rhythm for layout).
abstract final class SbSpace {
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

abstract final class SbRadius {
  static const double xs = 4;

  /// Buttons, inputs, chips (non-pill), small tiles.
  static const double control = 8;

  /// Cards, list sections, images.
  static const double card = 12;

  /// Bottom sheets and dialogs.
  static const double sheet = 20;
  static const double full = 999;
}

/// Shadows are reserved for surfaces that float above the page. Content is
/// grouped with borders, not elevation.
abstract final class SbElevation {
  static const List<BoxShadow> none = [];
  static const List<BoxShadow> overlay = [
    BoxShadow(color: Color(0x1A0B1218), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x140B1218), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x240B1218), blurRadius: 32, offset: Offset(0, -8)),
  ];
}

abstract final class SbMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve exit = Cubic(0.3, 0, 1, 1);

  /// Collapses to zero when the OS asks for reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;
}

/// Minimum interactive sizes.
abstract final class SbTarget {
  static const double mobile = 48;
  static const double compact = 40;
}

/// Window size classes. Layout decisions use these, never raw pixel checks.
enum SbWindowSize {
  compact,
  medium,
  expanded;

  static SbWindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static SbWindowSize fromWidth(double width) {
    if (width >= SbLayout.expandedMin) return expanded;
    if (width >= SbLayout.mediumMin) return medium;
    return compact;
  }
}

abstract final class SbLayout {
  static const double mediumMin = 600;
  static const double expandedMin = 1024;
  static const double mobileEdge = 20;
  static const double tabletEdge = 24;
  static const double formMaxWidth = 560;
  static const double contentMaxWidth = 1200;

  static double edge(BuildContext context) =>
      SbWindowSize.of(context) == SbWindowSize.compact ? mobileEdge : tabletEdge;
}

extension SbContext on BuildContext {
  /// SkillBridge semantic colours for the active theme. Falls back to the
  /// light palette if the SkillBridge theme is not installed yet.
  SbColors get sb =>
      Theme.of(this).extension<SbColors>() ??
      (Theme.of(this).brightness == Brightness.dark ? SbColors.dark : SbColors.light);
}
