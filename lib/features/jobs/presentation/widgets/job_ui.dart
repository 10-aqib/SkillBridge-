import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

final NumberFormat _pkr = NumberFormat.decimalPattern('en');

String formatRupees(num amount) => 'Rs ${_pkr.format(amount.round())}';

/// "Rs 2,000 – 3,000 · Fixed price", "Rs 800 / hour", "Rs 4,500 / day".
String jobBudgetLabel(AppLocalizations l, JobEntity job) {
  final lo = job.budgetMin;
  final hi = job.budgetMax;
  if (lo <= 0 && hi <= 0) return l.jobBudgetNotSet;
  final amount = (lo > 0 && hi > lo) ? '${formatRupees(lo)} – ${_pkr.format(hi.round())}' : formatRupees(hi > 0 ? hi : lo);
  return switch (job.budgetType) {
    'hourly' => l.jobBudgetPerHour(amount),
    'daily' => l.jobBudgetPerDay(amount),
    _ => l.jobBudgetFixedPrice(amount),
  };
}

String budgetTypeLabel(AppLocalizations l, String type) => switch (type) {
      'hourly' => l.jobBudgetTypeHourly,
      'daily' => l.jobBudgetTypeDaily,
      _ => l.jobBudgetTypeFixed,
    };

String budgetBandLabel(AppLocalizations l, BudgetBand b) => switch (b) {
      BudgetBand.under2k => l.jobBandUnder2k,
      BudgetBand.from2kTo5k => l.jobBand2kTo5k,
      BudgetBand.from5kTo15k => l.jobBand5kTo15k,
      BudgetBand.from15kTo50k => l.jobBand15kTo50k,
      BudgetBand.over50k => l.jobBandOver50k,
    };

String postedWithinLabel(AppLocalizations l, JobPostedWithin p) => switch (p) {
      JobPostedWithin.any => l.jobPostedAnyTime,
      JobPostedWithin.day => l.jobPostedLast24h,
      JobPostedWithin.threeDays => l.jobPostedLast3Days,
      JobPostedWithin.week => l.jobPostedLast7Days,
      JobPostedWithin.month => l.jobPostedLast30Days,
    };

String jobSortLabel(AppLocalizations l, JobSort s) => switch (s) {
      JobSort.newest => l.jobSortNewest,
      JobSort.oldest => l.jobSortOldest,
      JobSort.budgetLow => l.jobSortBudgetLow,
      JobSort.budgetHigh => l.jobSortBudgetHigh,
    };

/// "Posted today", "Posted 3 days ago", "Posted 4 Nov 2026".
String jobPostedLabel(BuildContext context, DateTime createdAt, {DateTime? now}) {
  final l = context.l10n;
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(createdAt);
  final days = today.difference(day).inDays;
  if (days <= 0) return l.jobPostedToday;
  if (days == 1) return l.jobPostedYesterday;
  if (days < 7) return l.jobPostedDaysAgo(days);
  return l.jobPostedOn(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(createdAt));
}

String urgencyLabel(AppLocalizations l, String urgency) => switch (urgency) {
      'immediate' || 'urgent' => l.jobUrgencyImmediate,
      'flexible' => l.jobUrgencyFlexible,
      _ => l.jobUrgencyThreeDays,
    };

bool isUrgentJob(JobEntity job) => job.urgency == 'immediate' || job.urgency == 'urgent';

String jobCategoryLabel(BuildContext context, String categoryId, String categoryName) {
  final c = PakistanConstants.categoryById(categoryId);
  if (c == null) return categoryName;
  return context.isUrdu ? c['urdu'] as String : c['name'] as String;
}

IconData jobCategoryIcon(String categoryId) =>
    (PakistanConstants.categoryById(categoryId)?['icon'] as IconData?) ?? Icons.handyman_outlined;

/// City and area only — the exact address is never shown on a public job.
String jobAreaLabel(JobEntity job) {
  final parts = [job.address.trim(), job.city.trim()].where((p) => p.isNotEmpty).toList();
  if (parts.length == 2 && parts[0].toLowerCase().contains(parts[1].toLowerCase())) return parts[0];
  return parts.join(', ');
}

class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status, this.dense = true});
  final JobStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (label, icon, tone) = switch (status) {
      JobStatus.open => (l.jobStatusOpen, Icons.radio_button_checked_rounded, SbTone.info),
      JobStatus.assigned => (l.jobStatusAssigned, Icons.handshake_outlined, SbTone.accent),
      JobStatus.inProgress => (l.jobStatusInProgress, Icons.construction_rounded, SbTone.warning),
      JobStatus.completed => (l.jobStatusCompleted, Icons.check_circle_outline_rounded, SbTone.success),
      JobStatus.cancelled => (l.jobStatusClosed, Icons.do_not_disturb_on_outlined, SbTone.neutral),
    };
    return SbStatusBadge(label: label, icon: icon, tone: tone, dense: dense);
  }
}

/// Job card used by the client's My Jobs list and the worker feed.
class JobListCard extends StatelessWidget {
  const JobListCard({
    super.key,
    required this.job,
    this.onTap,
    this.showStatus = false,
    this.showDetails = false,
    this.proposalsLabel,
    this.footer,
  });

  final JobEntity job;
  final VoidCallback? onTap;
  final bool showStatus;

  /// Feed view: short description, skills and the client's public name.
  final bool showDetails;
  final String? proposalsLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final area = jobAreaLabel(job);
    final client = job.clientName.trim().split(RegExp(r'\s+')).first;
    return SbJobCard(
      title: job.title,
      category: jobCategoryLabel(context, job.categoryId, job.categoryName),
      categoryIcon: jobCategoryIcon(job.categoryId),
      locationLabel: area.isEmpty ? null : area,
      postedLabel: jobPostedLabel(context, job.createdAt),
      budgetLabel: jobBudgetLabel(l, job),
      urgentLabel: isUrgentJob(job) ? l.jobUrgencyImmediate : null,
      proposalsLabel: proposalsLabel,
      status: showStatus ? JobStatusBadge(status: job.status) : null,
      summary: showDetails ? job.description : null,
      tags: showDetails ? job.requiredSkills : const [],
      byline: showDetails && client.isNotEmpty ? client : null,
      footer: footer,
      onTap: onTap,
    );
  }
}

/// Loading placeholder shaped like [JobListCard].
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SbSkeletonCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SbSkeleton(width: 40, height: 40, radius: SbRadius.control),
          SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SbSkeleton(width: 90, height: 12),
              SizedBox(height: SbSpace.s2),
              SbSkeleton(height: 16),
            ]),
          ),
        ]),
        SizedBox(height: SbSpace.s3),
        SbSkeleton(height: 12),
        SizedBox(height: SbSpace.s2),
        SbSkeleton(width: 200, height: 12),
        SizedBox(height: SbSpace.s4),
        SbSkeleton(width: 140, height: 16),
      ]),
    );
  }
}
