import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  // Theme shortcut
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;
  Color get scaffoldBg => isDark ? AppColors.darkBg : AppColors.backgroundGray;
  Color get surfaceColor => isDark ? AppColors.darkCard : AppColors.surfaceWhite;
  Color get textColor => isDark ? AppColors.darkText : AppColors.onSurface;
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.onSurfaceVariant;
  Color get borderColor => isDark ? AppColors.darkLine : AppColors.outlineVariant;

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
