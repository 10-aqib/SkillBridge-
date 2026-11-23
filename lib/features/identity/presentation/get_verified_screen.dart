import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/features/identity/presentation/verified_badge.dart';
import 'package:skill_bridge/features/worker/data/verification_service.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Where the CNIC step stands.
enum CnicStepStatus { notStarted, review, approved, rejected }

CnicStepStatus cnicStepStatus(UserEntity user, VerificationSubmission? submission) {
  if (cnicDocumentsApproved(user)) return CnicStepStatus.approved;
  final s = submission?.status ?? user.workerProfile?.verificationStatus;
  if (s == 'rejected') return CnicStepStatus.rejected;
  if (s == 'pending' || submission != null) return CnicStepStatus.review;
  return CnicStepStatus.notStarted;
}

/// "Get verified" (both roles): one place with the two identity checks.
/// 1. CNIC: number + photos of the card, reviewed by SkillBridge staff.
///    Approval gives the Verified badge.
/// 2. Fingerprint: matched against NADRA's records. Opens only when an
///    authorised NADRA integration exists; until then it says "Coming soon"
///    and collects nothing.
class GetVerifiedScreen extends ConsumerWidget {
  const GetVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SbDetailSkeleton());
    final edge = SbLayout.edge(context);
    final submission = ref.watch(verificationSubmissionProvider(user.uid));
    final config = ref.watch(identityConfigProvider);
    final verified = isIdentityVerified(user);
    final cnic = cnicStepStatus(user, submission.value);
    final nadra = IdentityState.of(user);
    final nadraOpen = config.value?.available ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l.getVerifiedTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s2, edge, SbSpace.s8),
        children: [
          SbReadableWidth(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _Header(verified: verified),
              const SizedBox(height: SbSpace.s5),
              _StepCard(
                number: 1,
                icon: Icons.badge_outlined,
                title: l.getVerifiedStepCnic,
                body: l.getVerifiedStepCnicBody,
                status: switch (cnic) {
                  CnicStepStatus.approved => (l.getVerifiedStatusDone, SbTone.success),
                  CnicStepStatus.review => (l.getVerifiedStatusReview, SbTone.warning),
                  CnicStepStatus.rejected => (l.getVerifiedStatusRejected, SbTone.error),
                  CnicStepStatus.notStarted => (l.getVerifiedStatusNotStarted, SbTone.neutral),
                },
                actionLabel: switch (cnic) {
                  CnicStepStatus.notStarted => l.getVerifiedStart,
                  CnicStepStatus.rejected => l.getVerifiedTryAgain,
                  _ => l.getVerifiedView,
                },
                primary: cnic == CnicStepStatus.notStarted || cnic == CnicStepStatus.rejected,
                onAction: () => context.push(RouteNames.cnicVerificationPath),
              ),
              const SizedBox(height: SbSpace.s3),
              _StepCard(
                number: 2,
                icon: Icons.fingerprint_rounded,
                title: l.getVerifiedStepFingerprint,
                body: nadraOpen || nadra.verified ? l.getVerifiedStepFingerprintBody : l.getVerifiedFingerprintSoon,
                status: nadra.verified
                    ? (l.getVerifiedStatusDone, SbTone.success)
                    : nadraOpen
                        ? (nadra.status == IdentityStatus.notStarted ? l.getVerifiedStatusNotStarted : identityStepLabel(context, nadra), SbTone.neutral)
                        : (l.getVerifiedComingSoon, SbTone.info),
                actionLabel: nadra.verified ? l.getVerifiedView : (nadraOpen ? l.getVerifiedStart : null),
                primary: nadraOpen && !nadra.verified && cnic != CnicStepStatus.notStarted,
                onAction: () => context.push(RouteNames.identityPath),
              ),
              const SizedBox(height: SbSpace.s5),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: sb.textSecondary),
                const SizedBox(width: SbSpace.s2),
                Expanded(child: Text(l.getVerifiedPrivacy, style: t.bodySmall!.copyWith(color: sb.textSecondary))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Short status for a NADRA attempt in progress or finished without success.
String identityStepLabel(BuildContext context, IdentityState s) {
  final l = context.l10n;
  return switch (s.status) {
    IdentityStatus.rejected || IdentityStatus.failed || IdentityStatus.expired || IdentityStatus.cancelled => l.getVerifiedStatusRejected,
    IdentityStatus.manualReview => l.getVerifiedStatusReview,
    _ => l.getVerifiedStatusInProgress,
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    return Container(
      padding: const EdgeInsets.all(SbSpace.s5),
      decoration: BoxDecoration(color: sb.primarySubtle, borderRadius: BorderRadius.circular(SbRadius.card)),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: verified ? sb.primary : sb.surface, shape: BoxShape.circle),
          child: Icon(verified ? Icons.verified_rounded : Icons.verified_outlined, size: 38, color: verified ? sb.onPrimary : sb.primary),
        ),
        const SizedBox(height: SbSpace.s3),
        Text(verified ? l.getVerifiedDoneTitle : l.getVerifiedHeaderTitle,
            style: t.titleLarge!.copyWith(color: sb.onPrimarySubtle), textAlign: TextAlign.center),
        const SizedBox(height: SbSpace.s1),
        Text(verified ? l.getVerifiedDoneBody : l.getVerifiedIntro,
            style: t.bodyMedium!.copyWith(color: sb.onPrimarySubtle), textAlign: TextAlign.center),
        if (verified) ...[const SizedBox(height: SbSpace.s3), const VerifiedPill()],
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
    required this.onAction,
    this.actionLabel,
    this.primary = false,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;
  final (String, SbTone) status;
  final String? actionLabel;
  final bool primary;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    return Material(
      color: sb.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card), side: BorderSide(color: sb.border)),
      child: Padding(
        padding: const EdgeInsets.all(SbSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: sb.primarySubtle, borderRadius: BorderRadius.circular(SbRadius.control)),
              child: Icon(icon, color: sb.primary),
            ),
            const SizedBox(width: SbSpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.getVerifiedStepN(number), style: t.labelSmall!.copyWith(color: sb.textSecondary)),
                Text(title, style: t.titleMedium),
              ]),
            ),
            SbStatusBadge(label: status.$1, icon: _iconFor(status.$2), tone: status.$2, dense: true),
          ]),
          const SizedBox(height: SbSpace.s3),
          Text(body, style: t.bodyMedium),
          if (actionLabel != null) ...[
            const SizedBox(height: SbSpace.s3),
            SbButton(
              label: actionLabel!,
              variant: primary ? SbButtonVariant.primary : SbButtonVariant.secondary,
              expand: true,
              onPressed: onAction,
            ),
          ],
        ]),
      ),
    );
  }

  static IconData _iconFor(SbTone tone) => switch (tone) {
        SbTone.success => Icons.check_circle_rounded,
        SbTone.warning => Icons.schedule_rounded,
        SbTone.error => Icons.error_outline_rounded,
        SbTone.info => Icons.hourglass_empty_rounded,
        _ => Icons.radio_button_unchecked_rounded,
      };
}

/// The "Get verified" entry on a person's own profile: a call to action
/// before, the Verified badge after.
class GetVerifiedCard extends ConsumerWidget {
  const GetVerifiedCard({super.key, required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final verified = isIdentityVerified(user);
    final submission = ref.watch(verificationSubmissionProvider(user.uid)).value;
    final cnic = cnicStepStatus(user, submission);
    final (String title, String body) = verified
        ? (l.getVerifiedDoneTitle, l.getVerifiedDoneBody)
        : cnic == CnicStepStatus.review
            ? (l.getVerifiedReviewTitle, l.getVerifiedReviewBody)
            : (l.getVerifiedTitle, l.getVerifiedCardBody);

    return Material(
      color: verified ? sb.surface : sb.primarySubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.card),
        side: BorderSide(color: verified ? sb.border : sb.primary.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteNames.getVerifiedPath),
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: verified ? sb.primary : sb.surface, shape: BoxShape.circle),
              child: Icon(
                verified ? Icons.verified_rounded : (cnic == CnicStepStatus.review ? Icons.schedule_rounded : Icons.verified_user_outlined),
                color: verified ? sb.onPrimary : sb.primary,
              ),
            ),
            const SizedBox(width: SbSpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleMedium!.copyWith(color: verified ? null : sb.onPrimarySubtle)),
                const SizedBox(height: 2),
                Text(body, style: t.bodySmall!.copyWith(color: verified ? sb.textSecondary : sb.onPrimarySubtle)),
              ]),
            ),
            const SizedBox(width: SbSpace.s2),
            verified
                ? Icon(Icons.chevron_right_rounded, color: sb.textSecondary)
                : SbButton(label: cnic == CnicStepStatus.review ? l.getVerifiedView : l.getVerifiedStart, onPressed: () => context.push(RouteNames.getVerifiedPath)),
          ]),
        ),
      ),
    );
  }
}
