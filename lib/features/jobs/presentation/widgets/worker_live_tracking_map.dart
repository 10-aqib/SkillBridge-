import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Guild Modernist Live Worker GPS Tracking widget.
/// Displays animated tracking status, Pakistani locality geofencing,
/// Lahore/Karachi city traffic ETA, and 1-tap contact actions.
class WorkerLiveTrackingMap extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String? workerImageUrl;
  final String workerPhone;
  final double workerLat;
  final double workerLon;
  final double clientLat;
  final double clientLon;
  final VoidCallback? onCallWorker;

  const WorkerLiveTrackingMap({
    super.key,
    this.workerId = 'default_worker',
    required this.workerName,
    this.workerImageUrl,
    required this.workerPhone,
    this.workerLat = 31.5102, // Gulberg III default
    this.workerLon = 74.3441,
    this.clientLat = 31.4697, // DHA Phase 5 default
    this.clientLon = 74.4093,
    this.onCallWorker,
  });

  @override
  State<WorkerLiveTrackingMap> createState() => _WorkerLiveTrackingMapState();
}

class _WorkerLiveTrackingMapState extends State<WorkerLiveTrackingMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late double _distanceKm;
  late int _etaMinutes;
  late String _locality;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _distanceKm = GeoLocationUtil.calculateDistanceKm(
      widget.workerLat,
      widget.workerLon,
      widget.clientLat,
      widget.clientLon,
    );
    _etaMinutes = GeoLocationUtil.calculateEtaMinutes(_distanceKm);
    _locality = GeoLocationUtil.detectLocality(
      widget.workerLat,
      widget.workerLon,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _sharePin() {
    HapticFeedback.lightImpact();
    final snackMsg = AppL10n.select(
      context,
      en: '📍 Live Pin copied to clipboard! Ready to share via WhatsApp.',
      ur: '📍 لائیو پن کاپی ہو گیا! واٹس ایپ پر شیئر کرنے کے لیے تیار۔',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMsg),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerText = AppL10n.select(
      context,
      en: '${widget.workerName} • $_etaMinutes mins',
      ur: '${widget.workerName} • $_etaMinutes منٹ',
    );
    return AppCard(
      padding: EdgeInsets.zero,
      shadow: AppShadows.level2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Simulated Live Map Header ───────────────────────────────────
          Container(
            height: 150,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Simulated map grid
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),

                // Pulsing worker marker
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_car_filled_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                headerText,
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Locality tag in bottom left
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _locality,
                          style: AppTextStyles.labelCaption.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Worker Details & Action Buttons ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'worker_avatar_${widget.workerId}',
                      child: AppAvatar(
                        size: 44,
                        imageUrl: widget.workerImageUrl,
                        name: widget.workerName,
                        showStatus: true,
                        isOnline: true,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workerName,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppL10n.select(
                              context,
                              en: 'Ustad is en route',
                              ur: 'استاد راستے میں ہیں',
                            ),
                            style: AppTextStyles.bodyPrimary.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_distanceKm km',
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            AppL10n.select(
                              context,
                              en: 'Distance',
                              ur: 'فاصلہ',
                            ),
                            style: AppTextStyles.labelCaption.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: AppDimensions.md),

                // ── Interactive Action Buttons ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onCallWorker ??
                            () {
                              HapticFeedback.mediumImpact();
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: Text(
                          AppL10n.select(
                            context,
                            en: 'Call Ustad',
                            ur: 'کال کریں',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    OutlinedButton.icon(
                      onPressed: _sharePin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.share_location_rounded, size: 18),
                      label: Text(
                        AppL10n.select(
                          context,
                          en: 'Pin',
                          ur: 'پن',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j <= size.height; j += 25) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
