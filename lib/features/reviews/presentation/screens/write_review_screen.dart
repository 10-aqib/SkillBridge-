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

  const WriteReviewScreen({
    super.key,
    required this.contract,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;
  final List<String> _attachedPhotos = [];

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
      final reviewerName =
          isClient ? widget.contract.clientName : widget.contract.workerName;
      final reviewerPhotoUrl = isClient
          ? widget.contract.clientPhotoUrl
          : widget.contract.workerPhotoUrl;
      final revieweeId =
          isClient ? widget.contract.workerId : widget.contract.clientId;
      final revieweeName =
          isClient ? widget.contract.workerName : widget.contract.clientName;

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
        isVerifiedCustomer: true, // They are reviewing from a contract
        photos: _attachedPhotos,
      );

      await ref.read(reviewRemoteDataSourceProvider).submitReview(
            review: review,
            isClientReview: isClient,
          );

      if (mounted) {
        context.showSnackBar('Review submitted successfully! • رائے درج ہو گئی');
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
    final revieweeName =
        isClient ? widget.contract.workerName : widget.contract.clientName;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Write a Review • رائے لکھیں',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.xl),
              shadow: AppShadows.level1,
              child: Column(
                children: [
                  Text(
                    'How was your experience with • آپ کا تجربہ کیسا رہا',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revieweeName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.onSurface,
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
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
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
              labelText: 'Feedback / Comment • تاثرات',
              hintText: 'Share details of your experience...',
              maxLines: 4,
            ),
            const SizedBox(height: AppDimensions.xl),

            // Mock Photo Attachment UI
            Text(
              'Attach Photos (Optional) • تصاویر شامل کریں',
              style: AppTextStyles.labelCaption,
            ),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: [
                ..._attachedPhotos.map((url) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -8,
                          top: -8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _attachedPhotos.remove(url);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.errorRed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                if (_attachedPhotos.length < 3)
                  GestureDetector(
                    onTap: () {
                      // Mocking photo upload for now
                      setState(() {
                        _attachedPhotos.add('https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200');
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: AppColors.borderGray,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Submit Button
            AppButton(
              text: 'Submit Review • رائے جمع کریں',
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
