import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// CNIC entry (CNICInputScreen): masked XXXXX-XXXXXXX-X, digits only, 13
/// exactly. Returns the formatted CNIC. In test mode it lists the synthetic
/// identities (the simulator accepts nothing else).
class CnicInputScreen extends StatefulWidget {
  const CnicInputScreen({super.key, required this.test});
  final bool test;

  @override
  State<CnicInputScreen> createState() => _CnicInputScreenState();
}

class _CnicInputScreenState extends State<CnicInputScreen> {
  final _ctrl = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (!CnicValidation.isValid(_ctrl.text)) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(CnicValidation.format(CnicValidation.digitsOf(_ctrl.text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.cnicTitle)),
      body: ListView(padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s4, SbLayout.edge(context), SbSpace.s8), children: [
        if (widget.test) ...[
          SbInlineBanner(message: l.identityTestBanner, tone: SbTone.warning, icon: Icons.science_outlined),
          const SizedBox(height: SbSpace.s4),
        ],
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          // Not remembered by keyboards or autofill.
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), CnicInputFormatter()],
          onChanged: (_) {
            if (_showError) setState(() => _showError = false);
          },
          onSubmitted: (_) => _continue(),
          decoration: InputDecoration(
            labelText: l.cnicLabel,
            hintText: l.cnicHint,
            errorText: _showError ? l.cnicInvalid : null,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: SbSpace.s2),
        Text(l.cnicHelp, style: t.bodySmall),
        const SizedBox(height: SbSpace.s4),
        SbButton(label: l.identityContinue, icon: Icons.arrow_forward_rounded, expand: true, onPressed: _continue),
        if (widget.test) ...[
          const SizedBox(height: SbSpace.s4),
          Text(l.cnicTestOnly, style: t.labelLarge),
          const SizedBox(height: SbSpace.s1),
          for (final (cnic, label) in CnicValidation.syntheticTestCnics)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.science_outlined),
              title: Text(cnic, textDirection: TextDirection.ltr),
              subtitle: Text(label),
              onTap: () => setState(() {
                _ctrl.text = cnic;
                _showError = false;
              }),
            ),
        ],
      ]),
    );
  }
}
