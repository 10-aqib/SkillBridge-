import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'Guest';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: context.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── Premium Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF001E60), Color(0xFF003FB1)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        name: displayName,
                        imageUrl: photoUrl,
                        size: 52,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: AppTextStyles.labelCaption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  if (user == null)
                    const Text(
                      'Sign in to access all features',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),

            // ── Appearance Selector (Light / Dark / System) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 6),
                    child: Text(
                      'Appearance',
                      style: AppTextStyles.labelStatus.copyWith(
                          color: context.mutedColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        _AppearanceOption(
                          icon: Icons.light_mode_rounded,
                          label: 'Light',
                          selected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                        _AppearanceOption(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark',
                          selected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                        _AppearanceOption(
                          icon: Icons.brightness_auto_rounded,
                          label: 'System',
                          selected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Menu Items ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (user == null) ...[
                    _DrawerTile(
                      icon: Icons.login_rounded,
                      title: 'Login',
                      onTap: () {
                        context.pop();
                        context.push(RouteNames.loginPath);
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.person_add_outlined,
                      title: 'Register',
                      onTap: () {
                        context.pop();
                        context.push(RouteNames.signupPath);
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                  ],
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      context.pop();
                      context.push(RouteNames.clientSettingsPath);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.map_outlined,
                    title: 'Find Workers Near Me',
                    onTap: () {
                      context.pop();
                      context.push(RouteNames.clientNearbyWorkersPath);
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _DrawerTile(
                    icon: Icons.support_agent_rounded,
                    title: context.l10n.customerSupport,
                    onTap: () {
                      context.pop();
                      SupportUtils.showSupportOptions(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    title: context.l10n.termsAndConditions,
                    onTap: () {
                      context.pop();
                      context.push(RouteNames.termsAndConditionsPath);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.share_rounded,
                    title: 'Invite Friends & Earn',
                    onTap: () {
                      context.pop();
                      Share.share(
                        '🔧 Try Skill Bridge — find trusted home service professionals near you! Download: https://skillbridge.pk',
                        subject: 'Skill Bridge App',
                      );
                    },
                  ),
                  if (user != null) ...[
                    const Divider(indent: 16, endIndent: 16),
                    _DrawerTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      iconColor: AppColors.errorRed,
                      textColor: AppColors.errorRed,
                      onTap: () {
                        context.pop();
                        ref.read(signOutUseCaseProvider).call();
                      },
                    ),
                  ],
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Skill Bridge v1.0.0',
                    style: AppTextStyles.labelCaption.copyWith(
                      color: context.mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: textColor ?? context.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.labelCaption.copyWith(
                color: AppColors.successGreen,
                fontSize: 11,
              ),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 13, color: context.mutedColor),
      onTap: onTap,
    );
  }
}

/// Three-state appearance toggle chip used inside the drawer.
class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$label appearance mode${selected ? ", selected" : ""}',
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : context.mutedColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTextStyles.labelStatus.copyWith(
                    color: selected
                        ? AppColors.primary
                        : context.mutedColor,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
