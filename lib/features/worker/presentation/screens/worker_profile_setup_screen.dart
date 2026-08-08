import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_chip.dart';
import 'package:skill_bridge/shared/widgets/app_text_field.dart';

/// Guild Modernist Worker Profile Setup Screen
class WorkerProfileSetupScreen extends ConsumerStatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  ConsumerState<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState
    extends ConsumerState<WorkerProfileSetupScreen> {
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _cnicController = TextEditingController();

  String _selectedCategory = 'Electrician';
  String _selectedCity = 'Lahore';
  final List<String> _selectedSkills = ['Wiring'];
  String _selectedResponseTime = 'Within 1 hour';
  final List<String> _selectedLanguages = ['Urdu', 'English'];
  bool _isLoading = false;

  final List<String> _availableCategories = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mechanic',
    'Home Tutor',
    'AC Technician',
    'Cleaner',
    'Mason',
  ];

  final List<String> _availableSkills = [
    'Wiring',
    'Circuit Repair',
    'Generator Setup',
    'Solar Inverter',
    'Pipe Fitting',
    'Sanitary Repair',
    'Wood Furniture',
    'Wall Paint',
  ];

  final List<String> _availableResponseTimes = [
    'Within 1 hour',
    'Within 2 hours',
    'Within 4 hours',
    'Same day',
    'Within 24 hours',
  ];

  final List<String> _availableLanguages = [
    'Urdu',
    'English',
    'Punjabi',
    'Sindhi',
    'Pashto',
    'Balochi',
  ];

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final hourlyRate =
            int.tryParse(_hourlyRateController.text.trim()) ?? 1500;
        final cnic = _cnicController.text.trim();
        final existingMap = user.workerProfile != null
            ? {
                'headline': user.workerProfile!.headline,
                'bio': user.workerProfile!.bio,
                'categoryId': user.workerProfile!.categoryId,
                'categoryName': user.workerProfile!.categoryName,
                'skills': user.workerProfile!.skills,
                'experience': user.workerProfile!.experience,
                'hourlyRate': user.workerProfile!.hourlyRate,
                'dailyRate': user.workerProfile!.dailyRate,
                'certifications': user.workerProfile!.certifications,
                'portfolioImages': user.workerProfile!.portfolioImages,
                'availability': user.workerProfile!.availability,
                'isVerified': user.workerProfile!.isVerified,
                'verificationDocUrl': user.workerProfile!.verificationDocUrl,
                'city': user.workerProfile!.city,
                'address': user.workerProfile!.address,
                'serviceRadius': user.workerProfile!.serviceRadius,
                'totalJobsCompleted': user.workerProfile!.totalJobsCompleted,
                'totalEarnings': user.workerProfile!.totalEarnings,
                'averageRating': user.workerProfile!.averageRating,
                'totalReviews': user.workerProfile!.totalReviews,
                'coverImage': user.workerProfile!.coverImage,
                'languages': user.workerProfile!.languages,
                'responseTime': user.workerProfile!.responseTime,
                'beforeAfterImages': user.workerProfile!.beforeAfterImages,
              }
            : <String, dynamic>{};

        final data = <String, dynamic>{
          if (cnic.isNotEmpty) 'cnicNumber': cnic,
          if (cnic.isNotEmpty) 'isCnicVerified': false,
          'city': _selectedCity,
          'workerProfile': {
            ...existingMap,
            'categoryId': _selectedCategory.toLowerCase(),
            'categoryName': _selectedCategory,
            'headline': _headlineController.text.trim(),
            'bio': _bioController.text.trim(),
            'hourlyRate': hourlyRate,
            'skills': _selectedSkills,
            'city': _selectedCity,
            'availability': 'available',
            'languages': _selectedLanguages,
            'responseTime': _selectedResponseTime,
          },
        };
        await ref.read(updateUserProfileUseCaseProvider).call(
              uid: user.uid,
              data: data,
            );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go(RouteNames.workerHomePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Setup Worker Profile • کاریگر پروفائل',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete your Profile • پروفائل مکمل کریں',
              style: AppTextStyles.headlineLg.copyWith(
                color: AppColors.onSurface,
              ),
            ).animate().fade(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Tell clients about your expertise so you can get hired faster.',
              style: AppTextStyles.bodyPrimary.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ).animate().fade(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.xl),

            // ── Professional Headline ───────────────────────────────────────
            AppTextField(
              controller: _headlineController,
              labelText: 'Professional Headline • پیشہ ورانہ عنوان',
              hintText: 'e.g. Master Electrician with 5+ Years Experience',
            ).animate().fade(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── Category Dropdown ───────────────────────────────────────────
            Text(
              'Primary Category • زمرہ',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.primary),
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.onSurface,
                  ),
                  items: _availableCategories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ).animate().fade(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── Hourly Rate (PKR) ───────────────────────────────────────────
            AppTextField(
              controller: _hourlyRateController,
              labelText: 'Hourly Rate (PKR) • فی گھنٹہ ریٹ',
              hintText: 'e.g. 800',
              keyboardType: TextInputType.number,
            ).animate().fade(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── City Dropdown ───────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: 'City • شہر',
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceWhite,
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
            ).animate().fade(delay: 270.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── CNIC Number (Optional) ──────────────────────────────────────
            AppTextField(
              controller: _cnicController,
              labelText: 'CNIC Number (Optional) • شناختی کارڈ نمبر',
              hintText: '35202-1234567-1',
              keyboardType: TextInputType.number,
            ).animate().fade(delay: 290.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── Bio ─────────────────────────────────────────────────────────
            AppTextField(
              controller: _bioController,
              labelText: 'About / Bio • تعارف',
              hintText:
                  'Describe your work experience, tools, and specialty...',
              maxLines: 3,
            ).animate().fade(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.xl),

            // ── Select Skills (Using AppChip) ───────────────────────────────
            Text(
              'Select Skills • مہارتیں منتخب کریں',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSkills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return AppChip(
                  label: skill,
                  isSelected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (isSelected) {
                        _selectedSkills.remove(skill);
                      } else {
                        _selectedSkills.add(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ).animate().fade(delay: 350.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.xl),

            // ── Select Languages (Using AppChip) ────────────────────────────
            Text(
              'Languages • زبانیں',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLanguages.map((lang) {
                final isSelected = _selectedLanguages.contains(lang);
                return AppChip(
                  label: lang,
                  isSelected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (isSelected && _selectedLanguages.length > 1) {
                        _selectedLanguages.remove(lang);
                      } else if (!isSelected) {
                        _selectedLanguages.add(lang);
                      }
                    });
                  },
                );
              }).toList(),
            ).animate().fade(delay: 370.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.xl),

            // ── Response Time Dropdown ───────────────────────────────────────
            Text(
              'Average Response Time • جواب دینے کا وقت',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedResponseTime,
                  isExpanded: true,
                  icon: const Icon(Icons.access_time_rounded,
                      color: AppColors.primary),
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.onSurface,
                  ),
                  items: _availableResponseTimes
                      .map((rt) => DropdownMenuItem(
                            value: rt,
                            child: Text(rt),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedResponseTime = val);
                    }
                  },
                ),
              ),
            ).animate().fade(delay: 390.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.space48),

            // ── Submit Button ───────────────────────────────────────────────
            AppButton(
              text: 'Save & Continue • محفوظ کریں اور آگے بڑھیں',
              onPressed: _isLoading ? null : _submitProfile,
              isLoading: _isLoading,
              width: double.infinity,
            ).animate().fade(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.space48),
          ],
        ),
      ),
    );
  }
}
