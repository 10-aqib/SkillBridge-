import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';

/// Edit client details. Email is shown read-only: it is the Firebase sign-in
/// identity, so changing it only in Firestore (as the old sheet did) would
/// make the two disagree.
class EditClientProfileScreen extends ConsumerStatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  ConsumerState<EditClientProfileScreen> createState() => _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends ConsumerState<EditClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _city;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = ref.read(currentUserProvider);
    if (u == null || _saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final phone = PakPhone.normalize(_phone.text);
    final result = await ref.read(updateUserProfileUseCaseProvider).call(uid: u.uid, data: {
      'displayName': _name.text.trim(),
      'phoneNumber': phone ?? '',
      // A changed number is no longer verified.
      if ((phone ?? '') != u.phoneNumber) 'isPhoneVerified': false,
      'city': ?_city,
      'address': _address.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    final l = context.l10n;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profileSaveFailed), backgroundColor: context.sb.error),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.profileSaved)));
        if (context.canPop()) context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = AuthValidators(l);
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_loaded) {
      _loaded = true;
      _name.text = user.displayName;
      _phone.text = PakPhone.toLocalDisplay(user.phoneNumber);
      _address.text = user.address ?? '';
      _city = user.city;
    }

    return AuthScaffold(
      onBack: () => context.canPop() ? context.pop() : null,
      title: l.editProfile,
      footer: SbButton(label: l.save, expand: true, isLoading: _saving, onPressed: _save),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: ProfilePhotoPicker(user: user, size: 104)),
          const SizedBox(height: SbSpace.s6),
          SbTextField(
            label: l.signupNameLabel,
            controller: _name,
            validator: v.name,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: SbSpace.s4),
          SbTextField(
            label: l.signupPhoneLabel,
            hint: l.signupPhoneHint,
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: PakPhone.inputFormatters,
            prefixText: '+92',
            validator: v.optionalPhone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: SbSpace.s4),
          CityDropdown(value: _city, onChanged: (c) => setState(() => _city = c)),
          const SizedBox(height: SbSpace.s4),
          SbTextField(
            label: l.profileAreaLabel,
            hint: l.profileAreaHint,
            helper: l.profileAreaHelp,
            controller: _address,
            optionalLabel: l.profileOptional,
            prefixIcon: Icons.place_outlined,
          ),
          const SizedBox(height: SbSpace.s4),
          ProfileInfoRow(icon: Icons.mail_outline_rounded, label: l.email, value: user.email),
          Text(l.profileEmailReadOnly, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
