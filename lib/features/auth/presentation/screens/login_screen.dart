import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';

/// Email/password and Google sign-in. Successful sign-in is routed by the
/// router (role-aware); a Firebase account without a profile goes to role
/// selection instead of creating a second account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Don't carry over an error from another screen (e.g. Google on Welcome).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(loginViewModelProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(loginViewModelProvider.notifier).login(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = AuthValidators(l);
    final state = ref.watch(loginViewModelProvider);

    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.needsRole && !(prev?.needsRole ?? false)) {
        ref.read(loginViewModelProvider.notifier).consumeNeedsRole();
        context.go(RouteNames.roleSelectionPath);
      }
    });

    return AuthScaffold(
      onBack: context.canPop() ? () => context.pop() : () => context.go(RouteNames.welcomePath),
      header: const Row(children: [
        SbBrandMark(size: 44),
        SizedBox(width: SbSpace.s3),
        SbWordmark(fontSize: 22),
      ]),
      title: l.loginTitle,
      subtitle: l.loginSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SbFailureBanner(failure: state.failure),
            SbTextField(
              label: l.email,
              hint: l.authEmailHint,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              prefixIcon: Icons.mail_outline_rounded,
              validator: v.email,
              autovalidateMode: AutovalidateMode.disabled,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: SbSpace.s4),
            SbPasswordField(
              label: l.password,
              controller: _password,
              validator: v.passwordPresent,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: state.isLoading ? null : () => context.push(RouteNames.forgotPasswordPath),
                child: Text(l.loginForgotPassword),
              ),
            ),
            const SizedBox(height: SbSpace.s2),
            SbButton(
              label: l.loginButton,
              expand: true,
              isLoading: state.isLoading,
              loadingSemanticLabel: l.loginSigningIn,
              onPressed: _submit,
            ),
            const SbOrDivider(),
            SbGoogleButton(
              isLoading: state.isLoading,
              onPressed: () => ref.read(loginViewModelProvider.notifier).loginWithGoogle(),
            ),
            const SizedBox(height: SbSpace.s6),
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l.loginNoAccount, style: Theme.of(context).textTheme.bodyMedium),
              TextButton(
                onPressed: state.isLoading ? null : () => context.push(RouteNames.signupPath),
                child: Text(l.welcomeCreateAccount),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
