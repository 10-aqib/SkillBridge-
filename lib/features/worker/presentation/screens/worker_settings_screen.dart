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
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';

/// Guild Modernist Worker Settings Screen
class WorkerSettingsScreen extends ConsumerWidget {
  WorkerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textColor),
        title: Text(
          AppL10n.select(context, en: 'Settings', ur: 'ترتیبات'),
          style: AppTextStyles.heading3.copyWith(
            color: context.textColor,
          ),
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
                    child: Icon(
                      Icons.dark_mode_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    AppL10n.select(context, en: 'Dark Mode', ur: 'ڈارک موڈ'),
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
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.successGreen,
                    ),
                  ),
                  title: Text(
                    AppL10n.select(context, en: 'Customer Support', ur: 'کسٹمر سپورٹ'),
                    style: AppTextStyles.bodyStrong.copyWith(color: context.textColor),
                  ),
                  subtitle: Text(
                    AppL10n.select(context, en: 'Chat on WhatsApp', ur: 'واٹس ایپ پر رابطہ کریں'),
                    style: AppTextStyles.bodyPrimary.copyWith(fontSize: 13),
                  ),
                  onTap: () {
                    SupportUtils.showSupportOptions(context);
                  },
                ),
                Divider(height: 1, color: context.borderColor),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blueTint,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    AppL10n.select(context, en: 'Terms & Conditions', ur: 'شرائط و ضوابط'),
                    style: AppTextStyles.bodyStrong.copyWith(color: context.textColor),
                  ),
                  onTap: () {
                    context.push(RouteNames.termsAndConditionsPath);
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
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorRed,
                ),
              ),
              title: Text(
                AppL10n.select(context, en: 'Sign Out', ur: 'لاگ آؤٹ'),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
              onTap: () {
                ref.read(signOutUseCaseProvider).call();
              },
            ),
          ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }
}
