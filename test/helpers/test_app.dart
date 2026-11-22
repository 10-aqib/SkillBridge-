import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

const testLocalizations = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// English strings, for asserting visible copy without hardcoding it twice.
Future<AppLocalizations> englishStrings() => AppLocalizations.delegate.load(const Locale('en'));

/// App shell for widget tests: real ARB localizations and the SkillBridge theme
/// (Google Fonts off — no network in tests).
Widget testApp({
  required Widget home,
  List<dynamic> overrides = const [],
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [...overrides.cast<Override>()],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: testLocalizations,
      theme: SbTheme.light(locale: locale, useGoogleFonts: false),
      darkTheme: SbTheme.dark(locale: locale, useGoogleFonts: false),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  );
}

/// Router-based shell so navigation calls (go/push) work in tests.
Widget testRouterApp({
  required GoRouter router,
  List<dynamic> overrides = const [],
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [...overrides.cast<Override>()],
    child: MaterialApp.router(
      routerConfig: router,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: testLocalizations,
      theme: SbTheme.light(useGoogleFonts: false),
      darkTheme: SbTheme.dark(useGoogleFonts: false),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}
