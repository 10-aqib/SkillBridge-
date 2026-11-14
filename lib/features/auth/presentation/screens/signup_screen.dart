import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/role_choice_card.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Client and worker registration (email + password, or Google with the chosen
/// role). Only client/worker can be chosen; the router then sends new clients
/// to onboarding and new workers to profile setup.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.initialRole});

  /// 'client' or 'worker' (from /signup?role=…). Anything else → client.
  final String? initialRole;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late String _role;
  bool _agreed = false;
  bool _showAgreeError = false;

  @override
  void initState() {
    super.initState();
    _role = UserRoles.isSelfService(widget.initialRole) ? widget.initialRole! : UserRoles.client;
    // Don't carry over an error from another screen (e.g. a failed sign-in).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(registerViewModelProvider.notifier).clearError();
      ref.read(loginViewModelProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _showAgreeError = !_agreed);
    if (!valid || !_agreed) return;
    ref.read(registerViewModelProvider.notifier).register(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim(),
          phoneNumber: PakPhone.normalize(_phone.text)!,
          role: _role,
        );
  }

  void _google() {
    if (!_agreed) {
      setState(() => _showAgreeError = true);
      return;
    }
    ref.read(loginViewModelProvider.notifier).loginWithGoogle(role: _role);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = AuthValidators(l);
    final t = Theme.of(context).textTheme;
    final reg = ref.watch(registerViewModelProvider);
    final google = ref.watch(loginViewModelProvider);
    final busy = reg.isLoading || google.isLoading;
    final isWorker = _role == UserRoles.worker;

    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.needsRole && !(prev?.needsRole ?? false)) {
        ref.read(loginViewModelProvider.notifier).consumeNeedsRole();
        context.go(RouteNames.roleSelectionPath);
      }
    });

    return AuthScaffold(
      onBack: context.canPop() ? () => context.pop() : () => context.go(RouteNames.welcomePath),
      title: isWorker ? l.signupTitleWorker : l.signupTitleClient,
      subtitle: isWorker ? l.signupSubtitleWorker : l.signupSubtitleClient,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SbFailureBanner(failure: reg.failure ?? google.failure),
            Semantics(header: true, child: Text(l.signupRoleQuestion, style: t.labelLarge)),
            const SizedBox(height: SbSpace.s2),
            RoleChoiceGroup(
              value: _role,
              enabled: !busy,
              onChanged: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: SbSpace.s6),
            SbTextField(
              label: l.signupNameLabel,
              hint: l.signupNameHint,
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              prefixIcon: Icons.person_outline_rounded,
              validator: v.name,
              enabled: !busy,
              autovalidateMode: AutovalidateMode.disabled,
            ),
            const SizedBox(height: SbSpace.s4),
            SbTextField(
              label: l.email,
              hint: l.authEmailHint,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              prefixIcon: Icons.mail_outline_rounded,
              validator: v.email,
              enabled: !busy,
              autovalidateMode: AutovalidateMode.disabled,
            ),
            const SizedBox(height: SbSpace.s4),
            SbTextField(
              label: l.signupPhoneLabel,
              hint: l.signupPhoneHint,
              helper: l.signupPhoneHelp,
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: PakPhone.inputFormatters,
              prefixText: '+92',
              validator: v.phone,
              enabled: !busy,
              autovalidateMode: AutovalidateMode.disabled,
            ),
            const SizedBox(height: SbSpace.s4),
            SbPasswordField(
              label: l.password,
              helper: l.signupPasswordHelp,
              controller: _password,
              validator: v.newPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: SbSpace.s4),
            SbPasswordField(
              label: l.signupConfirmPasswordLabel,
              controller: _confirm,
              validator: v.confirm(_password),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: SbSpace.s4),
            _AgreeRow(
              value: _agreed,
              showError: _showAgreeError,
              onChanged: busy ? null : (val) => setState(() {
                    _agreed = val;
                    if (val) _showAgreeError = false;
                  }),
            ),
            const SizedBox(height: SbSpace.s4),
            SbButton(
              label: l.signupButton,
              expand: true,
              isLoading: reg.isLoading,
              loadingSemanticLabel: l.signupCreating,
              onPressed: google.isLoading ? null : _submit,
            ),
            const SbOrDivider(),
            SbGoogleButton(isLoading: google.isLoading, onPressed: reg.isLoading ? null : _google),
            const SizedBox(height: SbSpace.s6),
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l.signupHaveAccount, style: t.bodyMedium),
              TextButton(
                onPressed: busy ? null : () => context.pushReplacement(RouteNames.loginPath),
                child: Text(l.loginButton),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _AgreeRow extends StatelessWidget {
  const _AgreeRow({required this.value, required this.showError, required this.onChanged});

  final bool value;
  final bool showError;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MergeSemantics(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Checkbox(value: value, onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false)),
          Expanded(
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: Text(l.signupAgree, style: t.bodyMedium),
            ),
          ),
          TextButton(
            onPressed: () => context.push(RouteNames.termsAndConditionsPath),
            child: Text(l.signupReadTerms),
          ),
        ]),
      ),
      if (showError)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: SbSpace.s3),
          child: Semantics(
            liveRegion: true,
            child: Text(l.signupAgreeRequired, style: t.bodySmall!.copyWith(color: c.error)),
          ),
        ),
    ]);
  }
}
