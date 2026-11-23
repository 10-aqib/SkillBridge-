import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skill_bridge/config/router/app_router.dart' show navigatorKey;
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/services/hive_service.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The blue "Verified" badge: shown next to a person's name once their
/// identity was checked (CNIC documents approved by staff, or an authentic
/// NADRA fingerprint check). Shows nothing otherwise.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, required this.user, this.dense = false});
  final UserEntity? user;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (!isIdentityVerified(user)) return const SizedBox.shrink();
    return VerifiedPill(dense: dense);
  }
}

/// The badge itself (always shown).
class VerifiedPill extends StatelessWidget {
  const VerifiedPill({super.key, this.dense = false});
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final label = context.l10n.verifiedBadge;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? SbSpace.s2 : SbSpace.s3, vertical: dense ? 2 : SbSpace.s1),
        decoration: BoxDecoration(color: sb.primary, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, size: dense ? 14 : 18, color: sb.onPrimary),
          const SizedBox(width: SbSpace.s1),
          Text(
            label,
            style: (dense ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelLarge)!
                .copyWith(color: sb.onPrimary, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }
}

/// "You're verified!" pop-up: the badge springs in with a ring of light.
Future<void> showVerifiedCelebration(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => const _VerifiedCelebration(),
    transitionBuilder: (context, a, _, child) => FadeTransition(opacity: a, child: child),
  );
}

class _VerifiedCelebration extends StatefulWidget {
  const _VerifiedCelebration();

  @override
  State<_VerifiedCelebration> createState() => _VerifiedCelebrationState();
}

class _VerifiedCelebrationState extends State<_VerifiedCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.elasticOut));
    final ring = CurvedAnimation(parent: _c, curve: const Interval(0.1, 0.9, curve: Curves.easeOut));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.8, curve: Curves.easeOut));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SbSpace.s6),
        child: Material(
          color: sb.surface,
          borderRadius: BorderRadius.circular(SbRadius.card + 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(SbSpace.s5, SbSpace.s6, SbSpace.s5, SbSpace.s4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox.square(
                  dimension: 132,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => CustomPaint(
                      painter: _RingPainter(progress: ring.value, color: sb.primary),
                      child: Center(
                        child: Transform.scale(
                          scale: pop.value,
                          child: Transform.rotate(
                            angle: (1 - _c.value.clamp(0.0, 0.6) / 0.6) * -0.5,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: sb.primary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: sb.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
                              ),
                              child: Icon(Icons.verified_rounded, size: 52, color: sb.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SbSpace.s3),
                FadeTransition(
                  opacity: text,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(text),
                    child: Column(children: [
                      Text(l.verifiedPopupTitle, style: t.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: SbSpace.s2),
                      Text(l.verifiedPopupBody, style: t.bodyMedium!.copyWith(color: sb.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: SbSpace.s3),
                      const VerifiedPill(),
                    ]),
                  ),
                ),
                const SizedBox(height: SbSpace.s5),
                SbButton(label: l.verifiedPopupOk, expand: true, onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// An expanding, fading ring with small sparks around the badge.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final fade = 1 - progress;
    final r = 42 + 24 * progress;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade + 0.5
        ..color = color.withValues(alpha: 0.5 * fade),
    );
    final spark = Paint()..color = color.withValues(alpha: fade);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final d = 46 + 20 * progress;
      canvas.drawCircle(center + Offset(math.cos(a) * d, math.sin(a) * d), 3 * fade + 1, spark);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

/// Pops up [showVerifiedCelebration] once per account, the first time the
/// signed-in person is verified (for example when staff approve their CNIC
/// while the app is open). Remembered on this device so it doesn't repeat.
class VerifiedCelebrationWatcher extends ConsumerStatefulWidget {
  const VerifiedCelebrationWatcher({super.key, required this.child, this.startDelay = const Duration(milliseconds: 2300)});

  final Widget child;

  /// Waits for the startup animation before the first pop-up.
  final Duration startDelay;

  @override
  ConsumerState<VerifiedCelebrationWatcher> createState() => _VerifiedCelebrationWatcherState();
}

class _VerifiedCelebrationWatcherState extends ConsumerState<VerifiedCelebrationWatcher> {
  static const _keyPrefix = 'verifiedCelebrated:';
  final _shownThisRun = <String>{};
  final _started = DateTime.now();

  bool _alreadyShown(String uid) {
    if (_shownThisRun.contains(uid)) return true;
    try {
      return Hive.box(HiveService.settingsBoxName).get('$_keyPrefix$uid') == true;
    } catch (_) {
      return false;
    }
  }

  void _remember(String uid) {
    _shownThisRun.add(uid);
    try {
      unawaited(Hive.box(HiveService.settingsBoxName).put('$_keyPrefix$uid', true));
    } catch (_) {}
  }

  Future<void> _maybeShow(UserEntity? user) async {
    if (user == null || !(user.isClient || user.isWorker)) return;
    if (!isIdentityVerified(user) || _alreadyShown(user.uid)) return;
    _remember(user.uid);
    final wait = widget.startDelay - DateTime.now().difference(_started);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    final ctx = navigatorKey.currentContext;
    if (!mounted || ctx == null || !ctx.mounted) return;
    if (ref.read(currentUserProvider)?.uid != user.uid) return;
    await showVerifiedCelebration(ctx);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShow(ref.read(currentUserProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserEntity?>(currentUserProvider, (_, next) => _maybeShow(next));
    return widget.child;
  }
}
