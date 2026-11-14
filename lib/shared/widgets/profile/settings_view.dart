import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Signs out after confirmation. The router returns to Welcome once the auth
/// state clears.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ok = await showSbConfirmSheet(
    context,
    title: l.signOutConfirmTitle,
    message: l.signOutConfirmBody,
    confirmLabel: l.signOut,
    cancelLabel: l.cancel,
  );
  if (!ok || !context.mounted) return;
  final result = await ref.read(signOutUseCaseProvider).call();
  if (!context.mounted) return;
  result.fold(
    (_) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.errGeneric), backgroundColor: context.sb.error),
    ),
    (_) => context.go(RouteNames.welcomePath),
  );
}

/// Settings shared by client and worker: appearance, support, legal, sign out.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);

    Widget group(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: SbSpace.s5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: SbSpace.s1, bottom: SbSpace.s2),
              child: Semantics(header: true, child: Text(title, style: t.labelLarge!.copyWith(color: c.textSecondary))),
            ),
            // Material (not a coloured Container) so ListTile ink stays visible.
            Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SbRadius.card),
                side: BorderSide(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.border),
                  children[i],
                ],
              ]),
            ),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s2, SbLayout.edge(context), SbSpace.s8),
        children: [
          SbReadableWidth(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              group(l.settingsAppearance, [
                Padding(
                  padding: const EdgeInsets.all(SbSpace.s3),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l.settingsThemeLight)),
                      ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l.settingsThemeDark)),
                      ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.settings_suggest_outlined), label: Text(l.settingsThemeSystem)),
                    ],
                    selected: {mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setThemeMode(s.first),
                  ),
                ),
              ]),
              group(l.settingsHelp, [
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: Text(l.customerSupport),
                  subtitle: Text(l.settingsSupportBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => SupportUtils.showSupportOptions(context),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.termsAndConditions),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(RouteNames.termsAndConditionsPath),
                ),
              ]),
              group(l.settingsAccount, [
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: c.error),
                  title: Text(l.signOut, style: TextStyle(color: c.error)),
                  onTap: () => confirmAndSignOut(context, ref),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
