import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/screens/worker_profile_detail_screen.dart' show workerRateLabel;
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';
import 'package:skill_bridge/shared/widgets/profile/reviews_section.dart';
import 'package:skill_bridge/features/identity/presentation/get_verified_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verified_badge.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';

/// What makes a worker profile convincing to clients, in the order to fix it.
class ProfileCompleteness {
  ProfileCompleteness(this.user);
  final UserEntity user;

  List<(bool done, String key)> get items {
    final p = user.workerProfile;
    return [
      ((user.photoUrl ?? '').isNotEmpty, 'photo'),
      (p != null && p.headline.isNotEmpty && p.bio.isNotEmpty && p.categoryId.isNotEmpty, 'work'),
      (p != null && p.skills.isNotEmpty, 'skills'),
      (p != null && (p.hourlyRate > 0 || p.dailyRate > 0), 'rate'),
      (p != null && (p.city.isNotEmpty || p.location != null), 'area'),
      (p != null && p.portfolioImages.isNotEmpty, 'photos'),
      (p != null && (p.isVerified || p.verificationStatus == 'pending'), 'verify'),
    ];
  }

  double get ratio => items.where((i) => i.$1).length / items.length;
  String? get nextKey => items.where((i) => !i.$1).map((i) => i.$2).firstOrNull;
}

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SbProfileSkeleton());
    final p = user.workerProfile;
    final edge = SbLayout.edge(context);
    void editStep(int step) => context.push('${RouteNames.workerProfileSetupPath}?step=$step');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profile),
        actions: [
          IconButton(
            tooltip: l.publicProfilePreview,
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => context.pushNamed(RouteNames.publicWorkerProfileName, pathParameters: {'workerId': user.uid}),
          ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RouteNames.workerSettingsPath),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s2, edge, SbSpace.s8),
        children: [
          SbReadableWidth(
            maxWidth: 680,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: ProfilePhotoPicker(user: user, size: 104)),
              const SizedBox(height: SbSpace.s3),
              Text(user.displayName.isEmpty ? l.profileNoName : user.formattedDisplayName,
                  style: t.headlineSmall, textAlign: TextAlign.center),
              if (p != null && p.headline.isNotEmpty)
                Text(p.headline, style: t.bodyLarge!.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: SbSpace.s3),
              Wrap(alignment: WrapAlignment.center, spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                VerifiedBadge(user: user),
                if (!isIdentityVerified(user) && p?.verificationStatus == 'pending') SbStatusBadge.pending(label: l.verificationPendingShort),
              ]),
              const SizedBox(height: SbSpace.s4),
              _CompletenessCard(user: user, onFix: editStep),
              const SizedBox(height: SbSpace.s4),
              GetVerifiedCard(user: user),
              const SizedBox(height: SbSpace.s4),
              if (p != null) ...[
                _AvailabilityCard(user: user),
                const SizedBox(height: SbSpace.s4),
              ],
              EmailVerificationCard(user: user),
              if (!user.isEmailVerified) const SizedBox(height: SbSpace.s4),
              ProfileSection(
                title: l.workerSetupStepWork,
                actionLabel: l.edit,
                onAction: () => editStep(2),
                child: p == null
                    ? Text(l.workerProfileNotStarted, style: t.bodyMedium!.copyWith(color: c.textSecondary))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        ProfileInfoRow(icon: Icons.work_outline_rounded, label: l.category, value: p.categoryName),
                        ProfileInfoRow(
                          icon: Icons.timeline_outlined,
                          label: l.experience,
                          value: p.experience > 0 ? l.yearsExperience(p.experience) : null,
                        ),
                        if (p.skills.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
                            child: Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
                              for (final s in p.skills) Chip(label: Text(s)),
                            ]),
                          ),
                        if (p.bio.isNotEmpty) Text(p.bio, style: t.bodyMedium),
                      ]),
              ),
              const SizedBox(height: SbSpace.s4),
              ProfileSection(
                title: l.workerSetupStepRates,
                actionLabel: l.edit,
                onAction: () => editStep(3),
                child: Column(children: [
                  ProfileInfoRow(icon: Icons.payments_outlined, label: l.workerProfileRate, value: p == null ? null : workerRateLabel(context, p)),
                  ProfileInfoRow(
                    icon: Icons.near_me_outlined,
                    label: l.publicProfileServiceArea,
                    value: (p == null || p.city.isEmpty) ? null : l.publicProfileAreaValue(p.city, p.serviceRadius.round()),
                  ),
                ]),
              ),
              const SizedBox(height: SbSpace.s4),
              ProfileSection(title: l.workerSetupStepPhotos, child: PortfolioManager(user: user)),
              const SizedBox(height: SbSpace.s4),
              ReviewsSection(userId: user.uid),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.user, required this.onFix});
  final UserEntity user;
  final void Function(int step) onFix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final comp = ProfileCompleteness(user);
    final pct = (comp.ratio * 100).round();
    final next = comp.nextKey;
    if (next == null) return const SizedBox.shrink();
    final (String text, VoidCallback action) = switch (next) {
      'photo' => (l.completeAddPhoto, () => onFix(1)),
      'work' => (l.completeAddWork, () => onFix(2)),
      'skills' => (l.completeAddSkills, () => onFix(2)),
      'rate' => (l.completeAddRate, () => onFix(3)),
      'area' => (l.completeAddArea, () => onFix(3)),
      'photos' => (l.completeAddPhotos, () => onFix(4)),
      _ => (l.completeVerify, () => context.push(RouteNames.getVerifiedPath)),
    };
    return Container(
      padding: const EdgeInsets.all(SbSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(SbRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(l.completeTitle(pct), style: t.titleSmall)),
          TextButton(onPressed: action, child: Text(l.completeFix)),
        ]),
        Semantics(
          value: '$pct%',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SbRadius.full),
            child: LinearProgressIndicator(value: comp.ratio, minHeight: 6),
          ),
        ),
        const SizedBox(height: SbSpace.s2),
        Text(text, style: t.bodySmall),
      ]),
    );
  }
}

/// available / busy / offline — saved immediately to workerProfile.availability.
class _AvailabilityCard extends ConsumerStatefulWidget {
  const _AvailabilityCard({required this.user});
  final UserEntity user;

  @override
  ConsumerState<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends ConsumerState<_AvailabilityCard> {
  bool _saving = false;

  Future<void> _set(String value) async {
    final p = widget.user.workerProfile;
    if (p == null || p.availability == value || _saving) return;
    setState(() => _saving = true);
    final map = WorkerProfileModel.fromEntity(p).toMap()..['availability'] = value;
    final result = await ref.read(updateUserProfileUseCaseProvider).call(uid: widget.user.uid, data: {'workerProfile': map});
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isLeft()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaveFailed), backgroundColor: context.sb.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final current = widget.user.workerProfile?.availability ?? 'available';
    return ProfileSection(
      title: l.availability,
      subtitle: l.availabilityHelp,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Icons only when there's room: on phones they squeezed "Available"
        // onto two lines.
        LayoutBuilder(builder: (context, box) {
          final icons = box.maxWidth >= 420;
          return SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'available', label: Text(l.available), icon: icons ? const Icon(Icons.check_circle_outline_rounded) : null),
              ButtonSegment(value: 'busy', label: Text(l.busy), icon: icons ? const Icon(Icons.schedule_rounded) : null),
              ButtonSegment(value: 'offline', label: Text(l.offline), icon: icons ? const Icon(Icons.do_not_disturb_on_outlined) : null),
            ],
            selected: {current},
            showSelectedIcon: false,
            onSelectionChanged: _saving ? null : (s) => _set(s.first),
          );
        }),
        if (_saving) ...[const SizedBox(height: SbSpace.s2), const LinearProgressIndicator()],
        const SizedBox(height: SbSpace.s2),
        Text(
          switch (current) {
            'busy' => l.availabilityBusyNote,
            'offline' => l.availabilityOfflineNote,
            _ => l.availabilityAvailableNote,
          },
          style: t.bodySmall,
        ),
      ]),
    );
  }
}
