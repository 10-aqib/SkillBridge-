import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/utils/validators.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_text_field.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

/// Guild Modernist Registration Step 1 (a3_registration_step_1)
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'client';
  String _selectedCity = 'Lahore';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;

    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+92${phone.replaceAll(RegExp(r'^0'), '')}';
    }

    ref.read(registerViewModelProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          phoneNumber: phone,
          role: _selectedRole,
          city: _selectedCity,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterState>(registerViewModelProvider, (prev, next) {
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        final phone = _phoneController.text.trim();
        String formatted = phone.startsWith('+')
            ? phone
            : '+92${phone.replaceAll(RegExp(r'^0'), '')}';
        context.push(RouteNames.otpPath, extra: formatted);
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
        ref.read(registerViewModelProvider.notifier).clearError();
      }
    });

    final state = ref.watch(registerViewModelProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back Button ─────────────────────────────────────────────
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: context.textColor,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: context.surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      side: BorderSide(
                        color: context.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // ── Header (Sora) ───────────────────────────────────────────
                Text(
                  AppL10n.select(context, en: 'Create Account', ur: 'اکاؤنٹ بنائیں'),
                  style: AppTextStyles.headlineLg.copyWith(
                    color: context.textColor,
                  ),
                ).animate().fade(duration: 500.ms).slideY(
                      begin: 0.2,
                      end: 0,
                      curve: Curves.easeOutQuad,
                    ),
                const SizedBox(height: 4),
                Text(
                  'Join Skill Bridge — verified Pakistani trades & clients',
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: context.mutedColor,
                  ),
                ).animate().fade(delay: 100.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.lg),

                // ── Role Selection Toggle ───────────────────────────────────
                Text(
                  'I am joining as:',
                  style: AppTextStyles.labelCaption.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        label: 'Client (Hire)',
                        icon: Icons.business_center_rounded,
                        isSelected: _selectedRole == 'client',
                        onTap: () => setState(() => _selectedRole = 'client'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: _RoleCard(
                        label: 'Worker (Work)',
                        icon: Icons.handyman_rounded,
                        isSelected: _selectedRole == 'worker',
                        onTap: () => setState(() => _selectedRole = 'worker'),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.lg),

                // ── Form Fields (12px radius, Inter) ────────────────────────
                AppTextField(
                  controller: _nameController,
                  labelText: AppL10n.select(context, en: 'Full Name', ur: 'پورا نام'),
                  hintText: 'e.g. Tariq Mahmood',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ).animate().fade(delay: 200.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),

                AppTextField(
                  controller: _emailController,
                  labelText: AppL10n.select(context, en: 'Email Address', ur: 'ای میل'),
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.email(value),
                ).animate().fade(delay: 250.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),

                AppTextField(
                  controller: _phoneController,
                  labelText: AppL10n.select(context, en: 'Phone Number', ur: 'فون نمبر'),
                  hintText: '300 1234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.phone(value),
                ).animate().fade(delay: 300.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),

                // ── City Dropdown ───────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: InputDecoration(
                    labelText: AppL10n.select(context, en: 'Default City', ur: 'شہر'),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: context.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                  ),
                  items: PakistanConstants.majorCities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city, style: AppTextStyles.bodyPrimary),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCity = val);
                  },
                ).animate().fade(delay: 320.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),

                AppTextField(
                  controller: _passwordController,
                  labelText: AppL10n.select(context, en: 'Password', ur: 'پاس ورڈ'),
                  hintText: 'Min 8 chars, 1 number',
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.password(value),
                ).animate().fade(delay: 350.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),

                AppTextField(
                  controller: _confirmPasswordController,
                  labelText: AppL10n.select(context, en: 'Confirm Password', ur: 'پاس ورڈ کی تصدیق'),
                  hintText: 'Re-enter password',
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onSubmitted: (_) => _onRegister(),
                ).animate().fade(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.xl),

                // ── Register Button ─────────────────────────────────────────
                AppButton(
                  text: AppL10n.select(context, en: 'Create Account', ur: 'اکاؤنٹ بنائیں'),
                  onPressed: state.isLoading ? null : _onRegister,
                  isLoading: state.isLoading,
                  width: double.infinity,
                ).animate().fade(delay: 450.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),

                // ── Login Link ──────────────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: context.mutedColor,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: 500.ms, duration: 500.ms),
                const SizedBox(height: AppDimensions.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.md,
          horizontal: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: isSelected ? AppShadows.level2 : const [],
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : context.borderColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? context.surfaceColor : context.mutedColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelCaption.copyWith(
                color: isSelected ? context.surfaceColor : context.textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
