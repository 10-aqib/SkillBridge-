import 'package:flutter/material.dart';
import 'package:skill_bridge/shared/widgets/brand/sb_logo.dart';

/// Short brand intro shown once when the app starts: on a white and blue
/// background, "Skill" slides in from the left and "Bridge" from the right,
/// they meet as one word "SkillBridge", the logo appears, and the intro fades
/// out to reveal the app (which keeps loading underneath).
///
/// It sits above the router, so it plays whatever screen the app opens on.
/// With reduced motion it shows the finished word briefly, without sliding.
class StartupIntro extends StatefulWidget {
  const StartupIntro({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// False skips the intro (tests, or when it has already played).
  final bool enabled;

  static const Duration duration = Duration(milliseconds: 2000);
  static const Duration reducedMotionDuration = Duration(milliseconds: 900);

  @override
  State<StartupIntro> createState() => _StartupIntroState();
}

class _StartupIntroState extends State<StartupIntro> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _done = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _done = !widget.enabled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _started) return;
    _started = true;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _c = AnimationController(vsync: this, duration: reduce ? StartupIntro.reducedMotionDuration : StartupIntro.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) setState(() => _done = true);
      })
      ..forward();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (_done || c == null) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(child: widget.child),
        AnimatedBuilder(
          animation: c,
          builder: (context, _) => _IntroFrame(t: c.value, reduceMotion: reduce),
        ),
      ],
    );
  }
}

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({required this.t, required this.reduceMotion});

  /// 0..1 through the whole intro.
  final double t;
  final bool reduceMotion;

  /// Progress of [t] within [begin, end], eased.
  static double _seg(double t, double begin, double end, [Curve curve = Curves.linear]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    // Timeline (fractions of the whole): words slide 0–.38, meet/settle
    // .34–.48, logo .42–.62, hold, fade out .82–1. Reduced motion: no slide.
    final slide = reduceMotion ? 1.0 : _seg(t, 0.0, 0.38, Curves.easeOutCubic);
    final settle = reduceMotion ? 1.0 : _seg(t, 0.34, 0.48, Curves.easeOutBack);
    final logo = reduceMotion ? 1.0 : _seg(t, 0.42, 0.62, Curves.easeOutBack);
    final line = reduceMotion ? 1.0 : _seg(t, 0.48, 0.70, Curves.easeOutCubic);
    final fadeOut = _seg(t, reduceMotion ? 0.6 : 0.82, 1.0, Curves.easeIn);

    final size = MediaQuery.sizeOf(context);
    final fontSize = (size.width * 0.115).clamp(30.0, 56.0);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.1,
      decoration: TextDecoration.none,
    );
    final travel = size.width * 0.75;
    final scale = 0.92 + 0.08 * settle;

    // Sits above the Navigator, so give it Material text defaults.
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        ignoring: fadeOut > 0.5,
        child: Opacity(
          opacity: 1 - fadeOut,
          child: Semantics(
            label: 'SkillBridge',
            container: true,
            child: DecoratedBox(
              // White page with a soft blue glow in the middle and a blue base.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Color(0xFFE6EEFD), Color(0xFFBFD3FA)],
                  stops: [0, 0.45, 0.8, 1],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Container(
                      width: size.shortestSide * 0.9,
                      height: size.shortestSide * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            SbLogoColors.top.withValues(alpha: 0.10 * slide),
                            SbLogoColors.top.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: logo.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * logo,
                              child: SbLogoMark(size: fontSize * 3.2, semanticLabel: null, tile: false),
                            ),
                          ),
                          SizedBox(height: fontSize * 0.45),
                          Transform.scale(
                            scale: scale,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.translate(
                                  offset: Offset(-travel * (1 - slide), 0),
                                  child: Opacity(
                                    opacity: (slide * 1.6).clamp(0.0, 1.0),
                                    child: Text('Skill', style: style.copyWith(color: SbLogoColors.skill)),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(travel * (1 - slide), 0),
                                  child: Opacity(
                                    opacity: (slide * 1.6).clamp(0.0, 1.0),
                                    child: Text('Bridge', style: style.copyWith(color: SbLogoColors.bridge)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: fontSize * 0.3),
                          Container(
                            width: fontSize * 3.2 * line,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: SbLogoColors.gradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
