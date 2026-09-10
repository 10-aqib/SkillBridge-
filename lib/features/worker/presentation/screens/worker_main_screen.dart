import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

/// Guild Modernist Worker Bottom Navigation (5 Tabs)
class WorkerMainScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          destinations: [
            _buildNavDestination(
              context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: AppL10n.select(context, en: 'Home', ur: 'ہوم'),
            ),
            _buildNavDestination(
              context,
              icon: Icons.description_outlined,
              selectedIcon: Icons.description_rounded,
              label: 'Proposals',
            ),
            _buildNavDestination(
              context,
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment_rounded,
              label: 'Contracts',
            ),
            _buildNavDestination(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Chats',
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
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: context.mutedColor, size: 22),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary, size: 24),
      label: label,
    );
  }
}
