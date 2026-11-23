import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';

/// First-run setup for new clients: photo + name, contact number, city/area.
/// Every step is optional; finishing or skipping marks onboarding complete so
/// it is never shown again. Only what the person enters is saved.
class ClientOnboardingScreen extends ConsumerStatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  ConsumerState<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends ConsumerState<ClientOnboardingScreen> {
  static const _steps = 3;
  int _step = 1;
  bool _saving = false;
  bool _prefilled = false;
  final _formKeys = List.generate(_steps, (_) => GlobalKey<FormState>());
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _city;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _prefill() {
    final u = ref.read(currentUserProvider);
    if (_prefilled || u == null) return;
    _prefilled = true;
    _name.text = u.displayName;
    _phone.text = PakPhone.toLocalDisplay(u.phoneNumber);
    _address.text = u.address ?? '';
    _city = u.city;
  }

  Future<void> _finish({required bool skipped}) async {
    final u = ref.read(currentUserProvider);
    if (u == null || _saving) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{'onboardingCompleted': true};
    if (!skipped) {
      final name = _name.text.trim();
      final phone = PakPhone.normalize(_phone.text);
      if (name.isNotEmpty) data['displayName'] = name;
      if (phone != null) data['phoneNumber'] = phone;
      if (phone != null && phone != u.phoneNumber) data['isPhoneVerified'] = false;
      if (_city != null) data['city'] = _city;
      if (_address.text.trim().isNotEmpty) data['address'] = _address.text.trim();
    }
    final result = await ref.read(updateUserProfileUseCaseProvider).call(uid: u.uid, data: data);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaveFailed), backgroundColor: context.sb.error),
      ),
      (_) => context.go(RouteNames.clientHomePath),
    );
  }

  void _next() {
    if (!(_formKeys[_step - 1].currentState?.validate() ?? true)) return;
    if (_step < _steps) {
      setState(() => _step++);
    } else {
      _finish(skipped: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = AuthValidators(l);
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _prefill();

    final labels = [l.onboardingStepYou, l.onboardingStepContact, l.onboardingStepLocation];
    final titles = [l.clientOnboardingYouTitle, l.clientOnboardingContactTitle, l.clientOnboardingLocationTitle];
    final subtitles = [l.clientOnboardingYouBody, l.clientOnboardingContactBody, l.clientOnboardingLocationBody];

    final body = switch (_step) {
      1 => Form(
          key: _formKeys[0],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: ProfilePhotoPicker(user: user, size: 112)),
            const SizedBox(height: SbSpace.s2),
            Center(child: Text(l.onboardingPhotoHint, style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: SbSpace.s6),
            SbTextField(
              label: l.signupNameLabel,
              controller: _name,
              validator: v.name,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              prefixIcon: Icons.person_outline_rounded,
            ),
          ]),
        ),
      2 => Form(
          key: _formKeys[1],
          child: SbTextField(
            label: l.signupPhoneLabel,
            hint: l.signupPhoneHint,
            helper: l.clientOnboardingPhoneHelp,
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: PakPhone.inputFormatters,
            prefixText: '+92',
            validator: v.optionalPhone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
        ),
      _ => Form(
          key: _formKeys[2],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CityDropdown(value: _city, onChanged: (c) => setState(() => _city = c)),
            const SizedBox(height: SbSpace.s4),
            SbTextField(
              label: l.profileAreaLabel,
              hint: l.profileAreaHint,
              helper: l.profileAreaHelp,
              controller: _address,
              optionalLabel: l.profileOptional,
              prefixIcon: Icons.place_outlined,
              textInputAction: TextInputAction.done,
            ),
          ]),
        ),
    };

    return AuthScaffold(
      onBack: _step > 1 && !_saving ? () => setState(() => _step--) : null,
      actions: [
        TextButton(onPressed: _saving ? null : () => _finish(skipped: true), child: Text(l.onboardingSkip)),
      ],
      header: SbStepProgress(step: _step, total: _steps, label: labels[_step - 1]),
      title: titles[_step - 1],
      subtitle: subtitles[_step - 1],
      footer: SbButton(
        label: _step == _steps ? l.onboardingFinish : l.continueText,
        expand: true,
        isLoading: _saving,
        onPressed: _next,
      ),
      child: AnimatedSwitcher(duration: SbMotion.of(context, SbMotion.base), child: KeyedSubtree(key: ValueKey(_step), child: body)),
    );
  }
}
