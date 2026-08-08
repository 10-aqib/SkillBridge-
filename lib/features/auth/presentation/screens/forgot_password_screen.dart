import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/validators.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_text_field.dart';

/// Guild Modernist Forgot Password Screen
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(forgotPasswordViewModelProvider.notifier)
        .sendResetEmail(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordViewModelProvider,
        (prev, next) {
      if (next.emailSent && !(prev?.emailSent ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: AppColors.tertiary, // Skill Green
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(forgotPasswordViewModelProvider.notifier).reset();
        context.pop();
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
        ref.read(forgotPasswordViewModelProvider.notifier).clearError();
      }
    });

    final state = ref.watch(forgotPasswordViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onSurface,
            size: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon Box (White 16px Radius + Primary Icon) ─────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().fade(duration: 600.ms).scale(
                    duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: AppDimensions.xl),

                // ── Header (Sora + Inter) ───────────────────────────────────
                Text(
                  'Reset Password • پاس ورڈ ری سیٹ کریں',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                ).animate().fade(delay: 100.ms, duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  'Enter your email address and we will send you a secure link to reset your password.',
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ).animate().fade(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.xl),

                // ── Email Field ─────────────────────────────────────────────
                AppTextField(
                  controller: _emailController,
                  labelText: 'Email Address • ای میل',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onResetPassword(),
                  validator: (value) => Validators.email(value),
                ).animate().fade(delay: 200.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.xl),

                // ── Reset Button (52px Primary) ─────────────────────────────
                AppButton(
                  text: 'Send Reset Link • ری سیٹ لنک بھیجیں',
                  onPressed: state.isLoading ? null : _onResetPassword,
                  isLoading: state.isLoading,
                  width: double.infinity,
                ).animate().fade(delay: 250.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
