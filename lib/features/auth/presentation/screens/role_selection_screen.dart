import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';

/// Guild Modernist Role Selection Screen (a2_role_selection)
/// Features 16px Level 2 cards with 4px left color-coded accent borders
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String _selectedRole = 'client';
  bool _isLoading = false;

  void _onRoleSelected() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ref
        .read(updateUserRoleUseCaseProvider)
        .call(uid: user.uid, role: _selectedRole);

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (_) {
          // The authStateProvider will emit the updated user role and
          // router will automatically redirect to the correct home screen.
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (Sora + Inter) ─────────────────────────────────────
              Text(
                'I am a...',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(duration: 500.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutQuad,
                  ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Select your role in the Guild marketplace • اپنا کردار منتخب کریں',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 100.ms, duration: 500.ms),
              const SizedBox(height: AppDimensions.xl),

              // ── Role Cards (Guild Modernist 4px Left Accent) ─────────────
              Expanded(
                child: Column(
                  children: [
                    _RoleSelectionCard(
                      title: 'Client • کلائنٹ',
                      subtitle: 'I want to hire verified skilled pros for projects in Pakistan.',
                      icon: Icons.business_center_rounded,
                      accentColor: AppColors.tertiaryContainer, // Green accent
                      iconBgColor: AppColors.tertiary.withValues(alpha: 0.12),
                      iconColor: AppColors.tertiary,
                      isSelected: _selectedRole == 'client',
                      onTap: () => setState(() => _selectedRole = 'client'),
                    ).animate().fade(delay: 150.ms, duration: 500.ms),
                    const SizedBox(height: AppDimensions.md),
                    _RoleSelectionCard(
                      title: 'Worker • کاریگر',
                      subtitle: 'I want to offer my trade skills, earn PKR, and build trust.',
                      icon: Icons.handyman_rounded,
                      accentColor: AppColors.primary, // Blue accent
                      iconBgColor: AppColors.blueTint,
                      iconColor: AppColors.primary,
                      isSelected: _selectedRole == 'worker',
                      onTap: () => setState(() => _selectedRole = 'worker'),
                    ).animate().fade(delay: 200.ms, duration: 500.ms),
                  ],
                ),
              ),

              // ── Continue Button (52px Primary) ───────────────────────────
              AppButton(
                text: 'Continue • آگے بڑھیں',
                onPressed: _isLoading ? null : _onRoleSelected,
                isLoading: _isLoading,
                width: double.infinity,
              ).animate().fade(delay: 250.ms, duration: 500.ms),
              const SizedBox(height: AppDimensions.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color iconBgColor;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: isSelected ? AppShadows.level3 : AppShadows.level2,
          border: Border.all(
            color: isSelected ? accentColor : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 4px Left Accent Bar
                Container(
                  width: 4,
                  color: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: AppTextStyles.bodyPrimary.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
