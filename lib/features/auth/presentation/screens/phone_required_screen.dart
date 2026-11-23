import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/auth_redirect.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Required phone number step. Shown after sign-up, after a Google sign-in,
/// and whenever the stored number is not confirmed yet (for example after
/// changing it). The person types their Pakistani mobile number, gets a
/// 6-digit SMS code, and enters it on the next screen. Until then the router
/// keeps them here (see `resolveAuthRedirect`).
class PhoneRequiredScreen extends ConsumerStatefulWidget {
  const PhoneRequiredScreen({super.key});

  @override
  ConsumerState<PhoneRequiredScreen> createState() => _PhoneRequiredScreenState();
}

class _PhoneRequiredScreenState extends ConsumerState<PhoneRequiredScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _prefilled = false;
  bool _signingOut = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = PakPhone.normalize(_phone.text)!;
    final ok = await context.push<bool>(RouteNames.otpPath, extra: phone);
    if (ok != true || !mounted) return;
    // Confirmed: carry on to onboarding/home. (The router also does this as
    // soon as the saved profile says the number is verified.)
    final user = ref.read(currentUserProvider);
    if (user != null) context.go(homePathFor(user));
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(signOutUseCaseProvider).call();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (!_prefilled && user != null) {
      _prefilled = true;
      final stored = PakPhone.normalize(user.phoneNumber);
      if (stored != null) _phone.text = PakPhone.toLocalDisplay(stored);
    }

    return AuthScaffold(
      title: l.phoneRequiredTitle,
      subtitle: l.phoneRequiredSubtitle,
      footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbButton(label: l.phoneRequiredSend, icon: Icons.sms_outlined, expand: true, onPressed: _signingOut ? null : _sendCode),
        SbButton(
          label: l.phoneRequiredSignOut,
          variant: SbButtonVariant.quiet,
          expand: true,
          isLoading: _signingOut,
          onPressed: _signingOut ? null : _signOut,
        ),
      ]),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (user != null && user.email.isNotEmpty) ...[
            Text(l.phoneRequiredSignedInAs(user.email), style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.sb.textSecondary)),
            const SizedBox(height: SbSpace.s4),
          ],
          SbTextField(
            label: l.signupPhoneLabel,
            hint: l.signupPhoneHint,
            helper: l.phoneRequiredHelp,
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: PakPhone.inputFormatters,
            prefixText: '+92',
            validator: (v) => PakPhone.normalize(v) == null ? l.phoneRequiredInvalid : null,
            onSubmitted: (_) => _sendCode(),
          ),
        ]),
      ),
    );
  }
}
