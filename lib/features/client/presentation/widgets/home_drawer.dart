import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/constants/app_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';

/// Side menu for clients and workers: shortcuts to their work (different for
/// each role), account, appearance (light/dark/system), and help & legal.
class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final signedIn = user != null;
    final worker = user?.isWorker ?? false;
    final profilePath = worker ? RouteNames.workerProfilePath : RouteNames.clientProfilePath;
    final themeMode = ref.watch(themeModeProvider);

    /// Closes the menu, then runs [action] (navigation or a sheet).
    VoidCallback close(void Function() action) => () {
          Navigator.of(context).pop();
          action();
        };

    Widget section(String title) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(SbSpace.s4, SbSpace.s4, SbSpace.s4, SbSpace.s1),
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(),
                style: t.labelSmall!.copyWith(color: c.textSecondary, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
          ),
        );

    return Drawer(
      width: math.min(MediaQuery.sizeOf(context).width * 0.84, 360),
      backgroundColor: c.canvas,
      child: Column(children: [
        _Header(
          name: user?.displayName.trim().isNotEmpty == true ? user!.displayName : l.drawerGuest,
          email: user?.email ?? '',
          photoUrl: user?.photoUrl,
          signedIn: signedIn,
          onOpenProfile: signedIn ? close(() => context.go(profilePath)) : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: SbSpace.s3),
            children: [
              if (!signedIn) ...[
                const SizedBox(height: SbSpace.s2),
                _DrawerTile(
                  icon: Icons.login_rounded,
                  title: l.drawerSignIn,
                  onTap: close(() => context.push(RouteNames.loginPath)),
                ),
                _DrawerTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: l.drawerCreateAccount,
                  onTap: close(() => context.push(RouteNames.signupPath)),
                ),
              ],
              if (signedIn && worker) ...[
                section(l.drawerSectionWork),
                _DrawerTile(
                  icon: Icons.search_rounded,
                  title: l.drawerFindJobs,
                  onTap: close(() => context.push(RouteNames.workerJobFeedPath)),
                ),
                _DrawerTile(
                  icon: Icons.description_outlined,
                  title: l.drawerMyProposals,
                  onTap: close(() => context.go(RouteNames.workerProposalsPath)),
                ),
                _DrawerTile(
                  icon: Icons.assignment_outlined,
                  title: l.drawerContracts,
                  onTap: close(() => context.go(RouteNames.workerContractsPath)),
                ),
                _DrawerTile(
                  icon: Icons.bookmark_border_rounded,
                  title: l.drawerSavedJobs,
                  onTap: close(() => context.push(RouteNames.workerSavedJobsPath)),
                ),
                _DrawerTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: l.drawerMessages,
                  onTap: close(() => context.go(RouteNames.workerChatsPath)),
                ),
                _DrawerTile(
                  icon: Icons.notifications_none_rounded,
                  title: l.drawerNotifications,
                  onTap: close(() => context.push(RouteNames.workerNotificationsPath)),
                ),
              ],
              if (signedIn && !worker) ...[
                section(l.drawerSectionWork),
                _DrawerTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: l.drawerPostJob,
                  onTap: close(() => context.push(RouteNames.clientPostJobPath)),
                ),
                _DrawerTile(
                  icon: Icons.work_outline_rounded,
                  title: l.drawerMyJobs,
                  onTap: close(() => context.go(RouteNames.clientJobsPath)),
                ),
                _DrawerTile(
                  icon: Icons.assignment_outlined,
                  title: l.drawerContracts,
                  onTap: close(() => context.push(RouteNames.clientContractsPath)),
                ),
                _DrawerTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: l.drawerMessages,
                  onTap: close(() => context.go(RouteNames.clientChatsPath)),
                ),
                _DrawerTile(
                  icon: Icons.notifications_none_rounded,
                  title: l.drawerNotifications,
                  onTap: close(() => context.push(RouteNames.clientNotificationsPath)),
                ),
                _DrawerTile(
                  icon: Icons.map_outlined,
                  title: l.drawerNearbyWorkers,
                  onTap: close(() => context.push(RouteNames.clientNearbyWorkersPath)),
                ),
              ],
              if (signedIn) ...[
                section(l.drawerSectionAccount),
                _DrawerTile(
                  icon: Icons.person_outline_rounded,
                  title: l.drawerProfile,
                  onTap: close(() => context.go(profilePath)),
                ),
                _DrawerTile(
                  icon: Icons.verified_user_outlined,
                  title: l.drawerVerifyIdentity,
                  onTap: close(() => context.push(RouteNames.getVerifiedPath)),
                ),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  title: l.drawerSettings,
                  onTap: close(() => context.push(worker ? RouteNames.workerSettingsPath : RouteNames.clientSettingsPath)),
                ),
              ],
              section(l.settingsAppearance),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SbSpace.s4),
                child: _AppearanceSelector(
                  mode: themeMode,
                  onChanged: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m),
                ),
              ),
              section(l.settingsHelp),
              _DrawerTile(
                icon: Icons.support_agent_rounded,
                title: l.customerSupport,
                onTap: close(() => SupportUtils.showSupportOptions(context)),
              ),
              _DrawerTile(
                icon: Icons.privacy_tip_outlined,
                title: l.privacyPolicy,
                onTap: close(() => context.push(RouteNames.privacyPolicyPath)),
              ),
              _DrawerTile(
                icon: Icons.description_outlined,
                title: l.termsAndConditions,
                onTap: close(() => context.push(RouteNames.termsAndConditionsPath)),
              ),
              _DrawerTile(
                icon: Icons.info_outline_rounded,
                title: l.drawerAbout,
                onTap: close(() => _showAbout(context)),
              ),
              _DrawerTile(
                icon: Icons.share_outlined,
                title: l.drawerShare,
                onTap: close(() => Share.share(l.drawerShareText, subject: 'SkillBridge')),
              ),
              if (signedIn) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
                  child: Divider(height: 1, indent: SbSpace.s4, endIndent: SbSpace.s4, color: c.border),
                ),
                _DrawerTile(
                  icon: Icons.logout_rounded,
                  title: l.drawerSignOut,
                  tone: SbTone.error,
                  onTap: close(() => ref.read(signOutUseCaseProvider).call()),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SbSpace.s3),
            child: Text('SkillBridge · ${l.drawerVersion(AppConstants.appVersion)}',
                style: t.bodySmall!.copyWith(color: c.textSecondary)),
          ),
        ),
      ]),
    );
  }

  static void _showAbout(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          SbLogoMark(size: 40, semanticLabel: null),
          SizedBox(width: SbSpace.s3),
          Flexible(child: SbWordmark(fontSize: 20)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.drawerAboutBody, style: t.bodyMedium),
          const SizedBox(height: SbSpace.s3),
          Text(l.drawerVersion(AppConstants.appVersion), style: t.bodySmall),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(RouteNames.privacyPolicyPath);
            },
            child: Text(l.privacyPolicy),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.signedIn,
    required this.onOpenProfile,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final bool signedIn;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: SbLogoColors.gradient),
      padding: EdgeInsets.fromLTRB(SbSpace.s4, top + SbSpace.s3, SbSpace.s2, SbSpace.s4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32 * 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: const SbLogoMark(size: 32, semanticLabel: null),
          ),
          const SizedBox(width: SbSpace.s2),
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SbWordmark(fontSize: 20, skillColor: Colors.white, bridgeColor: Color(0xFFBFD3FA)),
              ),
            ),
          ),
          IconButton(
            tooltip: l.drawerClose,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ]),
        const SizedBox(height: SbSpace.s4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(SbRadius.card),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SbSpace.s1),
              child: Row(children: [
                AppAvatar(name: name, imageUrl: photoUrl, size: 48),
                const SizedBox(width: SbSpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      signedIn ? email : l.drawerSignInPrompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall!.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ]),
                ),
                if (onOpenProfile != null)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: SbSpace.s2),
                    child: Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.icon, required this.title, required this.onTap, this.tone});

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final SbTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    final fg = tone == null ? c.primary : c.tone(tone!).foreground;
    final bg = tone == null ? c.primarySubtle : c.tone(tone!).background;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: SbSpace.s4),
      minTileHeight: 48,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(SbRadius.control)),
        child: Icon(icon, color: fg, size: 20),
      ),
      title: Text(title,
          style: t.bodyLarge!.copyWith(
            color: tone == null ? c.text : fg,
            fontWeight: FontWeight.w500,
          )),
      onTap: onTap,
    );
  }
}

/// Light / Dark / System choice.
class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l.settingsThemeLight)),
          ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l.settingsThemeDark)),
          ButtonSegment(
              value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(l.settingsThemeSystem)),
        ],
        selected: {mode},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
