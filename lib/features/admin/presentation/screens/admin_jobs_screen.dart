import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/admin/presentation/providers/admin_providers.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_empty_state.dart';

/// Guild Modernist Admin Jobs Screen
class AdminJobsScreen extends ConsumerStatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  ConsumerState<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends ConsumerState<AdminJobsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(adminJobsStreamProvider);
    final currencyFormatter =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Manage Jobs • کاموں کا انتظام',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            color: AppColors.surfaceWhite,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search jobs by title • کام تلاش کریں...',
                    hintStyle: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      borderSide:
                          const BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      borderSide:
                          const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter • فلٹر',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      dropdownColor: AppColors.surfaceWhite,
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: AppColors.onSurface,
                      ),
                      underline: const SizedBox(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFilter = val);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Jobs • تمام')),
                        DropdownMenuItem(
                            value: 'active',
                            child: Text('Active / Open • فعال')),
                        DropdownMenuItem(
                            value: 'disputed',
                            child: Text('Disputed / Cancelled • تنازعات')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Job List
          Expanded(
            child: jobsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading jobs: $err',
                  style: AppTextStyles.bodyPrimary
                      .copyWith(color: AppColors.errorRed),
                ),
              ),
              data: (jobsList) {
                final filteredJobs = jobsList.where((j) {
                  final matchesSearch = j.title
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()) ||
                      j.categoryName
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                  final matchesFilter = _selectedFilter == 'all' ||
                      (_selectedFilter == 'active' &&
                          (j.status == JobStatus.open ||
                              j.status == JobStatus.inProgress ||
                              j.status == JobStatus.assigned)) ||
                      (_selectedFilter == 'disputed' &&
                          (j.status == JobStatus.cancelled));
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredJobs.isEmpty) {
                  return const AppEmptyState(
                    title: 'No Jobs Found • کوئی کام نہیں ملا',
                    description: 'No jobs match your search criteria.',
                    icon: Icons.work_off_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: AppDimensions.sm),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    final isDisputed = job.status == JobStatus.cancelled;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.md),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        shadow: AppShadows.level1,
                        leftAccentColor:
                            isDisputed ? AppColors.errorRed : AppColors.primary,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          job.title,
                                          style:
                                              AppTextStyles.bodyStrong.copyWith(
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDisputed
                                              ? AppColors.errorRed
                                                  .withValues(alpha: 0.15)
                                              : AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusSm),
                                        ),
                                        child: Text(
                                          job.status.value.toUpperCase(),
                                          style: AppTextStyles.labelCaption
                                              .copyWith(
                                            color: isDisputed
                                                ? AppColors.errorRed
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Category • زمرہ: ${job.categoryName}',
                                    style: AppTextStyles.labelCaption.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Budget: ${currencyFormatter.format(job.budgetMax)}',
                                    style: AppTextStyles.dataNumeric.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            if (isDisputed)
                              IconButton(
                                tooltip: 'Resolve Dispute • حل کریں',
                                icon: const Icon(Icons.check_circle_outline,
                                    color: AppColors.successGreen),
                                onPressed: () async {
                                  final ds =
                                      ref.read(adminRemoteDataSourceProvider);
                                  await ds.updateJobStatus(
                                      job.id, 'in_progress');
                                  if (context.mounted) {
                                    context.showSnackBar(
                                        'Job status resolved to in_progress.');
                                  }
                                },
                              )
                            else
                              IconButton(
                                tooltip: 'Flag Dispute • تنازعہ درج کریں',
                                icon: const Icon(Icons.flag_outlined,
                                    color: AppColors.warningOrange),
                                onPressed: () async {
                                  final ds =
                                      ref.read(adminRemoteDataSourceProvider);
                                  await ds.updateJobStatus(job.id, 'disputed');
                                  if (context.mounted) {
                                    context.showSnackBar(
                                        'Job marked as disputed.');
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.errorRed),
                              onPressed: () async {
                                final ds =
                                    ref.read(adminRemoteDataSourceProvider);
                                await ds.deleteJob(job.id);
                                if (context.mounted) {
                                  context.showSnackBar(
                                      'Job post deleted successfully.');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: (60 * index).ms, duration: 350.ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
