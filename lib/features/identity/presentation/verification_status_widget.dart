import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Short label for an identity status.
String identityStatusLabel(AppLocalizations l, IdentityState s) {
  if (s.verified) return l.identityStatusVerified;
  return switch (s.status) {
    IdentityStatus.notStarted => l.identityStatusNone,
    IdentityStatus.consentPending ||
    IdentityStatus.pending ||
    IdentityStatus.capturing ||
    IdentityStatus.submitted ||
    IdentityStatus.processing =>
      l.identityStatusInProgress,
    IdentityStatus.verified => s.test ? l.identityBadgeTest : l.identityStatusVerified,
    IdentityStatus.rejected => l.identityStatusRejected,
    IdentityStatus.failed => l.identityStatusFailed,
    IdentityStatus.manualReview => l.identityStatusReview,
    IdentityStatus.expired => l.identityStatusExpired,
    IdentityStatus.cancelled => l.identityStatusCancelled,
  };
}

/// The identity badges a profile may show (VerificationStatusWidget). Each
/// badge means one thing only: NADRA verified, TEST verification, or
/// documents reviewed by staff. Nothing private is shown.
class IdentityBadges extends StatelessWidget {
  const IdentityBadges({super.key, required this.user, this.dense = false});
  final UserEntity? user;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final badges = identityBadgesFor(user);
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s1, children: [
      for (final b in badges)
        switch (b) {
          IdentityBadge.nadraVerified => SbStatusBadge(label: l.identityBadgeNadra, icon: Icons.fingerprint_rounded, tone: SbTone.success, dense: dense),
          IdentityBadge.testVerification => SbStatusBadge(label: l.identityBadgeTest, icon: Icons.science_outlined, tone: SbTone.warning, dense: dense),
          IdentityBadge.documentReviewed => SbStatusBadge(label: l.verificationBadge, icon: Icons.fact_check_outlined, tone: SbTone.info, dense: dense),
        },
    ]);
  }
}

/// Card with the person's own identity status (method and date when verified).
class IdentityStatusCard extends StatelessWidget {
  const IdentityStatusCard({super.key, required this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final s = IdentityState.of(user);
    final tone = s.verified
        ? SbTone.success
        : s.test && s.status == IdentityStatus.verified
            ? SbTone.warning
            : s.status == IdentityStatus.rejected || s.status == IdentityStatus.failed
                ? SbTone.error
                : SbTone.neutral;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Material(
      color: sb.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card), side: BorderSide(color: sb.border)),
      child: Padding(
        padding: const EdgeInsets.all(SbSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.fingerprint_rounded, color: sb.tone(tone).foreground, size: 28),
            const SizedBox(width: SbSpace.s3),
            Expanded(child: Text(identityStatusLabel(l, s), style: t.titleMedium)),
          ]),
          if (s.verified) ...[
            const SizedBox(height: SbSpace.s2),
            Text(l.identityMethodFingerprint, style: t.bodySmall),
            if (s.verifiedAt != null) Text(l.identityVerifiedOn(DateFormat.yMMMd(locale).format(s.verifiedAt!)), style: t.bodySmall),
          ],
          const SizedBox(height: SbSpace.s2),
          IdentityBadges(user: user, dense: true),
          const SizedBox(height: SbSpace.s2),
          Text(l.identityOtherChecks, style: t.bodySmall?.copyWith(color: sb.textSecondary)),
        ]),
      ),
    );
  }
}
