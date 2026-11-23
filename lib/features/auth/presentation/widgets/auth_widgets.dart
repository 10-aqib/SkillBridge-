import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/core/errors/failure.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';
import 'package:skill_bridge/shared/widgets/google_logo.dart';
import 'package:skill_bridge/core/constants/app_constants.dart';

/// Page frame for auth and onboarding: keyboard-safe scrolling, readable max
/// width on tablets, consistent edges, optional back button and sticky footer.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onBack,
    this.footer,
    this.header,
    this.actions,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// Shows a back button when set.
  final VoidCallback? onBack;

  /// Pinned under the content (primary action area).
  final Widget? footer;

  /// Above the title (e.g. a step indicator).
  final Widget? header;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final edge = SbLayout.edge(context);
    final showBar = onBack != null || (actions?.isNotEmpty ?? false);
    return Scaffold(
      appBar: showBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: onBack == null
                  ? null
                  : IconButton(
                      icon: const BackButtonIcon(),
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: onBack,
                    ),
              actions: actions,
            )
          : null,
      body: SafeArea(
        top: !showBar,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(edge, showBar ? SbSpace.s2 : SbSpace.s8, edge, SbSpace.s6),
                child: SbReadableWidth(
                  maxWidth: 480,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null) ...[header!, const SizedBox(height: SbSpace.s5)],
                      if (title != null)
                        Semantics(header: true, child: Text(title!, style: t.headlineSmall)),
                      if (subtitle != null) ...[
                        const SizedBox(height: SbSpace.s2),
                        Text(subtitle!, style: t.bodyLarge!.copyWith(color: c.textSecondary)),
                      ],
                      if (title != null || subtitle != null) const SizedBox(height: SbSpace.s6),
                      child,
                    ],
                  ),
                ),
              ),
            ),
            if (footer != null)
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s3),
                child: SbReadableWidth(maxWidth: 480, child: footer!),
              ),
          ],
        ),
      ),
    );
  }
}

/// The app icon mark on its white tile (see [SbLogoMark]).
class SbBrandMark extends StatelessWidget {
  const SbBrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) => SbLogoMark(size: size);
}

/// Password input with a show/hide toggle that announces its state.
class SbPasswordField extends StatefulWidget {
  const SbPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.helper,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? helper;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<SbPasswordField> createState() => _SbPasswordFieldState();
}

class _SbPasswordFieldState extends State<SbPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SbTextField(
      label: widget.label,
      controller: widget.controller,
      validator: widget.validator,
      helper: widget.helper,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      prefixIcon: Icons.lock_outline_rounded,
      autovalidateMode: AutovalidateMode.disabled,
      suffix: IconButton(
        tooltip: _obscure ? l.authShowPassword : l.authHidePassword,
        icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// "Continue with Google" — Firebase Authentication with the Google provider.
class SbGoogleButton extends StatelessWidget {
  const SbGoogleButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    return SizedBox(
      height: SbTarget.mobile,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.text,
          side: BorderSide(color: c.borderStrong),
        ),
        child: isLoading
            ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.25, color: c.primary))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(size: 18),
                  const SizedBox(width: SbSpace.s3),
                  Flexible(child: Text(context.l10n.authContinueWithGoogle, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// "—— or ——" separator.
class SbOrDivider extends StatelessWidget {
  const SbOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SbSpace.s5),
      child: Row(children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3),
          child: Text(context.l10n.authOr, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: c.border)),
      ]),
    );
  }
}

/// Step indicator for onboarding ("Step 2 of 5 · Your work").
class SbStepProgress extends StatelessWidget {
  const SbStepProgress({super.key, required this.step, required this.total, required this.label});

  /// 1-based.
  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: context.l10n.onboardingStepOf(step, total, label),
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.onboardingStepOf(step, total, label),
            style: t.labelMedium!.copyWith(color: c.textSecondary)),
        const SizedBox(height: SbSpace.s2),
        Row(children: [
          for (var i = 1; i <= total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: SbMotion.of(context, SbMotion.base),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? c.primary : c.primarySubtle,
                  borderRadius: BorderRadius.circular(SbRadius.full),
                ),
              ),
            ),
            if (i < total) const SizedBox(width: SbSpace.s1),
          ],
        ]),
      ]),
    );
  }
}

/// Error banner showing a localized message for a failure.
class SbFailureBanner extends StatelessWidget {
  const SbFailureBanner({super.key, required this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    if (f == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: SbSpace.s4),
      child: SbInlineBanner(message: authErrorText(context.l10n, f), tone: SbTone.error),
    );
  }
}

/// Maps Firebase/app failure codes to friendly, localized copy. Raw exception
/// text is never shown.
String authErrorText(AppLocalizations l, Failure failure) {
  if (failure is NetworkFailure) {
    return failure.message.toLowerCase().contains('timed out') ? l.errTimeout : l.errNetwork;
  }
  final code = failure is AuthFailure ? failure.code : null;
  switch (code) {
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
    case 'wrong-password':
    case 'user-not-found':
      return l.errInvalidCredential;
    case 'email-already-in-use':
      return l.errEmailInUse;
    case 'weak-password':
      return l.validationPasswordWeak;
    case 'invalid-email':
      return l.validationEmailInvalid;
    case 'user-disabled':
      return l.errUserDisabled;
    case 'suspended':
      return l.errSuspended;
    case 'too-many-requests':
      return l.errTooManyRequests;
    case 'network-request-failed':
      return l.errNetwork;
    case 'account-exists-with-different-credential':
      return l.errAccountExistsDifferent;
    case 'operation-not-allowed':
      return l.errOperationNotAllowed;
    case 'role-locked':
      return l.errRoleLocked;
    case 'invalid-role':
      return l.roleSelectRequired;
    case 'requires-recent-login':
    case 'no-current-user':
      return l.errSignInAgain;
  }
  if (failure.message.toLowerCase().contains('suspended')) return l.errSuspended;
  return l.errGeneric;
}

/// Localized form validators.
class AuthValidators {
  AuthValidators(this.l);
  final AppLocalizations l;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l.validationEmailRequired;
    if (value.length > 254 || !_email.hasMatch(value)) return l.validationEmailInvalid;
    return null;
  }

  /// Sign-in: also accepts the staff address (no dot after the @).
  String? loginEmail(String? v) => AppConstants.isStaffEmail(v) ? null : email(v);

  /// Password reset: never for a staff account.
  String? resetEmail(String? v) => AppConstants.isStaffEmail(v) ? l.staffResetBlocked : email(v);

  String? passwordPresent(String? v) => (v == null || v.isEmpty) ? l.validationPasswordRequired : null;

  /// New passwords: 8+ characters and at least one number.
  String? newPassword(String? v) {
    if (v == null || v.isEmpty) return l.validationPasswordRequired;
    if (v.length < 8 || v.length > 128 || !RegExp(r'\d').hasMatch(v)) return l.validationPasswordWeak;
    return null;
  }

  String? Function(String?) confirm(TextEditingController other) =>
      (v) => (v == null || v.isEmpty)
          ? l.validationPasswordRequired
          : (v != other.text ? l.validationPasswordMismatch : null);

  String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l.validationNameRequired;
    if (value.length < 2 || value.length > 60) return l.validationNameLength;
    return null;
  }

  String? phone(String? v) => PakPhone.normalize(v) == null ? l.validationPhoneInvalid : null;

  String? optionalPhone(String? v) => (v == null || v.trim().isEmpty) ? null : phone(v);
}

/// Pakistani mobile numbers: accepts 03001234567, 3001234567, +923001234567,
/// 923001234567 (spaces/dashes allowed). Stored as +923001234567.
abstract final class PakPhone {
  static String? normalize(String? input) {
    if (input == null) return null;
    var d = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (d.startsWith('+92')) {
      d = d.substring(3);
    } else if (d.startsWith('0092')) {
      d = d.substring(4);
    } else if (d.startsWith('92') && d.length == 12) {
      d = d.substring(2);
    } else if (d.startsWith('0')) {
      d = d.substring(1);
    }
    if (!RegExp(r'^3\d{9}$').hasMatch(d)) return null;
    return '+92$d';
  }

  /// For display/editing: "+923001234567" → "300 1234567".
  static String toLocalDisplay(String? stored) {
    final n = normalize(stored);
    if (n == null) return stored ?? '';
    final d = n.substring(3);
    return '${d.substring(0, 3)} ${d.substring(3)}';
  }

  static List<TextInputFormatter> get inputFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
        LengthLimitingTextInputFormatter(16),
      ];
}

/// Countdown for "Resend in 42s" buttons.
class ResendCooldown {
  ResendCooldown(this.onTick);

  final VoidCallback onTick;
  Timer? _timer;
  int remaining = 0;

  void start([int seconds = 60]) {
    _timer?.cancel();
    remaining = seconds;
    onTick();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      if (remaining <= 0) {
        remaining = 0;
        t.cancel();
      }
      onTick();
    });
  }

  void dispose() => _timer?.cancel();
}
