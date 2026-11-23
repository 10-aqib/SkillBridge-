import 'package:flutter/material.dart';

/// SkillBridge brand colours, sampled from the official logo
/// (tool/brand/skillbridge_logo_source.png). Gradient runs top-left →
/// bottom-right, light blue to navy, like the "SB" mark.
abstract final class SbLogoColors {
  static const Color top = Color(0xFF017CFB);
  static const Color bottom = Color(0xFF002666);

  /// Wordmark: "Skill" in navy, "Bridge" in blue.
  static const Color skill = Color(0xFF011C43);
  static const Color bridge = Color(0xFF0068F9);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [top, bottom],
  );
}

/// Image files made by tool/brand/generate_icons.py from the official logo.
abstract final class SbBrandAssets {
  static const String mark = 'assets/brand/skillbridge_mark.png';
  static const String logo = 'assets/brand/skillbridge_logo.png';

  /// width / height of the images.
  static const double markAspect = 706 / 347;
  static const double logoAspect = 973 / 603;
}

/// The SkillBridge mark: the "SB" monogram with the briefcase, the same
/// drawing as the app icon.
///
/// With [tile] (default) it sits on a white rounded tile [size] wide, like
/// the launcher icon, so it reads on any background (blue headers, dark
/// mode). Without, it is drawn on its own, [size] wide (white screens such as
/// the splash, which matches the launch screen).
class SbLogoMark extends StatelessWidget {
  const SbLogoMark({super.key, this.size = 56, this.semanticLabel = 'SkillBridge', this.tile = true});

  final double size;

  /// Null hides the mark from screen readers (when a wordmark sits next to it).
  final String? semanticLabel;
  final bool tile;

  /// Mark width as a fraction of the tile.
  static const double markFraction = 0.86;

  @override
  Widget build(BuildContext context) {
    final w = tile ? size * markFraction : size;
    final image = Image.asset(
      SbBrandAssets.mark,
      width: w,
      height: w / SbBrandAssets.markAspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    final Widget mark = tile
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(color: const Color(0x14000000)),
            ),
            alignment: Alignment.center,
            child: image,
          )
        : image;
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: mark));
  }
}

/// The full logo: mark, "SkillBridge" and "Skills • Jobs • Growth", [width]
/// wide. Its navy lettering needs a light background, so in dark mode it sits
/// on a white card.
class SbFullLogo extends StatelessWidget {
  const SbFullLogo({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final image = Image.asset(
      SbBrandAssets.logo,
      width: width,
      height: width / SbBrandAssets.logoAspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    return Semantics(
      label: 'SkillBridge',
      image: true,
      child: ExcludeSemantics(
        child: dark
            ? Container(
                padding: EdgeInsets.all(width * 0.06),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(width * 0.08)),
                child: image,
              )
            : image,
      ),
    );
  }
}

/// "Skill" + "Bridge" wordmark in the logo's colours.
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
                style: style.copyWith(color: skillColor ?? (dark ? Colors.white : SbLogoColors.skill)),
              ),
              TextSpan(
                text: 'Bridge',
                style: style.copyWith(color: bridgeColor ?? (dark ? const Color(0xFF6FB0FF) : SbLogoColors.bridge)),
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
