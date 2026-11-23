import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/auth_redirect.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/features/auth/presentation/providers/phone_later.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

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
    _leave();
  }

  /// Back to where the person came from (their profile), or on to
  /// onboarding/home when this was the step after signing in.
  void _leave() {
    if (context.canPop()) {
      context.pop(true);
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user != null) context.go(homePathFor(user));
  }

  void _later() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    ref.read(phoneLaterProvider.notifier).defer(user.uid);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.phoneLaterNote)));
    _leave();
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
      onBack: context.canPop() ? () => context.pop() : null,
      title: l.phoneRequiredTitle,
      subtitle: l.phoneRequiredSubtitle,
      footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbButton(label: l.phoneRequiredSend, icon: Icons.sms_outlined, expand: true, onPressed: _signingOut ? null : _sendCode),
        SbButton(
          label: l.phoneRequiredLater,
          variant: SbButtonVariant.secondary,
          expand: true,
          onPressed: _signingOut ? null : _later,
        ),
        if (!context.canPop())
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

/// On a person's own profile while their phone number isn't confirmed (for
/// example after "Add later"): opens the phone number step.
class PhonePromptCard extends StatelessWidget {
  const PhonePromptCard({super.key, required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    if (user.isPhoneVerified) return const SizedBox.shrink();
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    return Padding(
      padding: const EdgeInsets.only(bottom: SbSpace.s4),
      child: Material(
        color: sb.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SbRadius.card), side: BorderSide(color: sb.border)),
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Row(children: [
            Icon(Icons.phone_iphone_rounded, color: sb.primary),
            const SizedBox(width: SbSpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.phonePromptTitle, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(l.phonePromptBody, style: t.bodySmall!.copyWith(color: sb.textSecondary)),
              ]),
            ),
            const SizedBox(width: SbSpace.s2),
            SbButton(label: l.phonePromptAction, onPressed: () => context.push(RouteNames.phoneRequiredPath)),
          ]),
        ),
      ),
    );
  }
}
