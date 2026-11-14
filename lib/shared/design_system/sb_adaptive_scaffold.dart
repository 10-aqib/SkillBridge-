import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

class SbNavDestination {
  const SbNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Unread count. Null or 0 hides the badge.
  final int? badgeCount;
}

/// Role shell layout: bottom navigation on phones (<600), navigation rail on
/// tablets (600–1023), extended rail on large screens (≥1024).
///
/// Only layout — keeps the caller's IndexedStack/router state untouched, so
/// it can wrap the existing client/worker shells without changing navigation.
class SbAdaptiveScaffold extends StatelessWidget {
  const SbAdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.railLeading,
  });

  final List<SbNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  /// Brand mark or primary action at the top of the rail (tablet+).
  final Widget? railLeading;

  Widget _icon(IconData icon, int? count) {
    final i = Icon(icon);
    if (count == null || count <= 0) return i;
    return Badge(label: Text(count > 99 ? '99+' : '$count'), child: i);
  }

  @override
  Widget build(BuildContext context) {
    final size = SbWindowSize.of(context);
    final c = context.sb;

    if (size == SbWindowSize.compact) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: _icon(d.icon, d.badgeCount),
                  selectedIcon: _icon(d.selectedIcon, d.badgeCount),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    final extended = size == SbWindowSize.expanded;
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 232,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: railLeading,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: _icon(d.icon, d.badgeCount),
                  selectedIcon: _icon(d.selectedIcon, d.badgeCount),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: c.border),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: SbLayout.contentMaxWidth),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centers forms and reading content at a readable width on tablets/desktop.
class SbReadableWidth extends StatelessWidget {
  const SbReadableWidth({super.key, required this.child, this.maxWidth = SbLayout.formMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
