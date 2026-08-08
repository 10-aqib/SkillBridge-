import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';

/// Structured AI diagnosis returned from photo analysis
class AiPhotoDiagnosisResult {
  final String detectedFault;
  final String recommendedCategory;
  final String suggestedSpareParts;
  final int minPkr;
  final int maxPkr;

  AiPhotoDiagnosisResult({
    required this.detectedFault,
    required this.recommendedCategory,
    required this.suggestedSpareParts,
    required this.minPkr,
    required this.maxPkr,
  });
}

/// Guild Modernist AI Photo Diagnostic Modal ("Snap & Estimate")
/// Simulates Gemini Multimodal Vision AI to diagnose home repair issues from photos.
class AiPhotoDiagnosticModal extends StatefulWidget {
  const AiPhotoDiagnosticModal({super.key});

  /// Show dialog and return diagnosis result if accepted.
  static Future<AiPhotoDiagnosisResult?> show(BuildContext context) {
    return showDialog<AiPhotoDiagnosisResult>(
      context: context,
      builder: (ctx) => const AiPhotoDiagnosticModal(),
    );
  }

  @override
  State<AiPhotoDiagnosticModal> createState() => _AiPhotoDiagnosticModalState();
}

class _AiPhotoDiagnosticModalState extends State<AiPhotoDiagnosticModal> {
  bool _isAnalyzing = false;
  bool _hasResult = false;
  late AiPhotoDiagnosisResult _diagnosis;

  void _runPhotoDiagnosis() {
    setState(() {
      _isAnalyzing = true;
      _hasResult = false;
    });
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
        _diagnosis = AiPhotoDiagnosisResult(
          detectedFault: 'Breaker Overload & Burnt Main Wiring Terminal',
          recommendedCategory: 'Electrician',
          suggestedSpareParts: '32A MCB Breaker, 4mm Pakistan Cables Copper Wire, Insulation Tape',
          minPkr: 1800,
          maxPkr: 4500,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      backgroundColor: AppColors.surfaceWhite,
      title: Row(
        children: [
          const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI Photo Diagnose • تصویر سے تشخیص',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snap a photo of the broken AC, plumbing leak, or wiring fault. Our Gemini Vision AI will diagnose the issue and suggest fair Pakistani market rates.',
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            GestureDetector(
              onTap: _runPhotoDiagnosis,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: _isAnalyzing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Analyzing with Gemini Vision AI...'),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to Snap / Upload Photo',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_hasResult) ...[
              const SizedBox(height: AppDimensions.lg),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF005438).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: const Color(0xFF005438)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Diagnostic Analysis:',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF005438),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fault: ${_diagnosis.detectedFault}\n'
                      'Category: ${_diagnosis.recommendedCategory}\n'
                      'Parts: ${_diagnosis.suggestedSpareParts}\n'
                      'Fair PKR Estimate: Rs. ${_diagnosis.minPkr} – Rs. ${_diagnosis.maxPkr}',
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        if (_hasResult)
          AppButton(
            text: 'Apply AI Diagnosis',
            onPressed: () => Navigator.of(context).pop(_diagnosis),
            type: AppButtonType.solid,
            isSmall: true,
          ),
      ],
    );
  }
}
