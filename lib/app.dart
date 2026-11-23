import 'package:flutter/material.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/router/app_router.dart';
import 'package:skill_bridge/config/theme/sb/sb_theme.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/core/services/local_account_data_cleanup.dart';
import 'package:skill_bridge/core/services/public_profile_sync.dart';
import 'package:skill_bridge/shared/widgets/brand/startup_intro.dart';
import 'package:skill_bridge/shared/widgets/connectivity_sync.dart';
import 'package:skill_bridge/features/identity/presentation/verified_badge.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keeps the signed-in person's public profile in step (free plan: no
    // Cloud Functions to do it).
    ref.watch(publicProfileSyncProvider);
    // Clears this device's cached listings, queued actions and searches when
    // an account signs out or another account signs in.
    ref.watch(localAccountDataCleanupProvider);

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
      // StartupIntro plays the short "Skill" + "Bridge" brand animation once
      // per app launch, above whichever screen the router opens.
      builder: (context, child) => StartupIntro(
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.2,
          // Plain "You're offline" line + resend queued actions; the Verified
          // pop-up once a person's identity is checked.
          child: ConnectivitySync(child: VerifiedCelebrationWatcher(child: child ?? const SizedBox.shrink())),
        ),
      ),
    );
  }
}
