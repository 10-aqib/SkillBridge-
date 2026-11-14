import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Phone number verification (Firebase phone auth, linked to the signed-in
/// account). Opened from the profile. One 6-digit field supports SMS autofill
/// and paste, and is read as a single input by screen readers.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  /// +92… format.
  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _code = TextEditingController();
  late final ResendCooldown _cooldown = ResendCooldown(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _cooldown.dispose();
    _code.dispose();
    super.dispose();
  }

  void _send() {
    ref.read(otpViewModelProvider.notifier).sendOtp(phoneNumber: widget.phoneNumber);
    _cooldown.start();
  }

  void _verify() {
    final code = _code.text.trim();
    if (code.length != 6) return;
    ref.read(otpViewModelProvider.notifier).verifyOtp(smsCode: code);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(otpViewModelProvider);

    ref.listen<OtpState>(otpViewModelProvider, (prev, next) {
      if (next.isVerified && !(prev?.isVerified ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.otpVerified)));
        if (context.canPop()) context.pop(true);
      }
    });

    final waiting = _cooldown.remaining > 0;
    return AuthScaffold(
      onBack: context.canPop() ? () => context.pop(false) : null,
      title: l.otpTitle,
      subtitle: l.otpSubtitle(PakPhone.toLocalDisplay(widget.phoneNumber)),
      footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbButton(
          label: l.otpVerify,
          expand: true,
          isLoading: state.isVerifying,
          onPressed: state.isSending ? null : _verify,
        ),
        SbButton(
          label: waiting ? l.forgotResendIn(_cooldown.remaining) : l.otpResend,
          variant: SbButtonVariant.quiet,
          expand: true,
          isLoading: state.isSending,
          onPressed: waiting || state.isVerifying ? null : _send,
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: SbSpace.s4),
            child: SbInlineBanner(message: l.otpError, tone: SbTone.error),
          ),
        if (state.otpSent && state.errorMessage == null)
          Padding(
            padding: const EdgeInsets.only(bottom: SbSpace.s4),
            child: SbInlineBanner(message: l.otpSent, tone: SbTone.info),
          ),
        SbTextField(
          label: l.otpCodeLabel,
          hint: '••••••',
          controller: _code,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          onChanged: (v) {
            if (v.length == 6) _verify();
          },
          onSubmitted: (_) => _verify(),
        ),
      ]),
    );
  }
}
