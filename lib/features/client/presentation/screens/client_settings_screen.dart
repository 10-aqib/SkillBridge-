import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Guild Modernist Client Settings Screen
class ClientSettingsScreen extends ConsumerWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          context.l10n.settings,
          style: AppTextStyles.heading3.copyWith(color: context.textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.sm,
              horizontal: AppDimensions.sm,
            ),
            shadow: AppShadows.level1,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blueTint,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    context.l10n.language,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: context.textColor,
                    ),
                  ),
                  subtitle: Text(
                    ref.watch(languageProvider).languageCode == 'ur'
                        ? 'اردو (RTL Mode Active)'
                        : 'English (LTR Mode Active)',
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      ref.watch(languageProvider).languageCode == 'ur'
                          ? 'اردو'
                          : 'EN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    ref.read(languageProvider.notifier).toggleLanguage();
                  },
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blueTint,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(
                      Icons.dark_mode_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    context.l10n.darkMode,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: context.textColor,
                    ),
                  ),
                  trailing: Switch(
                    value: ref.watch(themeModeProvider) == ThemeMode.dark ||
                        context.isDark,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: AppDimensions.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.sm,
              horizontal: AppDimensions.sm,
            ),
            shadow: AppShadows.level1,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.successGreen,
                    ),
                  ),
                  title: Text(
                    context.l10n.customerSupport,
                    style: AppTextStyles.bodyStrong.copyWith(color: context.textColor),
                  ),
                  subtitle: Text(
                    context.l10n.chatOnWhatsApp,
                    style: AppTextStyles.bodyPrimary.copyWith(fontSize: 13),
                  ),
                  onTap: () async {
                    // Open WhatsApp
                    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=+923000000000");
                    if (await canLaunchUrl(whatsappUrl)) {
                      await launchUrl(whatsappUrl);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.whatsappNotInstalled),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blueTint,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    context.l10n.termsAndConditions,
                    style: AppTextStyles.bodyStrong.copyWith(color: context.textColor),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.surfaceColor,
                        title: Text(
                          context.l10n.termsAndConditions,
                          style: AppTextStyles.heading3.copyWith(color: context.textColor),
                        ),
                        content: SingleChildScrollView(
                          child: Text(
                            context.l10n.termsContent,
                            style: AppTextStyles.bodyPrimary.copyWith(color: context.textColor),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              context.l10n.close,
                              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fade(delay: 50.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: AppDimensions.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.sm,
              horizontal: AppDimensions.sm,
            ),
            shadow: AppShadows.level1,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorRed,
                ),
              ),
              title: Text(
                context.l10n.logout,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
              onTap: () {
                ref.read(signOutUseCaseProvider).call();
              },
            ),
          ).animate().fade(delay: 100.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
