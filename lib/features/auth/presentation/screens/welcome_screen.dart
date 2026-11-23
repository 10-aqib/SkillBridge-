import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';

/// First screen for signed-out people: what SkillBridge is, then create an
/// account (client or worker), sign in, or continue with Google.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final login = ref.watch(loginViewModelProvider);

    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.needsRole && !(prev?.needsRole ?? false)) {
        ref.read(loginViewModelProvider.notifier).consumeNeedsRole();
        context.go(RouteNames.roleSelectionPath);
      }
    });

    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: SbSpace.s3),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.successSubtle, borderRadius: BorderRadius.circular(SbRadius.control)),
              child: Icon(icon, size: 20, color: c.onSuccessSubtle),
            ),
            const SizedBox(width: SbSpace.s3),
            Expanded(child: Text(text, style: t.bodyLarge)),
          ]),
        );

    return AuthScaffold(
      footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbFailureBanner(failure: login.failure),
        SbButton(
          label: l.welcomeCreateAccount,
          expand: true,
          onPressed: login.isLoading ? null : () => context.push(RouteNames.signupPath),
        ),
        const SizedBox(height: SbSpace.s2),
        SbGoogleButton(
          isLoading: login.isLoading,
          onPressed: () => ref.read(loginViewModelProvider.notifier).loginWithGoogle(),
        ),
        const SizedBox(height: SbSpace.s1),
        SbButton(
          label: l.welcomeSignIn,
          variant: SbButtonVariant.quiet,
          expand: true,
          onPressed: login.isLoading ? null : () => context.push(RouteNames.loginPath),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SbFullLogo(width: 220),
        const SizedBox(height: SbSpace.s5),
        Semantics(header: true, child: Text(l.welcomeTitle, style: t.headlineSmall)),
        const SizedBox(height: SbSpace.s2),
        Text(l.appTagline, style: t.bodyLarge!.copyWith(color: c.textSecondary)),
        const SizedBox(height: SbSpace.s8),
        point(Icons.verified_user_outlined, l.welcomePointTrust),
        point(Icons.near_me_outlined, l.welcomePointNearby),
        point(Icons.forum_outlined, l.welcomePointChat),
        const SizedBox(height: SbSpace.s4),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(l.welcomeTermsPrefix, style: t.bodySmall),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: SbSpace.s1)),
            onPressed: () => context.push(RouteNames.termsAndConditionsPath),
            child: Text(l.termsAndConditions),
          ),
          Text(l.legalAnd, style: t.bodySmall),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: SbSpace.s1)),
            onPressed: () => context.push(RouteNames.privacyPolicyPath),
            child: Text(l.privacyPolicy),
          ),
        ]),
      ]),
    );
  }
}
