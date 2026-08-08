import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/contract_status.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/shared/widgets/app_empty_state.dart';
import 'package:skill_bridge/shared/widgets/app_error_widget.dart';

/// Guild Modernist My Contracts Screen
class MyContractsScreen extends ConsumerWidget {
  const MyContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(userContractsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isClient = currentUser?.isClient ?? false;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceWhite,
          elevation: 0,
          title: Text(
            'My Contracts • میرے معاہدے',
            style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            labelStyle: AppTextStyles.bodyStrong,
            unselectedLabelStyle: AppTextStyles.bodyPrimary,
            tabs: const [
              Tab(text: 'Requests • درخواستیں'),
              Tab(text: 'Active • فعال'),
              Tab(text: 'Completed • مکمل'),
            ],
          ),
        ),
        body: contractsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => AppErrorWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(userContractsStreamProvider),
          ),
          data: (contracts) {
            final pending = contracts
                .where((c) => c.status == ContractStatus.pending)
                .toList();
            final active = contracts
                .where((c) => c.status == ContractStatus.active)
                .toList();
            final completed = contracts
                .where((c) => c.status == ContractStatus.completed)
                .toList();

            return TabBarView(
              children: [
                _ContractList(
                  contracts: pending,
                  isClient: isClient,
                  emptyMessage: 'No pending requests • کوئی زیر التوا درخواست نہیں',
                  ref: ref,
                ),
                _ContractList(
                  contracts: active,
                  isClient: isClient,
                  emptyMessage: 'No active contracts • کوئی فعال معاہدہ نہیں',
                  ref: ref,
                ),
                _ContractList(
                  contracts: completed,
                  isClient: isClient,
                  emptyMessage: 'No completed contracts yet • کوئی مکمل معاہدہ نہیں',
                  ref: ref,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContractList extends StatelessWidget {
  final List<ContractEntity> contracts;
  final bool isClient;
  final String emptyMessage;
  final WidgetRef ref;

  const _ContractList({
    required this.contracts,
    required this.isClient,
    required this.emptyMessage,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (contracts.isEmpty) {
      return AppEmptyState(
        title: 'No Contracts',
        description: emptyMessage,
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.lg),
      itemCount: contracts.length,
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: AppCard(
            padding: const EdgeInsets.all(AppDimensions.lg),
            shadow: AppShadows.level1,
            leftAccentColor: contract.status == ContractStatus.active
                ? AppColors.primary
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.jobTitle,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                Row(
                  children: [
                    AppAvatar(
                      name: isClient
                          ? contract.workerName
                          : contract.clientName,
                      imageUrl: isClient
                          ? contract.workerPhotoUrl
                          : contract.clientPhotoUrl,
                      size: 44,
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClient ? 'Worker • کاریگر' : 'Client • کلائنٹ',
                          style: AppTextStyles.labelCaption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isClient
                              ? contract.workerName
                              : contract.clientName,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),

                // Scheduling Details (if available)
                if (contract.serviceDate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    margin: const EdgeInsets.only(bottom: AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: AppDimensions.sm),
                            Text(
                              '${contract.serviceDate!.day}/${contract.serviceDate!.month}/${contract.serviceDate!.year} • ${contract.serviceTimeSlot ?? ''}',
                              style: AppTextStyles.bodyStrong,
                            ),
                          ],
                        ),
                        if (contract.serviceAddress != null && contract.serviceAddress!.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.errorRed),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(
                                child: Text(
                                  '${contract.serviceAddress}, ${contract.serviceCity ?? ''}',
                                  style: AppTextStyles.bodyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Commission & Earnings Summary
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AmountCell(
                        label: 'Total • کل رقم',
                        value: 'Rs. ${contract.totalAmount.toInt()}',
                        isPrimary: true,
                      ),
                      _AmountCell(
                        label: 'Fee • فیس (10%)',
                        value: 'Rs. ${contract.commissionAmount.toInt()}',
                      ),
                      _AmountCell(
                        label: isClient ? 'You Pay • ادائیگی' : 'Earn • کمائی',
                        value: 'Rs. ${contract.workerEarnings.toInt()}',
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),

                if (isClient &&
                    contract.status == ContractStatus.active) ...[
                  const SizedBox(height: AppDimensions.lg),
                  AppButton(
                    text: 'Mark as Completed • مکمل کے طور پر نشان زد کریں',
                    onPressed: () async {
                      await ref
                          .read(contractRemoteDataSourceProvider)
                          .updateContractStatus(contract.id, 'completed');
                    },
                    width: double.infinity,
                  ),
                ],

                // Pending Actions for Worker
                if (!isClient && contract.status == ContractStatus.pending) ...[
                  const SizedBox(height: AppDimensions.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(contractRemoteDataSourceProvider)
                                .updateContractStatus(contract.id, 'rejected');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                            side: const BorderSide(color: AppColors.errorRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: AppButton(
                          text: 'Accept',
                          onPressed: () async {
                            await ref
                                .read(contractRemoteDataSourceProvider)
                                .updateContractStatus(contract.id, 'active');
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                if (contract.status == ContractStatus.completed &&
                    ((isClient && !contract.clientReviewed) ||
                        (!isClient && !contract.workerReviewed))) ...[
                  const SizedBox(height: AppDimensions.lg),
                  AppButton(
                    text: 'Write a Review • جائزہ لکھیں',
                    onPressed: () {
                      context.pushNamed(
                        RouteNames.writeReviewName,
                        pathParameters: {'contractId': contract.id},
                        extra: contract,
                      );
                    },
                    width: double.infinity,
                  ),
                ],
              ],
            ),
          ),
        ).animate().fade(delay: (80 * index).ms, duration: 400.ms);
      },
    );
  }
}

class _AmountCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _AmountCell({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaption.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.dataNumeric.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color:
                isPrimary ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
