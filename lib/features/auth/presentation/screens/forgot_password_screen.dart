import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Password reset: Firebase emails a secure link; the new password is set on
/// Firebase's page, then the person signs in here. The confirmation never says
/// whether an account exists for the email (no account enumeration).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final ResendCooldown _cooldown = ResendCooldown(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    // Fresh state each time the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(forgotPasswordViewModelProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _cooldown.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    // Resend from the confirmation view reuses the already-validated email
    // (the form isn't on screen then).
    final resending = ref.read(forgotPasswordViewModelProvider).emailSent;
    if (!resending && !(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(forgotPasswordViewModelProvider.notifier).sendResetEmail(email: _email.text.trim());
    if (mounted && ref.read(forgotPasswordViewModelProvider).emailSent) _cooldown.start();
  }

  void _back() => context.canPop() ? context.pop() : context.go(RouteNames.loginPath);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final state = ref.watch(forgotPasswordViewModelProvider);

    if (state.emailSent) {
      final waiting = _cooldown.remaining > 0;
      return AuthScaffold(
        onBack: _back,
        footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SbButton(label: l.forgotBackToSignIn, expand: true, onPressed: () => context.go(RouteNames.loginPath)),
          SbButton(
            label: waiting ? l.forgotResendIn(_cooldown.remaining) : l.forgotResend,
            variant: SbButtonVariant.quiet,
            expand: true,
            isLoading: state.isLoading,
            onPressed: waiting ? null : _send,
          ),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SbStateView(
            kind: SbStateKind.success,
            icon: Icons.mark_email_read_outlined,
            title: l.forgotSentTitle,
            message: l.forgotSentBody(_email.text.trim()),
          ),
          SbFailureBanner(failure: state.failure),
          Text(l.forgotSentTip, style: t.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: SbSpace.s2),
          TextButton(
            onPressed: () => ref.read(forgotPasswordViewModelProvider.notifier).reset(),
            child: Text(l.forgotDifferentEmail),
          ),
        ]),
      );
    }

    return AuthScaffold(
      onBack: _back,
      title: l.forgotTitle,
      subtitle: l.forgotSubtitle,
      footer: SbButton(
        label: l.forgotSend,
        expand: true,
        isLoading: state.isLoading,
        loadingSemanticLabel: l.forgotSending,
        onPressed: _send,
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SbFailureBanner(failure: state.failure),
          SbTextField(
            label: l.email,
            hint: l.authEmailHint,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            prefixIcon: Icons.mail_outline_rounded,
            validator: AuthValidators(l).email,
            enabled: !state.isLoading,
            autovalidateMode: AutovalidateMode.disabled,
            onSubmitted: (_) => _send(),
          ),
        ]),
      ),
    );
  }
}
