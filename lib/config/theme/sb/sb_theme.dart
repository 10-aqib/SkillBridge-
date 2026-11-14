import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';
import 'package:skill_bridge/config/theme/sb/sb_typography.dart';

/// Builds SkillBridge [ThemeData] from tokens. Every Material component theme
/// is set here so screens get the house style without local overrides.
///
/// Not yet wired into `app.dart` — Phase 2 swaps `AppTheme` for this after the
/// prototypes are approved.
abstract final class SbTheme {
  static ThemeData light({Locale? locale, bool useGoogleFonts = true}) =>
      _build(SbColors.light, Brightness.light, locale, useGoogleFonts);

  static ThemeData dark({Locale? locale, bool useGoogleFonts = true}) =>
      _build(SbColors.dark, Brightness.dark, locale, useGoogleFonts);

  static ThemeData _build(SbColors c, Brightness b, Locale? locale, bool gf) {
    final text = SbTypography.textTheme(
      color: c.text,
      secondaryColor: c.textSecondary,
      locale: locale,
      useGoogleFonts: gf,
    );
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySubtle,
      onPrimaryContainer: c.onPrimarySubtle,
      secondary: c.success,
      onSecondary: c.onSuccess,
      secondaryContainer: c.successSubtle,
      onSecondaryContainer: c.onSuccessSubtle,
      tertiary: c.accent,
      onTertiary: c.onAccent,
      tertiaryContainer: c.accentSubtle,
      onTertiaryContainer: c.onAccentSubtle,
      error: c.error,
      onError: c.onError,
      errorContainer: c.errorSubtle,
      onErrorContainer: c.onErrorSubtle,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.canvas,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.borderInput,
      outlineVariant: c.border,
      shadow: c.scrim,
      scrim: c.scrim,
      inverseSurface: b == Brightness.light ? const Color(0xFF18232F) : const Color(0xFFE8EDF1),
      onInverseSurface: b == Brightness.light ? const Color(0xFFF7F8F6) : const Color(0xFF18232F),
      inversePrimary: b == Brightness.light ? SbColors.dark.primary : SbColors.light.primary,
      surfaceTint: Colors.transparent,
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.control),
    );
    final buttonText = text.labelLarge!.copyWith(fontSize: 15);
    const buttonMin = Size(64, SbTarget.mobile);
    const buttonPad = EdgeInsets.symmetric(horizontal: SbSpace.s5);

    OutlineInputBorder field(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(SbRadius.control),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      textTheme: text,
      extensions: [c],
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.border,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: c.text, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: SbLayout.mobileEdge,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle:
            b == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        shape: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0))),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SbRadius.card),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfaceSunken,
          disabledForegroundColor: c.textDisabled,
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      // ElevatedButton is styled flat so existing screens match FilledButton.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfaceSunken,
          disabledForegroundColor: c.textDisabled,
          elevation: 0,
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          disabledForegroundColor: c.textDisabled,
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: controlShape,
          side: BorderSide(color: c.borderStrong),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          disabledForegroundColor: c.textDisabled,
          minimumSize: const Size(48, SbTarget.mobile),
          padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(SbTarget.mobile, SbTarget.mobile),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: SbSpace.s4, vertical: 14),
        border: field(c.borderInput),
        enabledBorder: field(c.borderInput),
        focusedBorder: field(c.focusRing, 2),
        errorBorder: field(c.error),
        focusedErrorBorder: field(c.error, 2),
        disabledBorder: field(c.border),
        labelStyle: text.bodyLarge!.copyWith(color: c.textSecondary),
        floatingLabelStyle: text.labelLarge!.copyWith(color: c.primary),
        hintStyle: text.bodyLarge!.copyWith(color: c.textSecondary),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall!.copyWith(color: c.error),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primarySubtle,
        disabledColor: c.surfaceSunken,
        labelStyle: text.labelLarge!.copyWith(color: c.text),
        secondaryLabelStyle: text.labelLarge!.copyWith(color: c.onPrimarySubtle),
        side: BorderSide(color: c.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.full)),
        padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3, vertical: SbSpace.s2),
        showCheckmark: true,
        checkmarkColor: c.onPrimarySubtle,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primarySubtle,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? c.onPrimarySubtle : c.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium!.copyWith(
            color: s.contains(WidgetState.selected) ? c.primary : c.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primarySubtle,
        selectedIconTheme: IconThemeData(color: c.onPrimarySubtle),
        unselectedIconTheme: IconThemeData(color: c.textSecondary),
        selectedLabelTextStyle: text.labelMedium!.copyWith(color: c.primary),
        unselectedLabelTextStyle: text.labelMedium!.copyWith(color: c.textSecondary),
        labelType: NavigationRailLabelType.all,
        minWidth: 80,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.textSecondary,
        indicatorColor: c.primary,
        dividerColor: c.border,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.text,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodyMedium!.copyWith(color: c.textSecondary),
        minVerticalPadding: SbSpace.s3,
        contentPadding: const EdgeInsets.symmetric(horizontal: SbLayout.mobileEdge),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim.withValues(alpha: 0.45),
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(SbRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.scrim.withValues(alpha: 0.45),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge!.copyWith(color: c.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.sheet)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.control)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.primarySubtle,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.borderInput,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.borderInput,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.borderInput, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.xs)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.borderInput,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(SbRadius.xs),
        ),
        textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
