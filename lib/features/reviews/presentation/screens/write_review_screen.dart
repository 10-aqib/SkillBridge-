import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/features/reviews/data/models/review_model.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_text_field.dart';

/// Guild Modernist Write Review Screen
class WriteReviewScreen extends ConsumerStatefulWidget {
  final ContractEntity contract;

  const WriteReviewScreen({super.key, required this.contract});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final isClient = user.uid == widget.contract.clientId;
      final reviewerName = isClient
          ? widget.contract.clientName
          : widget.contract.workerName;
      final reviewerPhotoUrl = isClient
          ? widget.contract.clientPhotoUrl
          : widget.contract.workerPhotoUrl;
      final revieweeId = isClient
          ? widget.contract.workerId
          : widget.contract.clientId;
      final revieweeName = isClient
          ? widget.contract.workerName
          : widget.contract.clientName;

      final review = ReviewModel(
        id: '',
        contractId: widget.contract.id,
        jobId: widget.contract.jobId,
        reviewerId: user.uid,
        reviewerName: reviewerName,
        reviewerPhotoUrl: reviewerPhotoUrl,
        revieweeId: revieweeId,
        revieweeName: revieweeName,
        rating: _rating,
        comment: _commentController.text.trim(),
        reviewType: isClient ? 'client_to_worker' : 'worker_to_client',
        createdAt: DateTime.now(),
        isVerifiedCustomer: true,
        photos: const [],
      );

      await ref
          .read(reviewRemoteDataSourceProvider)
          .submitReview(review: review, isClientReview: isClient)
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        context.showSnackBar(
          AppL10n.select(
            context,
            en: 'Review submitted successfully!',
            ur: 'رائے درج ہو گئی',
          ),
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isClient = user?.uid == widget.contract.clientId;
    final revieweeName = isClient
        ? widget.contract.workerName
        : widget.contract.clientName;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          AppL10n.select(context, en: 'Write a Review', ur: 'رائے لکھیں'),
          style: AppTextStyles.heading3.copyWith(color: context.textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: EdgeInsets.all(AppDimensions.xl),
              shadow: AppShadows.level1,
              child: Column(
                children: [
                  Text(
                    AppL10n.select(
                      context,
                      en: 'How was your experience with',
                      ur: 'آپ کا تجربہ کیسا رہا',
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    revieweeName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2.copyWith(
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // Rating Stars selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        iconSize: 44,
                        icon: Icon(
                          _rating >= starValue
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.warningOrange,
                        ),
                        onPressed: () {
                          setState(() => _rating = starValue);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Text(
                      'Rating: ${_rating.toInt()} / 5',
                      style: AppTextStyles.dataNumeric.copyWith(
                        color: AppColors.warningOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 350.ms),
            const SizedBox(height: AppDimensions.xl),

            // Comment textfield
            AppTextField(
              controller: _commentController,
              labelText: AppL10n.select(
                context,
                en: 'Feedback / Comment',
                ur: 'تاثرات',
              ),
              hintText: 'Share details of your experience...',
              maxLines: 4,
            ),
            const SizedBox(height: AppDimensions.xl),

            // Submit Button
            AppButton(
              text: AppL10n.select(
                context,
                en: 'Submit Review',
                ur: 'رائے جمع کریں',
              ),
              isLoading: _isLoading,
              onPressed: _submitReview,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
