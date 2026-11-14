import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/contract_ui.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

enum ContractsTab { requests, active, completed, cancelled }

ContractsTab contractsTabOf(ContractStage s) => switch (s) {
      ContractStage.requested => ContractsTab.requests,
      ContractStage.notStarted || ContractStage.inProgress || ContractStage.submitted => ContractsTab.active,
      ContractStage.completed => ContractsTab.completed,
      ContractStage.cancelled || ContractStage.declined => ContractsTab.cancelled,
    };

/// The signed-in user's contracts, for clients and workers, from Firestore.
class MyContractsScreen extends ConsumerStatefulWidget {
  const MyContractsScreen({super.key});

  @override
  ConsumerState<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends ConsumerState<MyContractsScreen> {
  ContractsTab _tab = ContractsTab.active;
  bool _tabChosen = false;

  String _tabLabel(ContractsTab t, int n) {
    final l = context.l10n;
    final name = switch (t) {
      ContractsTab.requests => l.contractsTabRequests,
      ContractsTab.active => l.contractsTabActive,
      ContractsTab.completed => l.contractsTabCompleted,
      ContractsTab.cancelled => l.contractsTabCancelled,
    };
    return '$name · $n';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final edge = SbLayout.edge(context);
    final contracts = ref.watch(userContractsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.contractsTitle)),
      body: contracts.when(
        loading: () => ListView(
          padding: EdgeInsets.all(edge),
          children: const [JobCardSkeleton(), SizedBox(height: SbSpace.s3), JobCardSkeleton()],
        ),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.contractsLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(userContractsStreamProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            final isClient = ref.read(currentUserProvider)?.isClient ?? false;
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(userContractsStreamProvider),
              child: ListView(children: [
                SizedBox(
                  height: 420,
                  child: SbStateView(
                    kind: SbStateKind.empty,
                    title: l.contractsEmptyTitle,
                    message: isClient ? l.contractsEmptyClient : l.contractsEmptyWorker,
                  ),
                ),
              ]),
            );
          }
          final counts = {for (final t in ContractsTab.values) t: all.where((c) => contractsTabOf(c.stage) == t).length};
          if (!_tabChosen) {
            _tabChosen = true;
            if (counts[_tab] == 0) _tab = ContractsTab.values.firstWhere((t) => counts[t]! > 0);
          }
          final shown = all.where((c) => contractsTabOf(c.stage) == _tab).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userContractsStreamProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
              children: [
                SbReadableWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final t in ContractsTab.values)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: SbSpace.s2),
                            child: ChoiceChip(
                              label: Text(_tabLabel(t, counts[t]!)),
                              selected: _tab == t,
                              onSelected: (_) => setState(() => _tab = t),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: SbSpace.s4),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: SbSpace.s8),
                        child: Text(l.contractsTabEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    for (final c in shown) ...[
                      ContractCard(contract: c),
                      const SizedBox(height: SbSpace.s3),
                    ],
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One contract: job, the other participant's public profile, price and
/// payment type, created date, stage and what happens next.
class ContractCard extends ConsumerWidget {
  const ContractCard({super.key, required this.contract});
  final ContractEntity contract;

  String _progress(BuildContext context, bool isClient) {
    final l = context.l10n;
    final c = contract;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    return switch (c.stage) {
      ContractStage.requested => isClient ? l.contractNextClientRequested : l.contractNextWorkerRequested,
      ContractStage.notStarted => isClient ? l.contractNextClientNotStarted : l.contractNextWorkerNotStarted,
      ContractStage.inProgress => l.contractProgressStarted(date.format(c.workStartedAt!)),
      ContractStage.submitted => isClient ? l.contractNextClientSubmitted : l.contractNextWorkerSubmitted,
      ContractStage.completed => c.completedAt == null ? l.contractStageCompleted : l.contractProgressCompleted(date.format(c.completedAt!)),
      ContractStage.cancelled => c.cancelledAt == null
          ? l.contractStageCancelled
          : l.contractProgressCancelled(date.format(c.cancelledAt!)),
      ContractStage.declined => l.contractStageDeclined,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final me = ref.watch(currentUserProvider);
    final isClient = me?.uid == contract.clientId;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    void open() => context.push(RouteNames.contractDetailsLocation(contract.id), extra: contract);
    final needsMe = switch (contract.stage) {
      ContractStage.requested => !isClient,
      ContractStage.notStarted || ContractStage.inProgress => !isClient,
      ContractStage.submitted => isClient,
      _ => false,
    };

    return Material(
      color: sb.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.card),
        side: BorderSide(color: needsMe ? sb.primary : sb.border, width: needsMe ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              ContractStageBadge(stage: contract.stage),
              const SizedBox(width: SbSpace.s2),
              // The date gives way on narrow screens; the stage never does.
              Expanded(
                child: Text(l.contractCreatedOn(date.format(contract.createdAt)),
                    style: t.bodySmall, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: SbSpace.s2),
            Text(contract.jobTitle, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: SbSpace.s3),
            ContractPartyCard(
              uid: isClient ? contract.workerId : contract.clientId,
              fallbackName: isClient ? contract.workerName : contract.clientName,
              fallbackPhoto: isClient ? contract.workerPhotoUrl : contract.clientPhotoUrl,
              isWorker: isClient,
              showDetails: false,
            ),
            const SizedBox(height: SbSpace.s3),
            Text(contractPriceLabel(l, contract), style: SbTypography.numeric(t.titleSmall!)),
            const SizedBox(height: SbSpace.s1),
            Row(children: [
              Icon(needsMe ? Icons.arrow_circle_right_outlined : Icons.info_outline_rounded, size: 16, color: needsMe ? sb.primary : sb.textSecondary),
              const SizedBox(width: SbSpace.s1),
              Expanded(
                child: Text(
                  _progress(context, isClient),
                  style: t.bodySmall!.copyWith(color: needsMe ? sb.primary : sb.textSecondary),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
