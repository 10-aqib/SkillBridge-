import 'package:flutter/material.dart';

/// SkillBridge brand colours (wordmark, intro, headers). Gradient runs
/// top-left → bottom-right.
abstract final class SbLogoColors {
  static const Color top = Color(0xFF2F6FE4);
  static const Color bottom = Color(0xFF163F82);
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [top, bottom],
  );
}

/// The SkillBridge mark: the app icon itself (the official logo on a white
/// rounded tile, like the launcher icon), so the logo looks the same on the
/// home screen, the launch screens and inside the app. The logo is drawn by
/// Flutter's own [FlutterLogo] (vector, sharp at any size); the launch-screen
/// images come from the same drawing (tool/brand/generate_icons.py).
class SbLogoMark extends StatelessWidget {
  const SbLogoMark({super.key, this.size = 56, this.semanticLabel = 'SkillBridge'});

  final double size;

  /// Null hides the mark from screen readers (when a wordmark sits next to it).
  final String? semanticLabel;

  /// Logo size as a fraction of the tile (as on the launcher icon).
  static const double logoFraction = 0.86;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0x14000000)),
      ),
      alignment: Alignment.center,
      child: FlutterLogo(size: size * logoFraction),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: mark),
    );
  }
}

/// "Skill" + "Bridge" wordmark.
class SbWordmark extends StatelessWidget {
  const SbWordmark({super.key, this.fontSize = 22, this.skillColor, this.bridgeColor});

  final double fontSize;
  final Color? skillColor;
  final Color? bridgeColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.3);
    return Semantics(
      label: 'SkillBridge',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Skill',
                style: style.copyWith(color: skillColor ?? (dark ? Colors.white : SbLogoColors.bottom)),
              ),
              TextSpan(
                text: 'Bridge',
                style: style.copyWith(color: bridgeColor ?? (dark ? const Color(0xFF8DB4FF) : SbLogoColors.top)),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
