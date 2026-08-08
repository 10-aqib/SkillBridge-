import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Guild Modernist Splash Screen (a1_splash_screen)
/// Features Navy mesh gradient, white 24px logo box with "S" lettermark, Sora wordmark
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Wait for a short duration for branding
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      context.go(RouteNames.loginPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF001E60),
              AppColors.primary,
              AppColors.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // White 24px Logo Box with Lettermark
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'S',
                        style: AppTextStyles.displayHero.copyWith(
                          color: AppColors.primary,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 18,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary, // Skill Green
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: AppColors.onTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fade(duration: 700.ms)
                  .scale(duration: 700.ms, curve: Curves.easeOutBack)
                  .then(delay: 200.ms)
                  .shimmer(duration: 1.seconds, color: AppColors.blueTint.withValues(alpha: 0.3)),
              const SizedBox(height: AppDimensions.lg),
              // Wordmark (Sora)
              Text(
                'Skill Bridge',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.surfaceWhite,
                  letterSpacing: 0.5,
                ),
              ).animate().fade(delay: 250.ms, duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOutQuad,
                  ),
              const SizedBox(height: AppDimensions.sm),
              // Bilingual Tagline (Inter)
              Text(
                'Connecting Skills. Building Trust. • ہنر کا اعتماد',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.onPrimaryContainer,
                  fontSize: 14,
                ),
              ).animate().fade(delay: 450.ms, duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOutQuad,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
