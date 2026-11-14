import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  // Theme shortcut
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;
  // Themed colours come from the active SkillBridge token set (SbColors), so
  // they are correct in light and dark. Prefer `context.sb.<role>` in new code.
  Color get scaffoldBg => sb.canvas;
  Color get surfaceColor => sb.surface;
  Color get textColor => sb.text;
  Color get mutedColor => sb.textSecondary;
  Color get borderColor => sb.border;

  /// Accent for icons/indicators sitting on a themed surface. Do NOT use as a
  /// fill that white text sits on — use the light-theme primary there.
  Color get accentColor => sb.primary;

  // Directionality shortcut, for layout mirroring.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Whether the active UI language is Urdu, for picking a display label out of
  /// data that carries its own translations (e.g. [PakistanConstants]).
  /// For UI copy use [l10n] instead — this is not a substitute for it.
  bool get isUrdu => Localizations.localeOf(this).languageCode == 'ur';

  // Media Query shortcut
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // Navigation shortcut
  NavigatorState get navigator => Navigator.of(this);

  // Localization shortcut
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  // SnackBar shortcuts
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
