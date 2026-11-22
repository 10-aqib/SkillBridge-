import 'package:flutter/material.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Explicit biometric consent (BiometricConsentScreen), separate from any
/// other agreement. Capture can't start until the box is ticked; the server
/// records the consent version and time with the session. Returns true when
/// the person agrees.
class BiometricConsentScreen extends StatefulWidget {
  const BiometricConsentScreen({super.key, required this.maskedCnic, required this.consentVersion, required this.test});
  final String maskedCnic;
  final String consentVersion;
  final bool test;

  @override
  State<BiometricConsentScreen> createState() => _BiometricConsentScreenState();
}

class _BiometricConsentScreenState extends State<BiometricConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: SbSpace.s3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: sb.primary),
            const SizedBox(width: SbSpace.s3),
            Expanded(child: Text(text, style: t.bodyMedium)),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.consentTitle)),
      body: ListView(padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s4, SbLayout.edge(context), SbSpace.s8), children: [
        if (widget.test) ...[
          SbInlineBanner(message: l.identityTestBanner, tone: SbTone.warning, icon: Icons.science_outlined),
          const SizedBox(height: SbSpace.s4),
        ],
        Text(widget.maskedCnic, style: t.titleMedium, textDirection: TextDirection.ltr),
        const SizedBox(height: SbSpace.s4),
        point(Icons.help_outline_rounded, l.consentWhy),
        point(Icons.account_balance_outlined, l.consentWho),
        point(Icons.send_outlined, l.consentWhat),
        point(Icons.check_circle_outline_rounded, l.consentResult),
        point(Icons.lock_outline_rounded, l.consentKeep),
        point(Icons.schedule_outlined, l.consentRetention),
        point(Icons.pan_tool_alt_outlined, l.consentWithdraw),
      ]),
      // Always in reach, whatever the screen size: the box, then the buttons.
      bottomNavigationBar: SafeArea(
        child: Material(
          color: sb.surface,
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s2, SbLayout.edge(context), SbSpace.s3),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(l.consentCheckbox, style: t.bodySmall),
              ),
              Text(l.consentVersion(widget.consentVersion), style: t.labelSmall?.copyWith(color: sb.textSecondary)),
              const SizedBox(height: SbSpace.s2),
              Row(children: [
                Expanded(child: SbButton(label: l.cancel, variant: SbButtonVariant.secondary, expand: true, onPressed: () => Navigator.of(context).pop(false))),
                const SizedBox(width: SbSpace.s2),
                Expanded(child: SbButton(label: l.consentAgree, icon: Icons.check_rounded, expand: true, onPressed: _agreed ? () => Navigator.of(context).pop(true) : null)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
