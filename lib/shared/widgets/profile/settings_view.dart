import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/account/account_deletion_service.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/features/identity/presentation/verification_status_widget.dart';
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

/// The signed-in person's push settings (users/{uid}.notificationPrefs):
/// push, messages, work. Missing switches count as on.
final notificationPrefsProvider = StreamProvider<Map<String, bool>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const {});
  return ref.watch(firestoreProvider).collection('users').doc(uid).snapshots().map((d) {
    final raw = d.data()?['notificationPrefs'];
    return {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.key is String && e.value is bool) e.key as String: e.value as bool,
    };
  });
});

/// Whether the signed-in account has a password (email sign-in), so it
/// can be changed by email link. False without Firebase (tests).
final canChangePasswordProvider = Provider<bool>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  try {
    return ref.watch(firebaseAuthProvider).currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;
  } catch (_) {
    return false;
  }
});

Future<void> _setPref(BuildContext context, WidgetRef ref, String key, bool value) async {
  final uid = ref.read(currentUserProvider)?.uid;
  if (uid == null) return;
  final current = ref.read(notificationPrefsProvider).value ?? const {};
  final next = {'push': current['push'] ?? true, 'messages': current['messages'] ?? true, 'work': current['work'] ?? true, key: value};
  final result = await ref.read(updateUserProfileUseCaseProvider).call(uid: uid, data: {'notificationPrefs': next});
  if (result.isLeft() && context.mounted) context.showSnackBar(context.l10n.settingsSaveFailed, isError: true);
}

Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final email = ref.read(firebaseAuthProvider).currentUser?.email;
  if (email == null || email.isEmpty) return;
  final result = await ref.read(sendPasswordResetEmailUseCaseProvider).call(email: email);
  if (!context.mounted) return;
  result.fold(
    (_) => context.showSnackBar(l.errGeneric, isError: true),
    (_) => context.showSnackBar(l.settingsPasswordEmailSent),
  );
}

/// Asks, then deletes the account through the trusted function, then signs
/// out locally and returns to Welcome. Explains every refusal.
Future<void> confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ok = await showSbConfirmSheet(
    context,
    title: l.deleteAccountTitle,
    message: l.deleteAccountBody,
    confirmLabel: l.deleteAccountConfirm,
    cancelLabel: l.cancel,
  );
  if (!ok || !context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: SbSpace.s4),
          Expanded(child: Text(l.deleteAccountWorking)),
        ]),
      ),
    ),
  );
  AccountDeletionProblem? problem;
  try {
    await ref.read(accountDeletionServiceProvider).deleteMyAccount();
  } on AccountDeletionException catch (e) {
    problem = e.problem;
  }
  navigator.pop();
  if (!context.mounted) return;
  if (problem == null) {
    await ref.read(signOutUseCaseProvider).call();
    if (!context.mounted) return;
    context.showSnackBar(l.deleteAccountDone);
    context.go(RouteNames.welcomePath);
    return;
  }
  if (problem == AccountDeletionProblem.recentLoginRequired) {
    final again = await showSbConfirmSheet(
      context,
      title: l.deleteAccountTitle,
      message: l.deleteAccountRecentLogin,
      confirmLabel: l.deleteAccountSignInAgain,
      cancelLabel: l.cancel,
    );
    if (!again || !context.mounted) return;
    await ref.read(signOutUseCaseProvider).call();
    if (context.mounted) context.go(RouteNames.welcomePath);
    return;
  }
  context.showSnackBar(
    switch (problem) {
      AccountDeletionProblem.activeContracts => l.deleteAccountActive,
      AccountDeletionProblem.notAvailable => l.deleteAccountUnavailable,
      AccountDeletionProblem.offline => l.errNetwork,
      _ => l.deleteAccountFailed,
    },
    isError: true,
  );
}

/// Settings shared by client and worker: appearance, notifications, support,
/// legal, account (password, sign out, delete).
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
              group(l.identityTitle, [
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded),
                  title: Text(l.identityTitle),
                  subtitle: Text(identityStatusLabel(l, IdentityState.of(ref.watch(currentUserProvider)))),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(RouteNames.identityPath),
                ),
              ]),
              group(l.settingsNotifications, [
                Builder(builder: (context) {
                  final prefs = ref.watch(notificationPrefsProvider).value ?? const <String, bool>{};
                  final push = prefs['push'] ?? true;
                  return Column(children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: Text(l.settingsPushAll),
                      subtitle: Text(l.settingsPushAllBody),
                      value: push,
                      onChanged: (v) => _setPref(context, ref, 'push', v),
                    ),
                    Divider(height: 1, color: c.border),
                    SwitchListTile(
                      secondary: const Icon(Icons.chat_bubble_outline_rounded),
                      title: Text(l.settingsPushMessages),
                      value: push && (prefs['messages'] ?? true),
                      onChanged: push ? (v) => _setPref(context, ref, 'messages', v) : null,
                    ),
                    Divider(height: 1, color: c.border),
                    SwitchListTile(
                      secondary: const Icon(Icons.work_outline_rounded),
                      title: Text(l.settingsPushWork),
                      value: push && (prefs['work'] ?? true),
                      onChanged: push ? (v) => _setPref(context, ref, 'work', v) : null,
                    ),
                  ]);
                }),
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
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l.privacyPolicy),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(RouteNames.privacyPolicyPath),
                ),
              ]),
              group(l.settingsAccount, [
                if (ref.watch(canChangePasswordProvider))
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded),
                    title: Text(l.settingsChangePassword),
                    subtitle: Text(l.settingsChangePasswordBody),
                    onTap: () => _changePassword(context, ref),
                  ),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: c.error),
                  title: Text(l.signOut, style: TextStyle(color: c.error)),
                  onTap: () => confirmAndSignOut(context, ref),
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: c.error),
                  title: Text(l.settingsDeleteAccount, style: TextStyle(color: c.error)),
                  onTap: () => confirmAndDeleteAccount(context, ref),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
