import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/pakistani_trade_synonyms.dart';
import 'package:skill_bridge/features/jobs/presentation/viewmodels/post_job_viewmodel.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/ai_photo_diagnostic_modal.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_text_field.dart';

/// Guild Modernist Post Job Screen
class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedCategory = 'Electrician';
  final List<String> _selectedSkills = ['Wiring'];
  final JobType _jobType = JobType.temporary;
  final String _budgetType = 'fixed';
  bool _isMilestoneEscrow = false;
  String _urgency = 'normal';

  final List<String> _availableCategories =
      PakistanConstants.categories.map((c) => c['name'] as String).toList();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _runAiPhotoDiagnose() async {
    final result = await AiPhotoDiagnosticModal.show(context);
    if (result != null) {
      setState(() {
        if (_availableCategories.contains(result.recommendedCategory)) {
          _selectedCategory = result.recommendedCategory;
        }
        if (_titleController.text.isEmpty) {
          _titleController.text = result.detectedFault;
        }
        if (_descController.text.isEmpty) {
          _descController.text =
              'Detected Fault: ${result.detectedFault}\nSuggested Spare Parts: ${result.suggestedSpareParts}';
        }
        _minBudgetController.text = '${result.minPkr}';
        _maxBudgetController.text = '${result.maxPkr}';
      });
      if (mounted) {
        context.showSnackBar(
          '📸 AI Photo Diagnosis applied to job post!',
        );
      }
    }
  }

  void _runAiSmartEstimate() {
    final query = '${_titleController.text} ${_descController.text}'.trim();
    if (query.isEmpty) {
      context.showSnackBar('Please enter a title or description first to run AI estimate.');
      return;
    }

    final matched = PakistaniTradeSynonyms.matchCategory(query);
    if (matched != null && _availableCategories.contains(matched)) {
      setState(() {
        _selectedCategory = matched;
      });
    }

    final budget = PakistaniTradeSynonyms.suggestBudgetRange(_selectedCategory);
    _minBudgetController.text = '${budget.minPkr}';
    _maxBudgetController.text = '${budget.maxPkr}';

    context.showSnackBar(
      '✨ AI Estimate Applied: $_selectedCategory (Rs ${budget.minPkr} - ${budget.maxPkr}) based on Pakistani market rates.',
    );
  }

  void _onPostJobSubmitted() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(postJobNotifierProvider.notifier).submitJob(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategory.toLowerCase(),
          categoryName: _selectedCategory,
          requiredSkills: _selectedSkills,
          jobType: _jobType,
          budgetMin: double.tryParse(_minBudgetController.text.trim()) ?? 0,
          budgetMax: double.tryParse(_maxBudgetController.text.trim()) ?? 0,
          budgetType: _budgetType,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          urgency: _urgency,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PostJobState>(postJobNotifierProvider, (previous, next) {
      if (next.isSuccess) {
        context.showSnackBar('Job posted successfully!');
        context.pop();
      } else if (next.errorMessage != null) {
        context.showSnackBar(next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(postJobNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Post a New Job • نیا کام پوسٹ کریں',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job Details • کام کی تفصیلات',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.onSurface,
                ),
              ).animate().fade(duration: 400.ms),
              const SizedBox(height: AppDimensions.md),

              AppCard(
                padding: const EdgeInsets.all(AppDimensions.lg),
                shadow: AppShadows.level1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    AppTextField(
                      controller: _titleController,
                      labelText: 'Job Title • کام کا عنوان',
                      hintText: 'e.g. Need Electrician for House Wiring',
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter job title'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Category Dropdown
                    Text(
                      'Category • زمرہ',
                      style: AppTextStyles.labelCaption.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineVariant),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          style: AppTextStyles.bodyPrimary.copyWith(
                            color: AppColors.onSurface,
                          ),
                          items: _availableCategories
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Description
                    AppTextField(
                      controller: _descController,
                      labelText: 'Job Description • کام کی تفصیل',
                      hintText:
                          'Describe the task, materials needed, requirements...',
                      maxLines: 4,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter job description'
                          : null,
                    ),
                  ],
                ),
              ).animate().fade(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.lg),

              // AI Smart Estimator Button
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.md),
                color: AppColors.primary.withValues(alpha: 0.06),
                border: const BorderSide(color: AppColors.primary, width: 1.2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Smart Estimate • اسمارٹ تخمینہ',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Auto-detect trade or diagnose from photo',
                            style: AppTextStyles.labelCaption.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          text: 'AI Text',
                          onPressed: _runAiSmartEstimate,
                          type: AppButtonType.outline,
                          isSmall: true,
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: '📸 Photo',
                          onPressed: _runAiPhotoDiagnose,
                          type: AppButtonType.solid,
                          isSmall: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 130.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.lg),

              // Budget Section (PKR)
              Text(
                'Budget Range (PKR) • بجٹ کی حد',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.onSurface,
                ),
              ).animate().fade(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.sm),
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.lg),
                shadow: AppShadows.level1,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _minBudgetController,
                            labelText: 'Min Budget (Rs)',
                            hintText: 'e.g. 1000',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: AppTextField(
                            controller: _maxBudgetController,
                            labelText: 'Max Budget (Rs)',
                            hintText: 'e.g. 3000',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: AppDimensions.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primary
                            : null,
                      ),
                      title: Text(
                        'Milestone-Based Escrow • مرحلہ وار ادائیگی',
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _isMilestoneEscrow
                            ? '50% upfront in Raast escrow, 50% on verified completion'
                            : 'Standard 100% upfront in escrow upon hiring',
                        style: AppTextStyles.labelCaption.copyWith(
                          color: _isMilestoneEscrow
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          fontWeight: _isMilestoneEscrow
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      value: _isMilestoneEscrow,
                      onChanged: (val) {
                        setState(() {
                          _isMilestoneEscrow = val;
                        });
                      },
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.lg),

              // Location
              Text(
                'Location • مقام',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.onSurface,
                ),
              ).animate().fade(delay: 250.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.sm),
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.lg),
                shadow: AppShadows.level1,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _addressController,
                      labelText: 'Address • پتہ',
                      hintText: 'Street address / Area',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    AppTextField(
                      controller: _cityController,
                      labelText: 'City • شہر',
                      hintText: 'e.g. Lahore, Karachi, Rawalpindi',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter city' : null,
                    ),
                  ],
                ),
              ).animate().fade(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.lg),

              // Urgency Selector ('immediate' | 'within_3_days' | 'flexible')
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.md),
                shadow: AppShadows.level1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urgency • فوری ضرورت',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Immediate'),
                            selected: _urgency == 'immediate' || _urgency == 'urgent',
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            onSelected: (selected) {
                              if (selected) setState(() => _urgency = 'immediate');
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Within 3 Days'),
                            selected: _urgency == 'within_3_days' || _urgency == 'normal',
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            onSelected: (selected) {
                              if (selected) setState(() => _urgency = 'within_3_days');
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Flexible'),
                            selected: _urgency == 'flexible',
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            onSelected: (selected) {
                              if (selected) setState(() => _urgency = 'flexible');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.xl),

              // Submit Button
              AppButton(
                text: 'Publish Job Post • کام شائع کریں',
                isLoading: state.isLoading,
                onPressed: _onPostJobSubmitted,
                width: double.infinity,
              ).animate().fade(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }
}
