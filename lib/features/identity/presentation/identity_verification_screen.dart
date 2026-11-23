import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/data/biometric_capture_service.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/features/identity/presentation/biometric_consent_screen.dart';
import 'package:skill_bridge/features/identity/presentation/cnic_input_screen.dart';
import 'package:skill_bridge/features/identity/presentation/fingerprint_capture_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verification_processing_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verification_result_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verification_status_widget.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:uuid/uuid.dart';

String identityProblemText(AppLocalizations l, IdentityProblem p) => switch (p) {
      IdentityProblem.recentLogin => l.identityErrRecentLogin,
      IdentityProblem.consent => l.consentTitle,
      IdentityProblem.invalidCnic => l.cnicInvalid,
      IdentityProblem.syntheticOnly => l.identityErrSynthetic,
      IdentityProblem.inUse => l.identityErrInUse,
      IdentityProblem.alreadyVerified => l.identityErrAlready,
      IdentityProblem.dailyLimit => l.identityErrDaily,
      IdentityProblem.attemptLimit => l.identityErrAttempts,
      IdentityProblem.expired => l.resultExpired,
      IdentityProblem.notAvailable => l.identityNotAvailableTitle,
      IdentityProblem.offline => l.identityErrOffline,
      IdentityProblem.generic => l.identityErrGeneric,
    };

/// Identity verification hub (IdentityVerificationScreen), the same for
/// workers and hirers: current status, availability of the service, and the
/// flow CNIC → consent → session → capture → check → result.
class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  bool _starting = false;

  Future<void> _run(IdentityConfig config) async {
    final l = context.l10n;
    final nav = Navigator.of(context);
    final service = ref.read(identityVerificationServiceProvider);

    final cnic = await nav.push<String>(MaterialPageRoute(builder: (_) => CnicInputScreen(test: config.test)));
    if (cnic == null || !mounted) return;
    final agreed = await nav.push<bool>(MaterialPageRoute(
      builder: (_) => BiometricConsentScreen(maskedCnic: CnicValidation.mask(cnic), consentVersion: config.consentVersion, test: config.test),
    ));
    if (agreed != true || !mounted) return;

    setState(() => _starting = true);
    IdentitySession session;
    try {
      session = await service.start(cnic: cnic, consentVersion: config.consentVersion);
    } on IdentityException catch (e) {
      if (mounted) context.showSnackBar(identityProblemText(l, e.problem), isError: true);
      return;
    } finally {
      if (mounted) setState(() => _starting = false);
    }
    if (!mounted) return;

    final capture = ref.read(biometricCaptureServiceProvider(session.provider));
    while (mounted) {
      final result = await nav.push<CaptureResult>(MaterialPageRoute(
        builder: (_) => FingerprintCaptureScreen(service: capture, expiresAt: session.expiresAt),
      ));
      if (!mounted) return;
      if (result == null) {
        // Cancelled before submitting: close the session (nothing was sent).
        service.cancel(session.sessionId).catchError((_) {});
        context.showSnackBar(l.identityCancelled);
        return;
      }
      final requestId = const Uuid().v4();
      final outcome = await nav.push<Object>(MaterialPageRoute(
        builder: (_) => VerificationProcessingScreen(
          test: session.test,
          submit: () => service.submit(sessionId: session.sessionId, cnic: cnic, requestId: requestId, capture: result.toRequest()),
        ),
      ));
      if (!mounted) return;
      if (outcome is IdentityException) {
        context.showSnackBar(identityProblemText(l, outcome.problem), isError: true);
        return;
      }
      if (outcome is! IdentitySubmitResult) return;
      final again = await nav.push<bool>(MaterialPageRoute(builder: (_) => VerificationResultScreen(result: outcome)));
      if (again != true || !outcome.retryable) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final state = IdentityState.of(user);
    final configAsync = ref.watch(identityConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.identityTitle), actions: [
        IconButton(tooltip: l.identityHistory, icon: const Icon(Icons.history_rounded), onPressed: () => context.push(RouteNames.identityHistoryPath)),
      ]),
      body: ListView(padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s3, SbLayout.edge(context), SbSpace.s8), children: [
        IdentityStatusCard(user: user),
        const SizedBox(height: SbSpace.s4),
        Text(l.identityIntro, style: t.bodyMedium),
        const SizedBox(height: SbSpace.s4),
        configAsync.when(
          loading: () => const SbSkeletonGroup(child: SbSkeleton(height: 120, radius: SbRadius.card)),
          error: (e, _) => SbInlineBanner(
            message: e is IdentityException ? identityProblemText(l, e.problem) : l.identityErrGeneric,
            tone: SbTone.error,
            actionLabel: l.tryAgain,
            onAction: () => ref.invalidate(identityConfigProvider),
          ),
          data: (config) {
            if (!config.available) {
              // Case A: no authorised NADRA integration yet. Nothing is collected.
              return SbInlineBanner(message: '${l.identityNotAvailableTitle}. ${l.identityNotAvailableBody}', tone: SbTone.info, icon: Icons.hourglass_empty_rounded);
            }
            if (state.verified) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (config.test) ...[
                SbInlineBanner(message: l.identityTestBanner, tone: SbTone.warning, icon: Icons.science_outlined),
                const SizedBox(height: SbSpace.s4),
              ],
              SbButton(
                label: state.status == IdentityStatus.notStarted ? l.identityStart : l.identityStartAgain,
                icon: Icons.fingerprint_rounded,
                expand: true,
                isLoading: _starting,
                onPressed: _starting ? null : () => _run(config),
              ),
            ]);
          },
        ),
      ]),
    );
  }
}
