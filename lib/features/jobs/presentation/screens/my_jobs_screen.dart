import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_actions.dart';
import 'package:skill_bridge/features/jobs/presentation/widgets/job_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

enum MyJobsTab { open, active, completed, closed }

MyJobsTab myJobsTabOf(JobStatus s) => switch (s) {
      JobStatus.open => MyJobsTab.open,
      JobStatus.assigned || JobStatus.inProgress => MyJobsTab.active,
      JobStatus.completed => MyJobsTab.completed,
      JobStatus.cancelled => MyJobsTab.closed,
    };

/// The signed-in client's own jobs, from Firestore, grouped by status.
class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  MyJobsTab _tab = MyJobsTab.open;

  String _tabLabel(MyJobsTab t, int n) {
    final l = context.l10n;
    final name = switch (t) {
      MyJobsTab.open => l.jobStatusOpen,
      MyJobsTab.active => l.myJobsTabActive,
      MyJobsTab.completed => l.jobStatusCompleted,
      MyJobsTab.closed => l.jobStatusClosed,
    };
    return '$name · $n';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final edge = SbLayout.edge(context);
    final jobs = ref.watch(clientJobsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myJobsTitle),
        actions: [
          IconButton(
            tooltip: l.contractsTitle,
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push(RouteNames.clientContractsPath),
          ),
          IconButton(
            tooltip: l.jobFormTitleNew,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RouteNames.clientPostJobPath),
          ),
        ],
      ),
      body: jobs.when(
        loading: () => ListView(
          padding: EdgeInsets.all(edge),
          children: const [JobCardSkeleton(), SizedBox(height: SbSpace.s3), JobCardSkeleton()],
        ),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.myJobsLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(clientJobsStreamProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return SbStateView(
              kind: SbStateKind.empty,
              title: l.myJobsEmptyTitle,
              message: l.myJobsEmptyBody,
              actionLabel: l.jobFormTitleNew,
              onAction: () => context.push(RouteNames.clientPostJobPath),
            );
          }
          final counts = {for (final t in MyJobsTab.values) t: all.where((j) => myJobsTabOf(j.status) == t).length};
          final shown = all.where((j) => myJobsTabOf(j.status) == _tab).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientJobsStreamProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s8),
              children: [
                SbReadableWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final t in MyJobsTab.values)
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
                        child: Text(l.myJobsTabEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    for (final job in shown) ...[
                      _MyJobCard(job: job),
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

class _MyJobCard extends ConsumerWidget {
  const _MyJobCard({required this.job});
  final JobEntity job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final direct = job.selectedWorkerId != null && job.selectedWorkerId!.isNotEmpty;
    void open() => context.push(RouteNames.jobDetailsLocation(job.id), extra: job);

    final actions = <Widget>[
      if (job.status == JobStatus.open) ...[
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l.jobEdit),
          onPressed: () => context.push(RouteNames.jobEditLocation(job.id), extra: job),
        ),
        TextButton.icon(
          icon: Icon(Icons.do_not_disturb_on_outlined, size: 18, color: context.sb.error),
          label: Text(l.jobClose, style: TextStyle(color: context.sb.error)),
          onPressed: () => closeJobWithConfirm(context, ref, job),
        ),
      ],
      if (job.status == JobStatus.cancelled && !direct)
        TextButton.icon(
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: Text(l.jobReopen),
          onPressed: () => reopenJobWithConfirm(context, ref, job),
        ),
    ];

    return JobListCard(
      job: job,
      showStatus: true,
      onTap: open,
      proposalsLabel: direct ? l.jobDirectTo(job.selectedWorkerName ?? '') : null,
      footer: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!direct && job.status == JobStatus.open) JobProposalCount(count: job.totalProposals),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Wraps on narrow phones instead of overflowing.
          Expanded(child: Wrap(spacing: SbSpace.s1, children: actions)),
          TextButton(onPressed: open, child: Text(l.jobView)),
        ]),
      ]),
    );
  }
}
