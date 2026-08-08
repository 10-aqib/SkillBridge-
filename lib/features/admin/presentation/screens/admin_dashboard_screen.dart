import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/admin/presentation/providers/admin_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Guild Modernist Admin Dashboard Screen
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsStreamProvider);
    final currencyFormatter =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Admin Console • ایڈمن پینل',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.onSurfaceVariant),
            onPressed: () {
              ref.read(signOutUseCaseProvider).call();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview • سسٹم جائزہ',
              style:
                  AppTextStyles.heading2.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppDimensions.lg),

            statsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading live metrics: $err',
                  style: AppTextStyles.bodyPrimary
                      .copyWith(color: AppColors.errorRed),
                ),
              ),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.md,
                crossAxisSpacing: AppDimensions.md,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    title: 'Total Users • صارفین',
                    value: '${stats.totalUsers}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'Workers • کاریگر',
                    value: '${stats.activeWorkers}',
                    icon: Icons.engineering_outlined,
                    color: AppColors.warningOrange,
                  ),
                  _StatCard(
                    title: 'Clients • کلائنٹس',
                    value: '${stats.activeClients}',
                    icon: Icons.business_center_outlined,
                    color: AppColors.successGreen,
                  ),
                  _StatCard(
                    title: 'Total Jobs • کام',
                    value: '${stats.totalJobs}',
                    icon: Icons.work_outline_rounded,
                    color: AppColors.primaryLight,
                  ),
                  _StatCard(
                    title: 'Contracts • معاہدے',
                    value: '${stats.activeContracts}',
                    icon: Icons.assignment_outlined,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'Gross Volume (PKR)',
                    value: currencyFormatter.format(stats.totalRevenue),
                    icon: Icons.payments_outlined,
                    color: AppColors.errorRed,
                  ),
                  _StatCard(
                    title: 'Commission (10%)',
                    value: currencyFormatter.format(stats.totalCommission),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.successGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            Text(
              'Quick Actions • فوری اقدامات',
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppDimensions.md),

            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    shadow: AppShadows.level1,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.supervised_user_circle_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Text(
                          'Manage Users • صارفین',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        AppButton(
                          text: 'View Users',
                          width: double.infinity,
                          onPressed: () {
                            context.push(RouteNames.adminUsersPath);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    shadow: AppShadows.level1,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.work_history_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Text(
                          'Manage Jobs • کام',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        AppButton(
                          text: 'View Jobs',
                          width: double.infinity,
                          onPressed: () {
                            context.push(RouteNames.adminJobsPath);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fade(delay: 200.ms, duration: 350.ms),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      shadow: AppShadows.level1,
      leftAccentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelCaption.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.dataNumeric.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 350.ms);
  }
}
