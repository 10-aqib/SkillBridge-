import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

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
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';

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
          shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _buildNavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: isUrdu ? 'ہوم' : 'Home',
            ),
            _buildNavDestination(
              icon: Icons.work_outline_rounded,
              selectedIcon: Icons.work_rounded,
              label: isUrdu ? 'میرے کام' : 'My Jobs',
            ),
            _buildNavDestination(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: isUrdu ? 'چیٹ' : 'Chats',
            ),
            _buildNavDestination(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: isUrdu ? 'پروفائل' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.onSurfaceVariant),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary),
      label: label,
    );
  }
}
