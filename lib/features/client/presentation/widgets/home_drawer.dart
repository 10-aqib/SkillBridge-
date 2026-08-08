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
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
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

            // ── Language & Theme Toggles ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  // Language Toggle
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(languageProvider.notifier)
                                  .setLanguage('en'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !isUrdu
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'EN',
                                  style: TextStyle(
                                    color: !isUrdu
                                        ? Colors.white
                                        : context.mutedColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(languageProvider.notifier)
                                  .setLanguage('ur'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isUrdu
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'اردو',
                                  style: TextStyle(
                                    color: isUrdu
                                        ? Colors.white
                                        : context.mutedColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Dark Mode Toggle
                  GestureDetector(
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setThemeMode(
                              isDark ? ThemeMode.light : ThemeMode.dark,
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
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
                    title: 'Customer Support',
                    onTap: () async {
                      context.pop();
                      final uri = Uri.parse('tel:+923000000000');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () async {
                      context.pop();
                      final uri = Uri.parse('https://skillbridge.pk/terms');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
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
                  const Divider(indent: 16, endIndent: 16),
                  _DrawerTile(
                    icon: Icons.engineering_rounded,
                    title: 'Join as a Professional',
                    subtitle: 'Start earning today — it\'s free',
                    onTap: () {
                      context.pop();
                      context.push(RouteNames.signupPath);
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
                    'Skill Bridge v1.0.0 • Made in Pakistan 🇵🇰',
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
