import 'package:flutter/material.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/router/app_router.dart';
import 'package:skill_bridge/config/theme/sb/sb_theme.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/core/services/public_profile_sync.dart';
import 'package:skill_bridge/shared/widgets/connectivity_banner.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keeps the signed-in person's public profile in step (free plan: no
    // Cloud Functions to do it).
    ref.watch(publicProfileSyncProvider);

    return MaterialApp.router(
      title: 'Skill Bridge',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // SkillBridge design system (lib/config/theme/sb). Theme mode selection
      // and persistence are unchanged (themeModeProvider). The locale passed to
      // SbTheme matches the pinned app locale below; change both together.
      theme: SbTheme.light(locale: const Locale('en')),
      darkTheme: SbTheme.dark(locale: const Locale('en')),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Fixed-height layouts (e.g. the home banner carousel) must not be
      // broken by very large OS font sizes.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.2,
        child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
