import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';

/// Guild Modernist Client Bottom Navigation (4 Tabs)
class ClientMainScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ClientMainScreen({
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
    // Conversations with unread messages (kept by the server).
    final unreadChats = ref.watch(unreadChatsCountProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          backgroundColor: context.surfaceColor,
          indicatorColor: AppColors.primaryContainer,
          elevation: 4,
          shadowColor: context.textColor.withValues(alpha: 0.08),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _buildNavDestination(
              context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
            ),
            _buildNavDestination(
              context,
              icon: Icons.work_outline_rounded,
              selectedIcon: Icons.work_rounded,
              label: 'Bookings',
            ),
            _buildNavDestination(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Messages',
              badge: unreadChats,
            ),
            _buildNavDestination(
              context,
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    int badge = 0,
  }) {
    Widget withBadge(Widget child) => Badge(isLabelVisible: badge > 0, label: Text('$badge'), child: child);
    return NavigationDestination(
      icon: withBadge(Icon(icon, color: context.mutedColor)),
      selectedIcon: withBadge(Icon(selectedIcon, color: AppColors.primary)),
      label: label,
    );
  }
}
