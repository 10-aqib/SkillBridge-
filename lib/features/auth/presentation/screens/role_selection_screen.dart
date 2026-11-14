import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/auth/presentation/viewmodels/auth_viewmodels.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/role_choice_card.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Finishes sign-up for a signed-in Firebase account that has no SkillBridge
/// role yet (new Google account, interrupted registration, or a legacy profile
/// saved with an empty role). Once saved, the router moves on automatically.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _role;
  bool _showRequired = false;
  bool _signingOut = false;

  Future<void> _useDifferentAccount() async {
    setState(() => _signingOut = true);
    await ref.read(signOutUseCaseProvider).call();
    if (mounted) context.go(RouteNames.welcomePath);
  }

  void _continue() {
    if (_role == null) {
      setState(() => _showRequired = true);
      return;
    }
    ref.read(completeProfileViewModelProvider.notifier).complete(role: _role!);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final state = ref.watch(completeProfileViewModelProvider);
    final firebaseUser = ref.watch(firebaseAuthProvider).currentUser;

    if (firebaseUser == null) {
      // Nobody is signed in (e.g. opened directly): nothing to finish here.
      return AuthScaffold(
        child: SbStateView(
          kind: SbStateKind.permission,
          title: l.roleSelectSignedOutTitle,
          message: l.roleSelectSignedOutBody,
          actionLabel: l.welcomeSignIn,
          onAction: () => context.go(RouteNames.welcomePath),
        ),
      );
    }

    return AuthScaffold(
      title: l.roleSelectTitle,
      subtitle: l.roleSelectSubtitle,
      footer: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbButton(
          label: l.continueText,
          expand: true,
          isLoading: state.isLoading || state.isDone,
          loadingSemanticLabel: l.roleSelectSaving,
          onPressed: _signingOut ? null : _continue,
        ),
        SbButton(
          label: l.roleSelectDifferentAccount,
          variant: SbButtonVariant.quiet,
          expand: true,
          isLoading: _signingOut,
          onPressed: state.isLoading ? null : _useDifferentAccount,
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SbFailureBanner(failure: state.failure),
        if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) ...[
          Row(children: [
            Icon(Icons.account_circle_outlined, color: c.textSecondary, size: 20),
            const SizedBox(width: SbSpace.s2),
            Expanded(
              child: Text(l.roleSelectSignedInAs(firebaseUser.email!),
                  style: t.bodyMedium!.copyWith(color: c.textSecondary)),
            ),
          ]),
          const SizedBox(height: SbSpace.s4),
        ],
        RoleChoiceGroup(
          value: _role ?? '',
          enabled: !state.isLoading && !state.isDone,
          onChanged: (r) => setState(() {
            _role = r;
            _showRequired = false;
          }),
        ),
        if (_showRequired) ...[
          const SizedBox(height: SbSpace.s3),
          Semantics(
            liveRegion: true,
            child: Text(l.roleSelectRequired, style: t.bodySmall!.copyWith(color: c.error)),
          ),
        ],
        const SizedBox(height: SbSpace.s4),
        SbInlineBanner(message: l.roleSelectPermanentNote, tone: SbTone.info),
      ]),
    );
  }
}

/// Kept for callers that only need the valid role list.
const kSelectableRoles = UserRoles.selfService;
