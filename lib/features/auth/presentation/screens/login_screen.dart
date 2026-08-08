import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/validators.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';

/// Guild Modernist Login Screen adapted to match Karsaaz layout
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginViewModelProvider.notifier).login(
          email: _mobileController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(loginViewModelProvider.notifier).clearError();
      }
    });

    final state = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEDF4F9), // Light blue-gray background matching Karsaaz
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.xl),
                // ── Logo & Header ───────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Karsaaz-like human shape logo in our primary colors
                      Icon(
                        Icons.engineering_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'SKILL BRIDGE',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.onSurface,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 48),

                // ── Mobile Number Field ─────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black45, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.phone_android_rounded, color: Colors.black54),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.black26,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Mobile Number',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) => Validators.required(value, fieldName: 'Mobile Number'),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: 16),

                // ── Password Field ──────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black45, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.lock_outline_rounded, color: Colors.black54),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.black26,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: Icon(Icons.visibility_off, color: Colors.black54),
                          ),
                          validator: (value) => Validators.required(value, fieldName: 'Password'),
                          onFieldSubmitted: (_) => _onLogin(),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 200.ms, duration: 500.ms),
                const SizedBox(height: 12),

                // ── Remember Me & Forgot Password ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() => _rememberMe = val ?? true);
                          },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        Text(
                          'Remember Me',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteNames.forgotPasswordPath),
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 250.ms, duration: 500.ms),
                const SizedBox(height: 16),

                // ── Login Button ────────────────────────────────────────────
                AppButton(
                  text: 'LOGIN',
                  onPressed: state.isLoading ? null : _onLogin,
                  isLoading: state.isLoading,
                ).animate().fade(delay: 300.ms, duration: 500.ms),
                const SizedBox(height: 16),

                // ── OR Separator ────────────────────────────────────────────
                Center(
                  child: Text(
                    'OR',
                    style: AppTextStyles.labelCaption.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ).animate().fade(delay: 350.ms, duration: 500.ms),
                const SizedBox(height: 16),

                // ── Register Button ─────────────────────────────────────────
                OutlinedButton(
                  onPressed: () => context.push(RouteNames.signupPath),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                  child: Text(
                    'Register',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().fade(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: 32),

                // ── Social Login ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black26)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Login using social account',
                        style: AppTextStyles.labelCaption.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ).animate().fade(delay: 450.ms, duration: 500.ms),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 36, color: Colors.white),
                  label: Text(
                    'CONTINUE WITH GOOGLE',
                    style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                ).animate().fade(delay: 500.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
