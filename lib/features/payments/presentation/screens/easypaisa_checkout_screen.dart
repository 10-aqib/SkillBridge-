import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

class EasyPaisaCheckoutScreen extends StatelessWidget {
  final String jobId;
  final double amount;
  final String workerName;

  const EasyPaisaCheckoutScreen({
    super.key,
    required this.jobId,
    required this.amount,
    required this.workerName,
  });

  @override
  Widget build(BuildContext context) {
    const easyPaisaGreen = Color(0xFF00B74F);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: easyPaisaGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Payment status',
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: easyPaisaGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'easypaisa',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment is not available yet',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Divider(height: 30),
                    Text(
                      'No payment was taken. EasyPaisa is awaiting secure provider setup.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Worker', style: AppTextStyles.bodyMedium),
                        Flexible(
                          child: Text(
                            workerName,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.bodyStrong,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount', style: AppTextStyles.bodyMedium),
                        Text(
                          'Rs. ${amount.toInt()}',
                          style: AppTextStyles.heading3.copyWith(
                            color: easyPaisaGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Booking reference',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Flexible(
                          child: Text(
                            jobId,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Back to booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
