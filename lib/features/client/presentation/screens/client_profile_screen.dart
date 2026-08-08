import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/reviews/data/datasources/review_remote_datasource.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Guild Modernist Client Profile Screen — fully functional edit profile
class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  File? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ImageSourceSheet(),
    );
    if (result == null) return;
    final picked = await picker.pickImage(
      source: result,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _openEditSheet() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _EditProfileSheet(
        initialName: user.displayName,
        initialEmail: user.email,
        initialPhone: user.phoneNumber,
        isUrdu: isUrdu,
        onSave: (name, email, phone, city) async {
          Navigator.pop(ctx);
          final useCase = ref.read(updateUserProfileUseCaseProvider);
          final result = await useCase(
            uid: user.uid,
            data: {
              'displayName': name,
              'email': email,
              'phoneNumber': phone,
              'city': city,
            },
          );
          result.fold(
            (failure) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isUrdu
                        ? 'خرابی: ${failure.message}'
                        : 'Error: ${failure.message}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isUrdu
                        ? '✅ پروفائل کامیابی سے اپڈیٹ ہوئی'
                        : '✅ Profile updated successfully!'),
                    backgroundColor: AppColors.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                // ── Light Premium Header ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 290,
                  pinned: true,
                  backgroundColor: context.surfaceColor,
                  foregroundColor: context.textColor,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.settings_rounded, color: context.textColor),
                      onPressed: () =>
                          context.push(RouteNames.clientSettingsPath),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.outlineVariant.withValues(alpha: 0.5),
                          )
                        )
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // ── Tappable Avatar with camera badge ──────────
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  _pickedImage != null
                                      ? CircleAvatar(
                                          radius: 55,
                                          backgroundImage:
                                              FileImage(_pickedImage!),
                                        )
                                      : Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppColors.surfaceContainerHigh, width: 4),
                                              boxShadow: AppShadows.level2,
                                            ),
                                            child: AppAvatar(
                                              name: user.displayName,
                                              imageUrl: user.photoUrl,
                                              size: 110,
                                            ),
                                          ).animate().scale(
                                              duration: 500.ms,
                                              curve: Curves.easeOutBack),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: AppShadows.level1,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.displayName,
                              style: AppTextStyles.heading2.copyWith(
                                color: context.textColor,
                              ),
                            ).animate().fade(delay: 100.ms, duration: 400.ms),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ).animate().fade(delay: 150.ms, duration: 400.ms),
                            const SizedBox(height: 16),
                            // ── Quick stats row ────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _HeroStat(
                                  value: '2',
                                  label: isUrdu ? 'کام' : 'Jobs',
                                ),
                                _heroDivider(),
                                _HeroStat(
                                  value: user.rating.toStringAsFixed(1),
                                  label: isUrdu ? 'ریٹنگ' : 'Rating',
                                ),
                                _heroDivider(),
                                _HeroStat(
                                  value: '${user.totalReviews}',
                                  label: isUrdu ? 'جائزے' : 'Reviews',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Profile Details Card ─────────────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(AppDimensions.lg),
                        shadow: AppShadows.level1,
                        child: Column(
                          children: [
                            _ProfileDetailRow(
                              icon: Icons.person_outline_rounded,
                              title: isUrdu ? 'پورا نام' : 'Full Name',
                              value: user.displayName,
                            ),
                            const Divider(
                                height: 24,
                                color: AppColors.outlineVariant),
                            _ProfileDetailRow(
                              icon: Icons.phone_outlined,
                              title:
                                  isUrdu ? 'فون نمبر' : 'Phone Number',
                              value: user.phoneNumber.isEmpty
                                  ? (isUrdu ? 'شامل نہیں' : 'Not added')
                                  : user.phoneNumber,
                            ),
                            const Divider(
                                height: 24,
                                color: AppColors.outlineVariant),
                            _ProfileDetailRow(
                              icon: Icons.location_on_outlined,
                              title: isUrdu ? 'شہر / پتہ' : 'Address',
                              value: (user.city != null && user.city!.isNotEmpty)
                                  ? '${user.city}, Pakistan'
                                  : (isUrdu ? 'شامل نہیں' : 'Not added'),
                            ),
                            const Divider(
                                height: 24,
                                color: AppColors.outlineVariant),
                            _ProfileDetailRow(
                              icon: Icons.email_outlined,
                              title: isUrdu ? 'ای میل' : 'Email',
                              value: user.email.isEmpty 
                                  ? (isUrdu ? 'شامل نہیں' : 'Not added')
                                  : user.email,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fade(delay: 180.ms, duration: 500.ms)
                          .slideY(begin: 0.08, end: 0),

                      const SizedBox(height: AppDimensions.lg),

                      // ── Edit Profile Button ──────────────────────────────
                      _GradientButton(
                        label: isUrdu
                            ? '✏️ پروفائل اپڈیٹ کریں'
                            : '✏️ Edit Profile',
                        onTap: _openEditSheet,
                      ).animate().fade(delay: 220.ms, duration: 400.ms),

                      const SizedBox(height: AppDimensions.md),

                      // ── Change Profile Picture Button ────────────────────
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined,
                            color: AppColors.primary),
                        label: Text(
                          isUrdu
                              ? 'تصویر تبدیل کریں'
                              : 'Change Profile Picture',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ).animate().fade(delay: 250.ms, duration: 400.ms),

                      const SizedBox(height: AppDimensions.xl),

                      // ── Reviews Card ─────────────────────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(AppDimensions.lg),
                        shadow: AppShadows.level1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'حالیہ جائزے' : 'Recent Reviews',
                              style: AppTextStyles.heading3.copyWith(
                                color: context.textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ref
                                .watch(
                                    userReviewsStreamProvider(user.uid))
                                .when(
                                  data: (reviews) {
                                    if (reviews.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: Center(
                                          child: Text(
                                            isUrdu
                                                ? 'ابھی تک کوئی جائزہ نہیں'
                                                : 'No reviews yet',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              color: AppColors
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: reviews.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 24),
                                      itemBuilder: (_, index) {
                                        final r = reviews[index];
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  r.reviewerName,
                                                  style: AppTextStyles
                                                      .bodyStrong
                                                      .copyWith(
                                                    color: context.textColor,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.amber
                                                        .withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    '★ ${r.rating.toStringAsFixed(1)}',
                                                    style: AppTextStyles
                                                        .labelCaption
                                                        .copyWith(
                                                      color: AppColors.amber,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              r.comment,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  loading: () => const Center(
                                      child: CircularProgressIndicator()),
                                  error: (e, _) => Text(
                                    isUrdu
                                        ? 'جائزے لوڈ نہیں ہو سکے'
                                        : 'Could not load reviews',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ).animate().fade(delay: 280.ms, duration: 500.ms),

                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heroDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
      );
}

// ── Hero Stat Chip ────────────────────────────────────────────────────────────
class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: context.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelCaption.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Gradient Button (Converted to Primary Solid) ──────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.35),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyStrong.copyWith(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ── Profile Detail Row ────────────────────────────────────────────────────────
class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ProfileDetailRow(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelCaption.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: context.textColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Image Source Bottom Sheet ─────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Photo Source',
            style: AppTextStyles.heading3
                .copyWith(color: context.textColor),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: AppColors.primary,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: AppColors.secondary,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.bodyStrong.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final bool isUrdu;
  final void Function(String name, String email, String phone, String city) onSave;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.isUrdu,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  static const _cities = [
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi',
    'Faisalabad', 'Multan', 'Peshawar', 'Quetta'
  ];
  String _selectedCity = 'Lahore';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 100));
    widget.onSave(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _selectedCity);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isUrdu ? 'پروفائل اپڈیٹ کریں' : 'Update Profile',
                  style: AppTextStyles.heading2.copyWith(color: context.textColor),
                ),
                const SizedBox(height: 6),
                Text(
                  isUrdu
                      ? 'اپنی معلومات درج کریں'
                      : 'Update your personal information',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Full Name field
                _buildLabel(isUrdu ? 'پورا نام' : 'Full Name', context),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    hint: isUrdu ? 'اپنا نام درج کریں' : 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (isUrdu ? 'نام لازمی ہے' : 'Name is required')
                      : null,
                ),
                const SizedBox(height: 16),

                // Email field
                _buildLabel(isUrdu ? 'ای میل' : 'Email', context),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: isUrdu ? 'example@email.com' : 'example@email.com',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Number field
                _buildLabel(isUrdu ? 'فون نمبر' : 'Phone Number', context),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    hint: isUrdu ? '03xxxxxxxxx' : '03xxxxxxxxx',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // City dropdown
                _buildLabel(isUrdu ? 'شہر' : 'City', context),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: _inputDecoration(
                    hint: isUrdu ? 'شہر منتخب کریں' : 'Select city',
                    icon: Icons.location_city_rounded,
                  ),
                  items: _cities
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCity = v);
                  },
                ),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isUrdu ? 'محفوظ کریں' : 'Save Changes',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, BuildContext context) => Text(
        label,
        style: AppTextStyles.bodyStrong.copyWith(
          color: context.textColor,
          fontSize: 13,
        ),
      );

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.primary.withValues(alpha: 0.04),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.outlineVariant, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.outlineVariant, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
