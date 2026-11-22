import 'package:flutter/material.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/identity/data/identity_verification_service.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// While the server checks the capture (VerificationProcessingScreen). Runs
/// [submit] once and returns its result (or the error) to the caller. It
/// can't be dismissed while the check runs, so the request isn't abandoned
/// half way; the server makes retries idempotent anyway.
class VerificationProcessingScreen extends StatefulWidget {
  const VerificationProcessingScreen({super.key, required this.submit, required this.test});
  final Future<IdentitySubmitResult> Function() submit;
  final bool test;

  @override
  State<VerificationProcessingScreen> createState() => _VerificationProcessingScreenState();
}

class _VerificationProcessingScreenState extends State<VerificationProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Object outcome;
      try {
        outcome = await widget.submit();
      } on IdentityException catch (e) {
        outcome = e;
      } catch (_) {
        outcome = const IdentityException(IdentityProblem.generic);
      }
      if (mounted) Navigator.of(context).pop(outcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(l.processingTitle), automaticallyImplyLeading: false),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: SbLayout.edge(context)),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.test) ...[
                SbInlineBanner(message: l.identityTestBanner, tone: SbTone.warning, icon: Icons.science_outlined),
                const SizedBox(height: SbSpace.s5),
              ],
              const SizedBox.square(dimension: 48, child: CircularProgressIndicator(strokeWidth: 4)),
              const SizedBox(height: SbSpace.s5),
              Text(widget.test ? l.processingBodyTest : l.processingBody, style: t.bodyLarge, textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}
