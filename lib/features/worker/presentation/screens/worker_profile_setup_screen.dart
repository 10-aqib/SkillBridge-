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
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/shared/widgets/location_picker_screen.dart';
import 'package:skill_bridge/core/utils/geohash_util.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> _selectedSkills = ['Wiring'];
  String _selectedResponseTime = 'Within 1 hour';
  final List<String> _selectedLanguages = ['English'];
  bool _isLoading = false;
  
  LocationResult? _pickedLocation;

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
    'English',
    'Urdu',
    'Punjabi',
    'Sindhi',
    'Pashto',
    'Balochi',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null && mounted) {
        if (user.cnicNumber != null && user.cnicNumber!.isNotEmpty) {
          _cnicController.text = user.cnicNumber!;
        }
        if (user.workerProfile != null) {
          final p = user.workerProfile!;
          setState(() {
            _headlineController.text = p.headline;
            _bioController.text = p.bio;
            if (p.hourlyRate > 0) {
              _hourlyRateController.text = p.hourlyRate.toInt().toString();
            }
            if (p.categoryName.isNotEmpty &&
                _availableCategories.contains(p.categoryName)) {
              _selectedCategory = p.categoryName;
            }
            if (p.address?.isNotEmpty == true) {
              _pickedLocation = LocationResult(
                latitude: p.location?.latitude ?? 0.0,
                longitude: p.location?.longitude ?? 0.0,
                formattedAddress: p.address ?? '',
                city: p.city,
                accuracy: LocationAccuracyLevel.unknown,
              );
            }
            if (p.skills.isNotEmpty) {
              _selectedSkills.clear();
              _selectedSkills.addAll(p.skills);
            }
            if (p.responseTime != null && p.responseTime!.isNotEmpty) {
              _selectedResponseTime = p.responseTime!;
            }
            if (p.languages.isNotEmpty) {
              _selectedLanguages.clear();
              _selectedLanguages.addAll(p.languages);
            }
          });
        }
      }
    });
  }

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
                'certifications': user.workerProfile!.certifications
                    .map((c) => {
                          'name': c.name,
                          'issuedBy': c.issuedBy,
                          'year': c.year,
                          if (c.imageUrl != null) 'imageUrl': c.imageUrl,
                        })
                    .toList(),
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
          if (_pickedLocation != null) 'city': _pickedLocation!.city,
          if (_pickedLocation != null) 'locationAddress': _pickedLocation!.formattedAddress,
          if (_pickedLocation != null) 'locationAccuracy': _pickedLocation!.accuracy.toString(),
          if (_pickedLocation != null) 'geohash': GeohashUtil.encode(_pickedLocation!.latitude, _pickedLocation!.longitude),
          if (_pickedLocation != null) 'location': GeoPoint(_pickedLocation!.latitude, _pickedLocation!.longitude),
          if (_pickedLocation != null) 'locationVisibility': 'public',
          
          'workerProfile': {
            ...existingMap,
            'categoryId': _selectedCategory.toLowerCase(),
            'categoryName': _selectedCategory,
            'headline': _headlineController.text.trim(),
            'bio': _bioController.text.trim(),
            'hourlyRate': hourlyRate,
            'skills': _selectedSkills,
            if (_pickedLocation != null) 'city': _pickedLocation!.city,
            if (_pickedLocation != null) 'address': _pickedLocation!.formattedAddress,
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          'Setup Worker Profile',
          style: AppTextStyles.heading3.copyWith(
            color: context.textColor,
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
              'Complete your Profile',
              style: AppTextStyles.headlineLg.copyWith(
                color: context.textColor,
              ),
            ).animate().fade(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Tell clients about your expertise so you can get hired faster.',
              style: AppTextStyles.bodyPrimary.copyWith(
                color: context.mutedColor,
              ),
            ).animate().fade(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.xl),

            // ── Professional Headline ───────────────────────────────────────
            AppTextField(
              controller: _headlineController,
              labelText: 'Professional Headline',
              hintText: 'e.g. Master Electrician with 5+ Years Experience',
            ).animate().fade(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── Category Dropdown ───────────────────────────────────────────
            Text(
              'Primary Category',
              style: AppTextStyles.bodyStrong.copyWith(
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.primary),
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: context.textColor,
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
              labelText: 'Hourly Rate (PKR)',
              hintText: 'e.g. 800',
              keyboardType: TextInputType.number,
            ).animate().fade(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── Service Location Picker ──────────────────────────────────────
            Text(
              'Service Location',
              style: AppTextStyles.bodyStrong.copyWith(
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<LocationResult>(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                );
                if (result != null) {
                  setState(() => _pickedLocation = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  color: context.surfaceColor,
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedLocation?.formattedAddress ?? 'Select your service location',
                        style: AppTextStyles.bodyPrimary.copyWith(
                          color: _pickedLocation == null ? context.mutedColor : context.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.borderGray),
                  ],
                ),
              ),
            ).animate().fade(delay: 270.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── CNIC Number (Optional) ──────────────────────────────────────
            AppTextField(
              controller: _cnicController,
              labelText: 'CNIC Number (Optional)',
              hintText: '35202-1234567-1',
              keyboardType: TextInputType.number,
            ).animate().fade(delay: 290.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.lg),

            // ── Bio ─────────────────────────────────────────────────────────
            AppTextField(
              controller: _bioController,
              labelText: 'About / Bio',
              hintText:
                  'Describe your work experience, tools, and specialty...',
              maxLines: 3,
            ).animate().fade(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.xl),

            // ── Select Skills (Using AppChip) ───────────────────────────────
            Text(
              'Select Skills',
              style: AppTextStyles.bodyStrong.copyWith(
                color: context.textColor,
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
              'Languages',
              style: AppTextStyles.bodyStrong.copyWith(
                color: context.textColor,
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
              'Average Response Time',
              style: AppTextStyles.bodyStrong.copyWith(
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedResponseTime,
                  isExpanded: true,
                  icon: const Icon(Icons.access_time_rounded,
                      color: AppColors.primary),
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: context.textColor,
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
              text: 'Save & Continue',
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
