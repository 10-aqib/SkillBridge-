import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/features/worker/presentation/widgets/worker_palette.dart';


/// Worker bottom navigation, in the app's light/dark colours (WorkerPalette).
class WorkerMainScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const WorkerMainScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = WorkerPalette.of(context);
    final currentIndex = navigationShell.currentIndex;
    // Conversations with unread messages (kept by the server).
    final unreadChats = ref.watch(unreadChatsCountProvider);

    final items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: AppL10n.select(context, en: 'Home', ur: 'ہوم'),
      ),
      _NavItem(
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        label: 'Proposals',
      ),
      _NavItem(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded,
        label: 'Contracts',
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Chats',
        badge: unreadChats,
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.card,
          border: Border(
            top: BorderSide(color: p.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: _NavButton(
                    item: item,
                    isActive: isActive,
                    onTap: () => _onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item Data ─────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}

// ── Nav Button ────────────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = WorkerPalette.of(context);
    return InkWell(
      onTap: onTap,
      splashColor: p.accent.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active indicator dot above icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 20 : 0,
            height: isActive ? 3 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (!isActive) const SizedBox(height: 7),
          // Icon
          Badge(
            isLabelVisible: item.badge > 0,
            label: Text('${item.badge}'),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? p.accent : p.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          // Label
          Text(
            item.label,
            style: TextStyle(
              color: isActive ? p.textPrimary : p.textSecondary,
              fontSize: 10,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'Inter',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
