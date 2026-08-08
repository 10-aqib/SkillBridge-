import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';

/// Guild Modernist OTP Verification Screen (a4_otp_verification)
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        if (mounted) {
          setState(() => _resendSeconds--);
        }
      }
    });
  }

  void _sendOtp() {
    ref
        .read(otpViewModelProvider.notifier)
        .sendOtp(phoneNumber: widget.phoneNumber);
  }

  void _resendOtp() {
    if (_resendSeconds > 0) return;
    _sendOtp();
    _startTimer();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _verifyOtp(otp);
    }
  }

  void _verifyOtp(String otp) {
    ref.read(otpViewModelProvider.notifier).verifyOtp(
          smsCode: otp,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OtpState>(otpViewModelProvider, (prev, next) {
      if (next.isVerified && !(prev?.isVerified ?? false)) {
        // Router will redirect upon auth status update
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(otpViewModelProvider.notifier).clearError();
      }
    });

    final state = ref.watch(otpViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back Button ─────────────────────────────────────────────
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.onSurface,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    side: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // ── Header (Sora + Inter) ─────────────────────────────────────
              Text(
                'Verify Phone • فون نمبر کی تصدیق',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ).animate().fade(duration: 500.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOutQuad,
                  ),
              const SizedBox(height: 4),
              Text(
                'We sent a 6-digit verification code to:\n${widget.phoneNumber}',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ).animate().fade(delay: 100.ms, duration: 500.ms),
              const SizedBox(height: AppDimensions.xl),

              // ── 6-Digit OTP Inputs (JetBrains Mono) ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return _OtpDigitField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onDigitChanged(index, value),
                    isLoading: state.isVerifying || state.isSending,
                  );
                }),
              ).animate().fade(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: AppDimensions.xl),

              // ── Verify Button (52px Primary) ───────────────────────────────
              AppButton(
                text: 'Verify Account • تصدیق کریں',
                onPressed: (state.isVerifying || state.isSending)
                    ? null
                    : () {
                        final otp = _controllers.map((c) => c.text).join();
                        if (otp.length == 6) {
                          _verifyOtp(otp);
                        }
                      },
                isLoading: state.isVerifying,
                width: double.infinity,
              ).animate().fade(delay: 300.ms, duration: 500.ms),
              const SizedBox(height: AppDimensions.lg),

              // ── Resend & Timer ─────────────────────────────────────────────
              if (state.isSending)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        'Sending OTP code...',
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: _resendSeconds == 0 ? _resendOtp : null,
                        child: Text(
                          _resendSeconds > 0
                              ? 'Resend in ${_resendSeconds}s'
                              : 'Resend Now',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: _resendSeconds > 0
                                ? AppColors.onSurfaceVariant
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: !isLoading,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.dataNumericLg.copyWith(
          color: AppColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasValue ? AppColors.blueTint : AppColors.surfaceWhite,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: hasValue ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(
              color: hasValue ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
