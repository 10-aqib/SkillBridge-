import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/admin/presentation/providers/admin_providers.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_empty_state.dart';

/// Guild Modernist Admin Users Screen
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Manage Users • صارفین کا انتظام',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email • تلاش کریں...',
                    hintStyle: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
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
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  children: [
                    Text(
                      'Filter Role • کردار: ',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    DropdownButton<String>(
                      value: _selectedRole,
                      dropdownColor: AppColors.surfaceWhite,
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: AppColors.onSurface,
                      ),
                      underline: const SizedBox(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRole = val);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All • تمام')),
                        DropdownMenuItem(
                            value: 'worker',
                            child: Text('Workers • کاریگر')),
                        DropdownMenuItem(
                            value: 'client',
                            child: Text('Clients • کلائنٹس')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live User List
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading users: $err',
                  style: AppTextStyles.bodyPrimary
                      .copyWith(color: AppColors.errorRed),
                ),
              ),
              data: (usersList) {
                final filteredUsers = usersList.where((u) {
                  final matchesSearch = u.displayName
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()) ||
                      u.email
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                  final matchesRole =
                      _selectedRole == 'all' || u.role == _selectedRole;
                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const AppEmptyState(
                    title: 'No Users Found • کوئی صارف نہیں ملا',
                    description: 'No users match your criteria.',
                    icon: Icons.person_off_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: AppDimensions.sm),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isSuspended = !user.isActive;
                    final isVerified = user.workerProfile?.isVerified ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.md),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        shadow: AppShadows.level1,
                        leftAccentColor:
                            isSuspended ? AppColors.errorRed : null,
                        child: Row(
                          children: [
                            AppAvatar(
                              name: user.displayName,
                              imageUrl: user.photoUrl,
                              size: 48,
                            ),
                            const SizedBox(width: AppDimensions.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user.displayName,
                                        style:
                                            AppTextStyles.bodyStrong.copyWith(
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      if (user.isWorker && isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style:
                                        AppTextStyles.labelCaption.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.isWorker
                                              ? AppColors.warningOrange
                                                  .withValues(alpha: 0.15)
                                              : AppColors.successGreen
                                                  .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusSm),
                                        ),
                                        child: Text(
                                          user.role.toUpperCase(),
                                          style: AppTextStyles.labelCaption
                                              .copyWith(
                                            color: user.isWorker
                                                ? AppColors.warningOrange
                                                : AppColors.successGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (isSuspended) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.errorRed
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                                AppDimensions.radiusSm),
                                          ),
                                          child: Text(
                                            'SUSPENDED',
                                            style: AppTextStyles.labelCaption
                                                .copyWith(
                                              color: AppColors.errorRed,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (user.isWorker)
                              IconButton(
                                tooltip: isVerified
                                    ? 'Revoke Verification'
                                    : 'Verify Worker',
                                icon: Icon(
                                  isVerified
                                      ? Icons.verified_user_rounded
                                      : Icons.verified_user_outlined,
                                  color: isVerified
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  final ds = ref
                                      .read(adminRemoteDataSourceProvider);
                                  await ds.toggleWorkerVerification(
                                      user.uid, !isVerified);
                                  if (context.mounted) {
                                    context.showSnackBar(
                                      !isVerified
                                          ? '${user.displayName} is now verified.'
                                          : '${user.displayName} verification revoked.',
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              tooltip: isSuspended
                                  ? 'Activate User'
                                  : 'Suspend User',
                              icon: Icon(
                                isSuspended
                                    ? Icons.play_arrow_rounded
                                    : Icons.block_rounded,
                                color: isSuspended
                                    ? AppColors.successGreen
                                    : AppColors.errorRed,
                              ),
                              onPressed: () async {
                                final ds = ref
                                    .read(adminRemoteDataSourceProvider);
                                await ds.updateUserStatus(
                                    user.uid, isSuspended);
                                if (context.mounted) {
                                  context.showSnackBar(
                                    isSuspended
                                        ? '${user.displayName} has been activated.'
                                        : '${user.displayName} has been suspended.',
                                  );
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
