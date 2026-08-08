import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Guild Modernist Worker 7-Day Earnings & Escrow Performance Chart
class WorkerEarningsChart extends StatelessWidget {
  const WorkerEarningsChart({super.key});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final earnings = [3200, 4500, 2100, 5800, 3900, 6200, 4800];
    final maxEarning = 6200;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      shadow: AppShadows.level1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Earnings • ہفتہ وار آمدنی',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. 30,500',
                    style: AppTextStyles.heading2.copyWith(
                      color: const Color(0xFF005438),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF005438).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: Color(0xFF005438),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Escrow Protected',
                      style: AppTextStyles.labelCaption.copyWith(
                        color: const Color(0xFF005438),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Bar Chart Visualizer
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final amount = earnings[index];
                final heightFactor = amount / maxEarning;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(amount / 1000).toStringAsFixed(1)}k',
                      style: AppTextStyles.labelCaption.copyWith(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 26,
                      height: 80 * heightFactor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF005438),
                            const Color(0xFF005438).withValues(alpha: 0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: AppTextStyles.labelSmall.copyWith(
                        color: index == 6
                            ? const Color(0xFF005438)
                            : AppColors.onSurfaceVariant,
                        fontWeight:
                            index == 6 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppDimensions.lg),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppDimensions.md),

          // Stats summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Avg Job Ticket',
                value: 'Rs. 2,450',
                icon: Icons.receipt_long_rounded,
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.outlineVariant,
              ),
              _buildStatItem(
                label: 'On-Time Signoff',
                value: '98.4%',
                icon: Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF005438)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.labelCaption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
