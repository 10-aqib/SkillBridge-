import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/privacy_helpers.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';

/// Guild Modernist 4-Digit Job Completion Digital Sign-off Dialog
/// Provides secure in-person escrow sign-off between Client and Worker without requiring SMS fees.
class JobCompletionOtpDialog extends StatefulWidget {
  final String jobId;
  final bool isClient;

  const JobCompletionOtpDialog({
    super.key,
    required this.jobId,
    required this.isClient,
  });

  /// Show the dialog and return true if OTP sign-off succeeded.
  static Future<bool?> show({
    required BuildContext context,
    required String jobId,
    required bool isClient,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => JobCompletionOtpDialog(
        jobId: jobId,
        isClient: isClient,
      ),
    );
  }

  @override
  State<JobCompletionOtpDialog> createState() => _JobCompletionOtpDialogState();
}

class _JobCompletionOtpDialogState extends State<JobCompletionOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    final entered = _otpController.text.trim();
    if (entered.length != 4) {
      setState(() {
        _errorText = 'Please enter a 4-digit verification code';
      });
      return;
    }
    final isValid = PrivacyHelpers.verifyJobCompletionOtp(
      jobId: widget.jobId,
      inputOtp: entered,
    );
    if (isValid) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorText = 'Incorrect code. Please ask the client for their 4-digit code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedOtp = PrivacyHelpers.generateJobCompletionOtp(widget.jobId);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      backgroundColor: AppColors.surfaceWhite,
      title: Row(
        children: [
          Icon(
            widget.isClient ? Icons.shield_rounded : Icons.verified_user_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isClient
                  ? 'Job Sign-off Code • تصدیق کوڈ'
                  : 'Enter Completion Code • تصدیق درج کریں',
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
              widget.isClient
                  ? 'Share this 4-digit security code with the worker after you have inspected and approved the completed work:'
                  : 'Ask the client for their 4-digit security code to finalize this job and release escrow funds:',
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            if (widget.isClient) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Text(
                    expectedOtp,
                    style: AppTextStyles.dataNumericLg.copyWith(
                      fontSize: 36,
                      color: AppColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: expectedOtp));
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Security Code'),
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: AppTextStyles.dataNumericLg.copyWith(
                  fontSize: 28,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (!widget.isClient)
          AppButton(
            text: 'Verify & Complete Job',
            onPressed: _verifyOtp,
            type: AppButtonType.solid,
            isSmall: true,
          )
        else
          AppButton(
            text: 'Done',
            onPressed: () => Navigator.of(context).pop(true),
            type: AppButtonType.solid,
            isSmall: true,
          ),
      ],
    );
  }
}
