import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/jobs/data/saved_jobs_repository.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The worker's saved jobs (Phase G6), newest first. Opening one shows the
/// job as it is now (the job page explains when it has closed or is gone).
class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  String _budget(BuildContext context, SavedJob j) {
    final f = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    final min = j.budgetMin, max = j.budgetMax;
    if (min == null && max == null) return '';
    if (min == null || max == null || min == max) return 'Rs. ${f.format(max ?? min)}';
    return 'Rs. ${f.format(min)}–${f.format(max)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final async = ref.watch(savedJobsProvider);

    Future<void> remove(SavedJob j) async {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) return;
      try {
        await ref.read(savedJobsStoreProvider).remove(uid, j.jobId);
        if (context.mounted) context.showSnackBar(l.jobBookmarkRemoved);
      } catch (_) {
        if (context.mounted) context.showSnackBar(l.errNetwork, isError: true);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.savedJobsTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => SbStateView(
          kind: SbStateKind.error,
          title: l.savedJobsLoadError,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(savedJobsProvider),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return SbStateView(kind: SbStateKind.empty, title: l.savedJobsEmptyTitle, message: l.savedJobsEmptyBody);
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s3, SbLayout.edge(context), SbSpace.s8),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: SbSpace.s2),
            itemBuilder: (context, i) {
              final j = jobs[i];
              final sub = [if (j.city.isNotEmpty) j.city, _budget(context, j)].where((s) => s.isNotEmpty).join(' · ');
              return Material(
                color: sb.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card), side: BorderSide(color: sb.border)),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(Icons.bookmark_rounded, color: sb.primary),
                  title: Text(j.title.isEmpty ? l.jobDetailsTitle : j.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                  subtitle: sub.isEmpty ? null : Text(sub, style: t.bodySmall),
                  trailing: IconButton(
                    tooltip: l.jobBookmarkRemove,
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    onPressed: () => remove(j),
                  ),
                  onTap: () => context.push(RouteNames.jobDetailsLocation(j.jobId)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
