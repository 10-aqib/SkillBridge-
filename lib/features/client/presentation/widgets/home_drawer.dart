import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'Guest';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

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

            // ── Theme Mode Toggle ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: GestureDetector(
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: isDark,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                                val ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                    ],
                  ),
                ),
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
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      context.pop();
                      context.go(RouteNames.clientHomePath);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.work_outline_rounded,
                    title: 'My Jobs',
                    onTap: () {
                      context.pop();
                      context.go(RouteNames.clientJobsPath);
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
