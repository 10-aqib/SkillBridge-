import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_media_widgets.dart';
import 'package:skill_bridge/shared/widgets/profile/profile_sections.dart';
import 'package:skill_bridge/shared/widgets/profile/reviews_section.dart';
import 'package:skill_bridge/features/identity/presentation/get_verified_screen.dart';
import 'package:skill_bridge/features/identity/presentation/verified_badge.dart';
import 'package:skill_bridge/features/auth/presentation/screens/phone_required_screen.dart';

/// Client's own profile: photo, contact details, verification prompts, stats
/// from real data, reviews received, and links to edit and settings.
class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SbProfileSkeleton());
    final edge = SbLayout.edge(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profile),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RouteNames.clientSettingsPath),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(edge, SbSpace.s2, edge, SbSpace.s8),
        children: [
          SbReadableWidth(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: ProfilePhotoPicker(user: user, size: 104)),
              const SizedBox(height: SbSpace.s3),
              Text(user.displayName.isEmpty ? l.profileNoName : user.formattedDisplayName,
                  style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: SbSpace.s1),
              Text(l.client, style: t.bodyMedium!.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: SbSpace.s2),
              Center(child: VerifiedBadge(user: user)),
              const SizedBox(height: SbSpace.s4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(child: ProfileStat(value: '${user.totalJobsPosted}', label: l.profileJobsPosted)),
                Expanded(child: ProfileStat(value: '${user.totalHires}', label: l.profileHires)),
                Expanded(
                  child: ProfileStat(
                    value: user.totalReviews > 0 ? user.rating.toStringAsFixed(1) : '—',
                    label: l.profileReviewsCount(user.totalReviews),
                  ),
                ),
              ]),
              const SizedBox(height: SbSpace.s5),
              GetVerifiedCard(user: user),
              const SizedBox(height: SbSpace.s4),
              PhonePromptCard(user: user),
              EmailVerificationCard(user: user),
              if (!user.isEmailVerified) const SizedBox(height: SbSpace.s4),
              ProfileSection(
                title: l.profileContactDetails,
                actionLabel: l.edit,
                onAction: () => context.push(RouteNames.clientEditProfilePath),
                child: Column(children: [
                  ProfileInfoRow(icon: Icons.mail_outline_rounded, label: l.email, value: user.email,
                      trailing: user.isEmailVerified ? SbStatusBadge.verified(label: l.verified, dense: true) : null),
                  _PhoneRow(user: user),
                  ProfileInfoRow(
                    icon: Icons.place_outlined,
                    label: l.profileLocationLabel,
                    value: [user.address, user.city].where((s) => s != null && s.trim().isNotEmpty).join(', '),
                  ),
                ]),
              ),
              const SizedBox(height: SbSpace.s4),
              ReviewsSection(userId: user.uid),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final phone = PakPhone.normalize(user.phoneNumber);
    Widget? trailing;
    if (user.isPhoneVerified && phone != null) {
      trailing = SbStatusBadge.verified(label: l.verified, dense: true);
    } else if (phone != null) {
      trailing = TextButton(
        onPressed: () => context.push(RouteNames.otpPath, extra: phone),
        child: Text(l.profileVerifyPhone),
      );
    }
    return ProfileInfoRow(
      icon: Icons.phone_outlined,
      label: l.signupPhoneLabel,
      value: phone == null ? user.phoneNumber : '+92 ${PakPhone.toLocalDisplay(phone)}',
      trailing: trailing,
    );
  }
}
