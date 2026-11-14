import 'package:flutter/material.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_roles.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Client / worker choice as two radio cards. Only self-service roles exist
/// here — there is no way to pick an admin role in the app.
class RoleChoiceGroup extends StatelessWidget {
  const RoleChoiceGroup({super.key, required this.value, required this.onChanged, this.enabled = true});

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      label: l.signupRoleQuestion,
      container: true,
      child: Column(children: [
        RoleChoiceCard(
          selected: value == UserRoles.client,
          icon: Icons.home_repair_service_outlined,
          title: l.roleClientTitle,
          description: l.roleClientDesc,
          onTap: enabled ? () => onChanged(UserRoles.client) : null,
        ),
        const SizedBox(height: SbSpace.s3),
        RoleChoiceCard(
          selected: value == UserRoles.worker,
          icon: Icons.construction_rounded,
          title: l.roleWorkerTitle,
          description: l.roleWorkerDesc,
          onTap: enabled ? () => onChanged(UserRoles.worker) : null,
        ),
      ]),
    );
  }
}

class RoleChoiceCard extends StatelessWidget {
  const RoleChoiceCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final t = Theme.of(context).textTheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? c.primarySubtle : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SbRadius.card),
          side: BorderSide(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(SbRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SbSpace.s4),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? c.primary : c.surfaceSunken,
                  borderRadius: BorderRadius.circular(SbRadius.control),
                ),
                child: Icon(icon, color: selected ? c.onPrimary : c.textSecondary),
              ),
              const SizedBox(width: SbSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: t.titleSmall),
                  const SizedBox(height: 2),
                  Text(description, style: t.bodyMedium!.copyWith(color: c.textSecondary)),
                ]),
              ),
              const SizedBox(width: SbSpace.s2),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? c.primary : c.borderInput,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
