import 'package:flutter/material.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/support_utils.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// What the person sees after a check (VerificationResultScreen). Neutral
/// wording; never any NADRA response details. Returns true for "try again"
/// (a retryable problem in the same session).
class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key, required this.result});
  final IdentitySubmitResult result;

  static (SbTone, IconData, String, String) contentFor(AppLocalizations l, IdentitySubmitResult r) {
    switch (r.status) {
      case IdentityStatus.verified:
        return r.test
            ? (SbTone.warning, Icons.science_outlined, l.resultTestTitle, l.resultTestBody)
            : (SbTone.success, Icons.verified_user_rounded, l.resultVerifiedTitle, l.resultVerifiedBody);
      case IdentityStatus.rejected:
        return (SbTone.error, Icons.gpp_maybe_outlined, l.resultRejectedTitle, l.resultRejectedBody);
      case IdentityStatus.manualReview:
        return (SbTone.info, Icons.manage_search_rounded, l.resultReviewTitle, l.resultReviewBody);
      case IdentityStatus.expired:
        return (SbTone.warning, Icons.timer_off_outlined, l.resultFailedTitle, l.resultExpired);
      case IdentityStatus.pending:
        if (r.retryable) {
          final poor = r.failureCategory == 'poor_quality';
          return (
            SbTone.warning,
            poor ? Icons.fingerprint_rounded : Icons.cloud_off_rounded,
            l.resultFailedTitle,
            poor ? l.resultRetryPoor(r.attemptsLeft) : l.resultRetryService(r.attemptsLeft),
          );
        }
        return (SbTone.error, Icons.error_outline_rounded, l.resultFailedTitle, l.resultFailedBody);
      default:
        return (SbTone.error, Icons.error_outline_rounded, l.resultFailedTitle, l.resultFailedBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final (tone, icon, title, body) = contentFor(l, result);
    return Scaffold(
      appBar: AppBar(title: Text(l.identityTitle), automaticallyImplyLeading: false),
      body: ListView(padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s6, SbLayout.edge(context), SbSpace.s8), children: [
        if (result.test) ...[
          SbInlineBanner(message: l.identityTestBanner, tone: SbTone.warning, icon: Icons.science_outlined),
          const SizedBox(height: SbSpace.s5),
        ],
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: sb.tone(tone).background),
            child: Icon(icon, size: 52, color: sb.tone(tone).foreground),
          ),
        ),
        const SizedBox(height: SbSpace.s4),
        Semantics(header: true, child: Text(title, style: t.titleLarge, textAlign: TextAlign.center)),
        const SizedBox(height: SbSpace.s2),
        Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: SbSpace.s6),
        if (result.retryable) ...[
          SbButton(label: l.resultTryAgain, icon: Icons.refresh_rounded, expand: true, onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: SbSpace.s2),
        ],
        if (result.status == IdentityStatus.rejected || result.status == IdentityStatus.manualReview) ...[
          SbButton(
            label: l.customerSupport,
            icon: Icons.support_agent_outlined,
            variant: SbButtonVariant.secondary,
            expand: true,
            onPressed: () => SupportUtils.showSupportOptions(context),
          ),
          const SizedBox(height: SbSpace.s2),
        ],
        SbButton(
          label: l.resultDone,
          variant: result.retryable ? SbButtonVariant.secondary : SbButtonVariant.primary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ]),
    );
  }
}
