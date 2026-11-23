import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/core/utils/geohash_util.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/location_picker_screen.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';

/// Worker onboarding and profile editing in five short steps. Each step is
/// saved as soon as it is completed, so nothing is lost if the app closes.
/// Staff-controlled fields (verification, ratings, earnings) are carried over
/// unchanged; nothing is invented (no default rate, city, category or skills).
class WorkerProfileSetupScreen extends ConsumerStatefulWidget {
  const WorkerProfileSetupScreen({super.key, this.initialStep});

  /// 1–5. When set, the screen edits just that step and returns afterwards.
  final int? initialStep;

  @override
  ConsumerState<WorkerProfileSetupScreen> createState() => _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends ConsumerState<WorkerProfileSetupScreen> {
  static const int steps = 5;
  late int _step = (widget.initialStep ?? 1).clamp(1, steps);
  bool get _editing => widget.initialStep != null;
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  final _forms = List.generate(steps, (_) => GlobalKey<FormState>());
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _experience = TextEditingController();
  final _hourly = TextEditingController();
  final _daily = TextEditingController();
  final _customSkill = TextEditingController();

  String? _categoryId;
  final List<String> _skills = [];
  final List<String> _languages = [];
  String? _city;
  LocationResult? _location;
  double _radius = 10;
  bool _showCategoryError = false;
  bool _showSkillsError = false;

  static const _languageOptions = ['Urdu', 'English', 'Punjabi', 'Sindhi', 'Pashto', 'Saraiki', 'Balochi'];
  static const Map<String, List<String>> _skillSuggestions = PakistanConstants.skillSuggestions;

  @override
  void dispose() {
    for (final c in [_name, _phone, _headline, _bio, _experience, _hourly, _daily, _customSkill]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(UserEntity u) {
    if (_loaded) return;
    _loaded = true;
    _name.text = u.displayName;
    _phone.text = PakPhone.toLocalDisplay(u.phoneNumber);
    final p = u.workerProfile;
    _city = p?.city.isNotEmpty == true ? p!.city : u.city;
    if (p == null) return;
    _headline.text = p.headline;
    _bio.text = p.bio;
    if (p.experience > 0) _experience.text = '${p.experience}';
    if (p.hourlyRate > 0) _hourly.text = p.hourlyRate.toStringAsFixed(0);
    if (p.dailyRate > 0) _daily.text = p.dailyRate.toStringAsFixed(0);
    _skills.addAll(p.skills);
    _languages.addAll(p.languages);
    _radius = p.serviceRadius.clamp(1, 50).toDouble();
    // Match by id, or by name for profiles saved before ids were used.
    for (final cat in PakistanConstants.categories) {
      if (cat['id'] == p.categoryId || (cat['name'] as String).toLowerCase() == p.categoryName.toLowerCase()) {
        _categoryId = cat['id'] as String;
      }
    }
    if (p.location != null && (p.address ?? '').isNotEmpty) {
      _location = LocationResult(
        latitude: p.location!.latitude,
        longitude: p.location!.longitude,
        formattedAddress: p.address!,
        city: p.city,
        accuracy: LocationAccuracyLevel.unknown,
      );
    }
  }

  /// Current workerProfile as a map (protected fields kept exactly), or a
  /// fresh one with verification/ratings at their honest starting values.
  Map<String, dynamic> _baseProfile(UserEntity u) {
    final existing = u.workerProfile;
    if (existing != null) return WorkerProfileModel.fromEntity(existing).toMap();
    return const WorkerProfileModel(headline: '', bio: '', categoryId: '', categoryName: '', city: '').toMap();
  }

  Future<bool> _save(UserEntity u, {Map<String, dynamic> root = const {}, Map<String, dynamic> profile = const {}}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{...root};
    if (profile.isNotEmpty) data['workerProfile'] = {..._baseProfile(u), ...profile};
    final result = await ref.read(updateUserProfileUseCaseProvider).call(uid: u.uid, data: data);
    if (!mounted) return false;
    setState(() => _saving = false);
    return result.fold((_) {
      setState(() => _error = context.l10n.profileSaveFailed);
      return false;
    }, (_) => true);
  }

  Future<bool> _saveStep(UserEntity u) async {
    switch (_step) {
      case 1:
        final phone = PakPhone.normalize(_phone.text);
        return _save(u, root: {
          'displayName': _name.text.trim(),
          'phoneNumber': phone ?? '',
          if ((phone ?? '') != u.phoneNumber) 'isPhoneVerified': false,
        });
      case 2:
        final cat = PakistanConstants.categories.firstWhere((c) => c['id'] == _categoryId);
        return _save(u, profile: {
          'headline': _headline.text.trim(),
          'bio': _bio.text.trim(),
          'categoryId': cat['id'],
          'categoryName': cat['name'],
          'skills': List<String>.from(_skills),
          'experience': int.parse(_experience.text.trim()),
          'languages': List<String>.from(_languages),
        });
      case 3:
        final loc = _location;
        final city = loc?.city.isNotEmpty == true ? loc!.city : (_city ?? '');
        return _save(u, root: {
          if (city.isNotEmpty) 'city': city,
          // Same shape as before so nearby search keeps working.
          if (loc != null) ...{
            'location': GeoPoint(loc.latitude, loc.longitude),
            'geohash': GeohashUtil.encode(loc.latitude, loc.longitude),
            'locationAccuracy': loc.accuracy.toString(),
            'locationAddress': loc.formattedAddress,
            'locationVisibility': 'public',
          },
        }, profile: {
          'hourlyRate': double.tryParse(_hourly.text.trim()) ?? 0,
          'dailyRate': double.tryParse(_daily.text.trim()) ?? 0,
          'city': city,
          'serviceRadius': _radius,
          if (loc != null) ...{
            'address': loc.formattedAddress,
            'location': GeoPoint(loc.latitude, loc.longitude),
          },
        });
      default:
        return true; // portfolio and verification save themselves
    }
  }

  bool _validate() {
    final formOk = _forms[_step - 1].currentState?.validate() ?? true;
    if (_step == 2) {
      setState(() {
        _showCategoryError = _categoryId == null;
        _showSkillsError = _skills.isEmpty;
      });
      return formOk && _categoryId != null && _skills.isNotEmpty;
    }
    if (_step == 3 && _location == null && _city == null) {
      setState(() => _error = context.l10n.workerSetupAreaRequired);
      return false;
    }
    return formOk;
  }

  Future<void> _continue(UserEntity u) async {
    if (_saving || !_validate()) return;
    if (!await _saveStep(u) || !mounted) return;
    if (_editing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
      context.canPop() ? context.pop() : context.go(RouteNames.workerProfilePath);
    } else if (_step < steps) {
      setState(() => _step++);
    } else {
      context.go(RouteNames.workerHomePath);
    }
  }

  Future<void> _pickLocation() async {
    final initial = _location;
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _location = result;
        if (result.city.isNotEmpty && PakistanConstants.majorCities.contains(result.city)) _city = result.city;
        _error = null;
      });
    } else if (initial == null && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _prefill(user);

    final labels = [l.onboardingStepYou, l.workerSetupStepWork, l.workerSetupStepRates, l.workerSetupStepPhotos, l.workerSetupStepVerify];
    final titles = [l.workerSetupYouTitle, l.workerSetupWorkTitle, l.workerSetupRatesTitle, l.workerSetupPhotosTitle, l.workerSetupVerifyTitle];
    final subtitles = [l.workerSetupYouBody, l.workerSetupWorkBody, l.workerSetupRatesBody, l.workerSetupPhotosBody, l.workerSetupVerifyBody];

    final String primaryLabel;
    if (_editing) {
      primaryLabel = l.save;
    } else if (_step == steps) {
      primaryLabel = l.onboardingFinish;
    } else {
      primaryLabel = l.workerSetupSaveContinue;
    }

    return AuthScaffold(
      onBack: _saving
          ? null
          : (_editing
              ? () => context.canPop() ? context.pop() : context.go(RouteNames.workerProfilePath)
              : (_step > 1 ? () => setState(() => _step--) : null)),
      header: _editing ? null : SbStepProgress(step: _step, total: steps, label: labels[_step - 1]),
      title: titles[_step - 1],
      subtitle: subtitles[_step - 1],
      footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[SbInlineBanner(message: _error!, tone: SbTone.error), const SizedBox(height: SbSpace.s3)],
        SbButton(label: primaryLabel, expand: true, isLoading: _saving, onPressed: () => _continue(user)),
        if (!_editing && (_step == 4 || _step == 5))
          SbButton(
            label: l.onboardingSkipStep,
            variant: SbButtonVariant.quiet,
            expand: true,
            onPressed: _saving ? null : () => _step < steps ? setState(() => _step++) : context.go(RouteNames.workerHomePath),
          ),
      ]),
      child: KeyedSubtree(key: ValueKey(_step), child: _stepBody(user)),
    );
  }

  Widget _stepBody(UserEntity user) {
    final l = context.l10n;
    final v = AuthValidators(l);
    final t = Theme.of(context).textTheme;
    final c = context.sb;

    switch (_step) {
      case 1:
        return Form(
          key: _forms[0],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: ProfilePhotoPicker(user: user, size: 112)),
            const SizedBox(height: SbSpace.s2),
            Center(child: Text(l.workerSetupPhotoHint, style: t.bodySmall, textAlign: TextAlign.center)),
            const SizedBox(height: SbSpace.s6),
            SbTextField(label: l.signupNameLabel, controller: _name, validator: v.name, prefixIcon: Icons.person_outline_rounded),
            const SizedBox(height: SbSpace.s4),
            SbTextField(
              label: l.signupPhoneLabel,
              hint: l.signupPhoneHint,
              helper: l.workerSetupPhoneHelp,
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: PakPhone.inputFormatters,
              prefixText: '+92',
              validator: v.phone,
            ),
          ]),
        );
      case 2:
        final suggestions = [
          ...?_skillSuggestions[_categoryId],
          ..._skills.where((s) => !(_skillSuggestions[_categoryId]?.contains(s) ?? false)),
        ];
        return Form(
          key: _forms[1],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SbTextField(
              label: l.workerSetupHeadlineLabel,
              hint: l.workerSetupHeadlineHint,
              controller: _headline,
              maxLength: 80,
              validator: (s) => (s ?? '').trim().length < 8 ? l.workerSetupHeadlineRequired : null,
            ),
            const SizedBox(height: SbSpace.s3),
            _Label(text: l.category, required: true),
            Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
              for (final cat in PakistanConstants.categories)
                ChoiceChip(
                  label: Text(context.isUrdu ? cat['urdu'] as String : cat['name'] as String),
                  avatar: Icon(cat['icon'] as IconData, size: 18),
                  selected: _categoryId == cat['id'],
                  onSelected: (_) => setState(() {
                    _categoryId = cat['id'] as String;
                    _showCategoryError = false;
                  }),
                ),
            ]),
            if (_showCategoryError) _ErrorText(l.workerSetupCategoryRequired),
            const SizedBox(height: SbSpace.s5),
            _Label(text: l.skills, required: true),
            if (suggestions.isNotEmpty)
              Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                for (final s in suggestions)
                  FilterChip(
                    label: Text(s),
                    selected: _skills.contains(s),
                    onSelected: (on) => setState(() {
                      on ? _skills.add(s) : _skills.remove(s);
                      _showSkillsError = false;
                    }),
                  ),
              ]),
            const SizedBox(height: SbSpace.s2),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: SbTextField(
                  label: l.workerSetupAddSkill,
                  hint: l.workerSetupAddSkillHint,
                  controller: _customSkill,
                  maxLength: 30,
                  onSubmitted: (_) => _addCustomSkill(),
                ),
              ),
              const SizedBox(width: SbSpace.s2),
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: SbButton(label: l.workerSetupAdd, size: SbButtonSize.compact, variant: SbButtonVariant.secondary, onPressed: _addCustomSkill),
              ),
            ]),
            if (_showSkillsError) _ErrorText(l.workerSetupSkillsRequired),
            const SizedBox(height: SbSpace.s3),
            SbTextField(
              label: l.workerSetupExperienceLabel,
              hint: '5',
              controller: _experience,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              validator: (s) {
                final n = int.tryParse(s ?? '');
                return (n == null || n > 60) ? l.workerSetupExperienceInvalid : null;
              },
            ),
            const SizedBox(height: SbSpace.s4),
            SbTextField(
              label: l.workerSetupBioLabel,
              hint: l.workerSetupBioHint,
              controller: _bio,
              maxLines: 5,
              maxLength: 600,
              validator: (s) => (s ?? '').trim().length < 30 ? l.workerSetupBioRequired : null,
            ),
            const SizedBox(height: SbSpace.s3),
            _Label(text: l.workerSetupLanguages, required: false),
            Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
              for (final lang in _languageOptions)
                FilterChip(
                  label: Text(lang),
                  selected: _languages.contains(lang),
                  onSelected: (on) => setState(() => on ? _languages.add(lang) : _languages.remove(lang)),
                ),
            ]),
          ]),
        );
      case 3:
        String? rate(String? s) => (s == null || s.isEmpty || (double.tryParse(s) ?? -1) > 0) ? null : l.workerSetupRateInvalid;
        return Form(
          key: _forms[2],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SbTextField(
              label: l.hourlyRate,
              hint: '800',
              optionalLabel: l.profileOptional,
              controller: _hourly,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              prefixText: 'Rs',
              validator: rate,
            ),
            const SizedBox(height: SbSpace.s4),
            SbTextField(
              label: l.dailyRate,
              hint: '5000',
              optionalLabel: l.profileOptional,
              controller: _daily,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
              prefixText: 'Rs',
              validator: rate,
            ),
            const SizedBox(height: SbSpace.s2),
            Text(l.workerSetupRateNote, style: t.bodySmall),
            const SizedBox(height: SbSpace.s5),
            _Label(text: l.workerSetupServiceArea, required: true),
            Container(
              padding: const EdgeInsets.all(SbSpace.s3),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(SbRadius.control),
              ),
              child: Row(children: [
                Icon(Icons.place_outlined, color: _location == null ? c.textSecondary : c.success),
                const SizedBox(width: SbSpace.s3),
                Expanded(child: Text(_location?.formattedAddress ?? l.workerSetupNoLocation, style: t.bodyMedium)),
                SbButton(
                  label: _location == null ? l.workerSetupPickLocation : l.verificationReplace,
                  size: SbButtonSize.compact,
                  variant: SbButtonVariant.secondary,
                  onPressed: _pickLocation,
                ),
              ]),
            ),
            const SizedBox(height: SbSpace.s4),
            CityDropdown(value: _city, onChanged: (v) => setState(() {
                  _city = v;
                  _error = null;
                })),
            const SizedBox(height: SbSpace.s4),
            Text(l.workerSetupRadius(_radius.round()), style: t.labelLarge),
            Slider(
              value: _radius,
              min: 1,
              max: 50,
              divisions: 49,
              label: l.workerSetupRadius(_radius.round()),
              onChanged: (v) => setState(() => _radius = v),
            ),
            Text(l.workerSetupLocationPrivacy, style: t.bodySmall),
          ]),
        );
      case 4:
        return PortfolioManager(user: user);
      default:
        final verified = user.workerProfile?.isVerified == true;
        final pending = user.workerProfile?.verificationStatus == 'pending';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (verified)
            SbInlineBanner(message: l.verificationVerifiedTitle, tone: SbTone.success, icon: Icons.verified_rounded)
          else if (pending)
            SbInlineBanner(message: l.verificationPendingTitle, tone: SbTone.warning)
          else ...[
            for (final line in [l.workerSetupVerifyPoint1, l.workerSetupVerifyPoint2, l.workerSetupVerifyPoint3])
              Padding(
                padding: const EdgeInsets.only(bottom: SbSpace.s2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20, color: c.success),
                  const SizedBox(width: SbSpace.s2),
                  Expanded(child: Text(line, style: t.bodyMedium)),
                ]),
              ),
            const SizedBox(height: SbSpace.s3),
            SbButton(
              label: l.workerSetupVerifyNow,
              variant: SbButtonVariant.secondary,
              icon: Icons.badge_outlined,
              expand: true,
              onPressed: () => context.push(RouteNames.getVerifiedPath),
            ),
          ],
        ]);
    }
  }

  void _addCustomSkill() {
    final s = _customSkill.text.trim();
    if (s.isEmpty || _skills.contains(s) || _skills.length >= 15) return;
    setState(() {
      _skills.add(s);
      _customSkill.clear();
      _showSkillsError = false;
    });
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: SbSpace.s2),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: text),
        if (!required) TextSpan(text: ' ${context.l10n.profileOptional}', style: t.bodySmall),
      ]), style: t.labelLarge),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: SbSpace.s2),
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.sb.error)),
        ),
      );
}
