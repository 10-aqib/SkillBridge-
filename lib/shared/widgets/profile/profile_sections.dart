import 'package:flutter/material.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Titled card used on profile screens, with an optional edit action.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    return Container(
      padding: const EdgeInsets.fromLTRB(SbSpace.s4, SbSpace.s3, SbSpace.s2, SbSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SbRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall),
              ]),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ]),
        const SizedBox(height: SbSpace.s2),
        Padding(padding: const EdgeInsetsDirectional.only(end: SbSpace.s2), child: child),
      ]),
    );
  }
}

/// Label / value row. Empty values show a muted "Not added".
class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({super.key, required this.icon, required this.label, this.value, this.trailing});

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    final empty = value == null || value!.trim().isEmpty;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: t.bodySmall),
              const SizedBox(height: 2),
              Text(
                empty ? context.l10n.profileNotAdded : value!,
                style: t.bodyLarge!.copyWith(color: empty ? c.textSecondary : c.text),
              ),
            ]),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

/// City dropdown from PakistanConstants (no default — nothing is invented).
class CityDropdown extends StatelessWidget {
  const CityDropdown({super.key, required this.value, required this.onChanged, this.validator});

  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cities = PakistanConstants.majorCities;
    final current = (value != null && cities.contains(value)) ? value : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.profileCityLabel, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: SbSpace.s2),
      DropdownButtonFormField<String>(
        initialValue: current,
        isExpanded: true,
        hint: Text(l.profileCityHint),
        validator: validator,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.location_city_outlined, size: 20)),
        items: [for (final c in cities) DropdownMenuItem(value: c, child: Text(c))],
        onChanged: onChanged,
      ),
    ]);
  }
}

/// Small numbered stat ("12 · Jobs posted").
class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(children: [
        Text(value, style: SbTypography.numeric(t.titleMedium!)),
        Text(label, style: t.bodySmall, textAlign: TextAlign.center),
      ]),
    );
  }
}
