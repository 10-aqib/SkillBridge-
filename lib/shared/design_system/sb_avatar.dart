import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

/// Person avatar with an initials fallback (no stock photos, no placeholder
/// people). The image is decorative; the name is announced by the parent row.
class SbAvatar extends StatelessWidget {
  const SbAvatar({super.key, required this.name, this.imageUrl, this.size = 52});

  final String name;
  final String? imageUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sb;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.primarySubtle, shape: BoxShape.circle),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: c.onPrimarySubtle,
              fontSize: size * 0.34,
              height: 1,
            ),
      ),
    );
    final url = imageUrl;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: url == null || url.isEmpty
            ? fallback
            : ClipOval(
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
              ),
      ),
    );
  }
}
