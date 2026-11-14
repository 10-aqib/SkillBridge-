import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/navigation_engine.dart';
import 'package:skill_bridge/features/navigation/presentation/nav_text.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Panels of the navigation screen (Navigation phase 6).

/// Top card: the next maneuver's arrow, how far it is, what to do, and a
/// "then …" hint when the following maneuver comes right after.
class NavInstructionCard extends StatelessWidget {
  const NavInstructionCard({super.key, required this.progress});
  final NavProgress progress;

  /// A following maneuver closer than this gets a "then …" hint.
  static const thenWithin = 150.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    final next = progress.nextStep ?? progress.currentStep;
    final after = progress.stepAfterNext;
    final distance = progress.distanceToManeuver;
    final distanceText = distance < 20 ? l.navNow : formatNavDistance(l, distance);
    final instruction = instructionFor(l, next);
    final showThen = after != null && next.distance < thenWithin;

    return Semantics(
      liveRegion: true,
      label: '$distanceText, $instruction',
      excludeSemantics: true,
      child: Material(
        color: sb.primary,
        elevation: 6,
        borderRadius: BorderRadius.circular(SbRadius.sheet),
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(maneuverIcon(next), size: 52, color: sb.onPrimary),
              const SizedBox(width: SbSpace.s3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(distanceText, style: SbTypography.numeric(t.headlineMedium!).copyWith(color: sb.onPrimary, fontWeight: FontWeight.w700)),
                  Text(instruction, style: t.titleMedium?.copyWith(color: sb.onPrimary), maxLines: 3, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
            if (showThen) ...[
              const SizedBox(height: SbSpace.s2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3, vertical: SbSpace.s1),
                decoration: BoxDecoration(color: sb.onPrimary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(SbRadius.control)),
                child: Row(children: [
                  Icon(maneuverIcon(after), size: 20, color: sb.onPrimary),
                  const SizedBox(width: SbSpace.s2),
                  Expanded(
                    child: Text(l.navThen(instructionFor(l, after)), style: t.bodyMedium?.copyWith(color: sb.onPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Arrival time. Urdu uses 24-hour time: intl's Urdu 12-hour format ends
/// in a bare "p" ("12:12 p"), which reads as a typo.
/// Top card while a new route is being found after leaving the route.
class NavReroutingCard extends StatelessWidget {
  const NavReroutingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: sb.primary,
        elevation: 6,
        borderRadius: BorderRadius.circular(SbRadius.sheet),
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Row(children: [
            SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3, color: sb.onPrimary)),
            const SizedBox(width: SbSpace.s3),
            Expanded(child: Text(context.l10n.navRerouting, style: t.titleMedium?.copyWith(color: sb.onPrimary))),
          ]),
        ),
      ),
    );
  }
}

String _clock(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'ur' ? DateFormat.Hm('ur').format(at) : DateFormat.jm(locale.toLanguageTag()).format(at);
}

/// Bottom panel while guiding: time left, distance left, arrival time, End.
class NavTripPanel extends StatelessWidget {
  const NavTripPanel({super.key, required this.progress, required this.onEnd});
  final NavProgress progress;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return _Sheet(
      child: Row(children: [
        Expanded(
          child: Semantics(
            container: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(formatNavDuration(l, progress.remainingDuration),
                  style: SbTypography.numeric(t.headlineSmall!).copyWith(color: sb.success, fontWeight: FontWeight.w700)),
              Text('${formatNavDistance(l, progress.remainingDistance)} · ${l.navArriveAt(_clock(context, progress.eta))}',
                  style: SbTypography.numeric(t.bodyMedium!)),
            ]),
          ),
        ),
        const SizedBox(width: SbSpace.s3),
        SbButton(label: l.navEnd, icon: Icons.close_rounded, variant: SbButtonVariant.destructive, onPressed: onEnd),
      ]),
    );
  }
}

/// Bottom panel before starting: the route options and Start.
class NavRouteChooser extends StatelessWidget {
  const NavRouteChooser({
    super.key,
    required this.routes,
    required this.selected,
    required this.place,
    required this.onSelect,
    required this.onStart,
  });

  final List<NavRoute> routes;
  final int selected;
  final String place;
  final ValueChanged<int> onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return _Sheet(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.navRouteTo(place), style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: SbSpace.s2),
        for (var i = 0; i < routes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: SbSpace.s2),
            child: Semantics(
              selected: i == selected,
              button: true,
              child: Material(
                color: i == selected ? sb.primarySubtle : sb.surfaceSunken,
                borderRadius: BorderRadius.circular(SbRadius.card),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SbRadius.card),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.all(SbSpace.s3),
                    child: Row(children: [
                      Icon(i == selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: sb.primary),
                      const SizedBox(width: SbSpace.s3),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            '${formatNavDuration(l, routes[i].duration)} · ${formatNavDistance(l, routes[i].distance)}',
                            style: SbTypography.numeric(t.titleSmall!).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            [i == 0 ? l.navFastest : l.navAlternative(i), if (routes[i].summary.isNotEmpty) l.navVia(routes[i].summary)].join(' · '),
                            style: t.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        Text(l.navEstimateNote, style: t.bodySmall),
        const SizedBox(height: SbSpace.s3),
        SbButton(label: l.navStart, icon: Icons.navigation_rounded, expand: true, onPressed: onStart),
      ]),
    );
  }
}

/// Bottom panel on arrival.
class NavArrivedPanel extends StatelessWidget {
  const NavArrivedPanel({super.key, required this.place, required this.onDone});
  final String place;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return _Sheet(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.sports_score, size: 36, color: sb.success),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.navArrivedTitle, style: t.titleLarge),
                Text(l.navArrivedBody(place), style: t.bodyMedium),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: SbSpace.s4),
        SbButton(label: l.done, expand: true, onPressed: onDone),
      ]),
    );
  }
}

/// Bottom panel for waiting (locating, calculating, resuming).
class NavBusyPanel extends StatelessWidget {
  const NavBusyPanel({super.key, required this.message, this.onCancel});
  final String message;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Sheet(
      child: Row(children: [
        const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(width: SbSpace.s3),
        Expanded(child: Semantics(liveRegion: true, child: Text(message, style: t.bodyLarge))),
        if (onCancel != null) SbButton(label: context.l10n.cancel, variant: SbButtonVariant.quiet, onPressed: onCancel),
      ]),
    );
  }
}

/// Bottom panel for a problem, with the fix (try again / settings) and close.
class NavProblemPanel extends StatelessWidget {
  const NavProblemPanel({super.key, required this.message, this.actionLabel, this.onAction, required this.onClose});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return _Sheet(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline_rounded, color: sb.error),
          const SizedBox(width: SbSpace.s3),
          Expanded(child: Semantics(liveRegion: true, child: Text(message, style: t.bodyLarge))),
        ]),
        const SizedBox(height: SbSpace.s4),
        Row(children: [
          Expanded(child: SbButton(label: context.l10n.close, variant: SbButtonVariant.secondary, onPressed: onClose)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: SbSpace.s3),
            Expanded(child: SbButton(label: actionLabel!, onPressed: onAction)),
          ],
        ]),
      ]),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Material(
      color: sb.surface,
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SbRadius.sheet)),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(SbSpace.s4, SbSpace.s4, SbSpace.s4, SbSpace.s3), child: child),
      ),
    );
  }
}
