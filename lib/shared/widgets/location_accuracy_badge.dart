import 'package:flutter/material.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';

class LocationAccuracyBadge extends StatelessWidget {
  final LocationAccuracyLevel accuracyLevel;
  final double? accuracyInMeters;

  const LocationAccuracyBadge({
    super.key,
    required this.accuracyLevel,
    this.accuracyInMeters,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;
    IconData iconData;

    switch (accuracyLevel) {
      case LocationAccuracyLevel.high:
        badgeColor = Colors.green;
        label = 'High Accuracy';
        iconData = Icons.gps_fixed;
        break;
      case LocationAccuracyLevel.medium:
        badgeColor = Colors.orange;
        label = 'Medium Accuracy';
        iconData = Icons.gps_not_fixed;
        break;
      case LocationAccuracyLevel.low:
        badgeColor = Colors.red;
        label = 'Low Accuracy';
        iconData = Icons.location_disabled;
        break;
      case LocationAccuracyLevel.unknown:
      default:
        badgeColor = Colors.grey;
        label = 'Determining...';
        iconData = Icons.gps_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: badgeColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (accuracyInMeters != null && accuracyLevel != LocationAccuracyLevel.unknown) ...[
            const SizedBox(width: 4),
            Text(
              '(\u00B1${accuracyInMeters!.toStringAsFixed(0)}m)',
              style: TextStyle(
                color: badgeColor.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
