import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

/// Guild Modernist Avatar Widget
/// Always circular, with Skill-Green online indicator
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool showStatus;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40.0,
    this.isOnline = false,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).map((l) => l[0]).take(2).join().toUpperCase();

    return Stack(
      children: [
        ClipOval(
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: size * 0.4,
                        height: size * 0.4,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildInitials(initials),
                  )
                : _buildInitials(initials),
          ),
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.tertiary : AppColors.outlineVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceWhite,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : 'S',
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.onPrimaryContainer,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
