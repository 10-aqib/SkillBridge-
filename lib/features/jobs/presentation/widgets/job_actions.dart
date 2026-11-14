import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/presentation/providers/job_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Close an open job after confirmation. Closed jobs leave the worker feed
/// but stay in the client's history.
Future<bool> closeJobWithConfirm(BuildContext context, WidgetRef ref, JobEntity job) async {
  final l = context.l10n;
  final ok = await showSbConfirmSheet(
    context,
    title: l.jobCloseTitle,
    message: l.jobCloseBody,
    confirmLabel: l.jobClose,
    cancelLabel: l.cancel,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  return _setStatus(context, ref, job, 'cancelled', l.jobClosed);
}

/// Reopen a closed public job after confirmation.
Future<bool> reopenJobWithConfirm(BuildContext context, WidgetRef ref, JobEntity job) async {
  final l = context.l10n;
  final ok = await showSbConfirmSheet(
    context,
    title: l.jobReopenTitle,
    message: l.jobReopenBody,
    confirmLabel: l.jobReopen,
    cancelLabel: l.cancel,
  );
  if (!ok || !context.mounted) return false;
  return _setStatus(context, ref, job, 'open', l.jobReopened);
}

Future<bool> _setStatus(BuildContext context, WidgetRef ref, JobEntity job, String status, String done) async {
  final l = context.l10n;
  try {
    await ref.read(jobRemoteDataSourceProvider).setJobStatus(job.id, status);
    if (context.mounted) context.showSnackBar(done);
    return true;
  } catch (_) {
    if (context.mounted) context.showSnackBar(l.profileSaveFailed, isError: true);
    return false;
  }
}

/// "No proposals yet" / "3 proposals". The number is the job's
/// `totalProposals`, kept by a Cloud Function from the proposal documents
/// (users cannot write it).
class JobProposalCount extends StatelessWidget {
  const JobProposalCount({super.key, required this.count, this.style});
  final int count;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Text(count == 0 ? l.jobNoProposalsYet : l.jobProposalsCount(count),
        style: style ?? Theme.of(context).textTheme.bodySmall);
  }
}
