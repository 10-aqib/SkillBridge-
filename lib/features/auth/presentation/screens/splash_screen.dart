import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';

/// Brief brand screen while the auth state loads. Signed-in people are moved
/// on by the router; signed-out people continue to Welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) context.go(RouteNames.welcomePath);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Same mark, size and place as the launch screen before it.
          const SbLogoMark(size: 160, tile: false),
          const SizedBox(height: SbSpace.s5),
          Text('SkillBridge', style: t.headlineSmall!.copyWith(color: c.primary)),
          const SizedBox(height: SbSpace.s2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SbSpace.s8),
            child: Text(context.l10n.appTagline,
                style: t.bodyLarge!.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
          ),
          const SizedBox(height: SbSpace.s8),
          SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.primary)),
        ]),
      ),
    );
  }
}
