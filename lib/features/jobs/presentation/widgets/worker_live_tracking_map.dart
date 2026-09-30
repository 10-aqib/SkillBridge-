import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Guild Modernist Live Worker GPS Tracking widget with real Google Maps.
/// Displays real-time device GPS coordinates streamed from Firestore,
/// live marker movement, traffic ETA, and one-tap contact actions.
class WorkerLiveTrackingMap extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String? workerImageUrl;
  final String workerPhone;
  final double? workerLat;
  final double? workerLon;
  final double clientLat;
  final double clientLon;
  final VoidCallback? onCallWorker;

  const WorkerLiveTrackingMap({
    super.key,
    required this.workerId,
    required this.workerName,
    this.workerImageUrl,
    required this.workerPhone,
    this.workerLat,
    this.workerLon,
    this.clientLat = 33.6844,
    this.clientLon = 73.0479,
    this.onCallWorker,
  });

  @override
  State<WorkerLiveTrackingMap> createState() => _WorkerLiveTrackingMapState();
}

class _WorkerLiveTrackingMapState extends State<WorkerLiveTrackingMap>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _locationSubscription;
  late AnimationController _pulseController;

  double? _workerCurrentLat;
  double? _workerCurrentLon;
  bool _isLocationSharing = false;
  DateTime? _locationUpdatedAt;

  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  String _locality = 'Islamabad';

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _workerCurrentLat = widget.workerLat;
    _workerCurrentLon = widget.workerLon;

    _updateMetricsAndMarkers();
    _subscribeToWorkerLiveLocation();
  }

  void _subscribeToWorkerLiveLocation() {
    if (widget.workerId.isEmpty) return;

    _locationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.workerId)
        .snapshots()
        .listen(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!mounted || !snapshot.exists) return;
        final data = snapshot.data();
        if (data == null) return;

        final isSharing = data['isLocationSharing'] as bool? ?? false;
        final geoPoint = data['location'] as GeoPoint?;
        final updatedAt = (data['locationUpdatedAt'] as Timestamp?)?.toDate();

        if (geoPoint != null) {
          setState(() {
            _workerCurrentLat = geoPoint.latitude;
            _workerCurrentLon = geoPoint.longitude;
            _isLocationSharing = isSharing;
            _locationUpdatedAt = updatedAt;
            _updateMetricsAndMarkers();
          });

          // Smoothly animate Google Maps camera to latest coordinates
          if (_mapController != null && _workerCurrentLat != null && _workerCurrentLon != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(_workerCurrentLat!, _workerCurrentLon!),
              ),
            );
          }
        } else {
          setState(() {
            _isLocationSharing = isSharing;
            _locationUpdatedAt = updatedAt;
          });
        }
      },
      onError: (e) {
        debugPrint('[WorkerLiveTrackingMap] Error streaming worker location: $e');
      },
    );
  }

  void _updateMetricsAndMarkers() {
    _markers.clear();
    _polylines.clear();

    // Client / Destination marker
    final clientLatLng = LatLng(widget.clientLat, widget.clientLon);
    _markers.add(
      Marker(
        markerId: const MarkerId('client_destination'),
        position: clientLatLng,
        infoWindow: const InfoWindow(
          title: 'Destination',
          snippet: 'Client Job Location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    if (_workerCurrentLat != null && _workerCurrentLon != null) {
      final workerLatLng = LatLng(_workerCurrentLat!, _workerCurrentLon!);

      _distanceKm = GeoLocationUtil.calculateDistanceKm(
        _workerCurrentLat!,
        _workerCurrentLon!,
        widget.clientLat,
        widget.clientLon,
      );
      _etaMinutes = GeoLocationUtil.calculateEtaMinutes(_distanceKm);
      _locality = GeoLocationUtil.formatDistance(_distanceKm);

      // Live worker marker
      _markers.add(
        Marker(
          markerId: const MarkerId('worker_live_marker'),
          position: workerLatLng,
          infoWindow: InfoWindow(
            title: widget.workerName,
            snippet: '$_locality • ${_distanceKm.toStringAsFixed(1)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      // Polyline connecting worker to client
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('tracking_route'),
          points: [workerLatLng, clientLatLng],
          color: AppColors.primary,
          width: 3,
          patterns: [PatternItem.dash(15), PatternItem.gap(10)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _sharePin() {
    HapticFeedback.lightImpact();
    final lat = _workerCurrentLat ?? widget.clientLat;
    final lon = _workerCurrentLon ?? widget.clientLon;
    final mapLink = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';

    Clipboard.setData(ClipboardData(text: mapLink));
    final snackMsg = AppL10n.select(
      context,
      en: '📍 Live location link copied to clipboard!',
      ur: '📍 لائیو لوکیشن لنک کاپی ہو گیا۔',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMsg),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _centerOnWorker() {
    if (_mapController == null) return;
    if (_workerCurrentLat != null && _workerCurrentLon != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_workerCurrentLat!, _workerCurrentLon!),
            zoom: 15.0,
          ),
        ),
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.clientLat, widget.clientLon),
            zoom: 14.0,
          ),
        ),
      );
    }
  }

  void _showFullScreenMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: context.surfaceColor,
            elevation: 1,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: context.textColor),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
            title: Text(
              '${widget.workerName} — Live Route',
              style: AppTextStyles.heading3.copyWith(color: context.textColor),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                onPressed: _centerOnWorker,
              ),
            ],
          ),
          body: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _workerCurrentLat ?? widget.clientLat,
                _workerCurrentLon ?? widget.clientLon,
              ),
              zoom: 14.5,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: true,
          ),
        ),
      ),
    );
  }

  String _formatLastUpdated() {
    if (_locationUpdatedAt == null) return '';
    final diff = DateTime.now().difference(_locationUpdatedAt!);
    if (diff.inSeconds < 60) {
      return 'Updated just now';
    } else if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes}m ago';
    } else {
      return 'Updated ${diff.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = LatLng(
      _workerCurrentLat ?? widget.clientLat,
      _workerCurrentLon ?? widget.clientLon,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      shadow: AppShadows.level2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Real Google Map Viewport ─────────────────────────────────────
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusMd),
                  ),
                  child: GoogleMap(
                    onMapCreated: (ctrl) {
                      _mapController = ctrl;
                      _centerOnWorker();
                    },
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: 14.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                  ),
                ),

                // Live status chip in top-left
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLocationSharing && _workerCurrentLat != null) ...[
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.successGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.successGreen.withValues(
                                        alpha: 0.5 * _pulseController.value,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live Tracking',
                            style: AppTextStyles.labelCaption.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ] else if (!_isLocationSharing) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sharing paused',
                            style: AppTextStyles.labelCaption.copyWith(
                              color: context.mutedColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Location unavailable',
                            style: AppTextStyles.labelCaption.copyWith(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Top-right controls: Center & Fullscreen
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _centerOnWorker,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.surfaceColor.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showFullScreenMap(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.surfaceColor.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.fullscreen_rounded,
                            size: 18,
                            color: context.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Locality tag in bottom-left
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                            color: context.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                        isOnline: _isLocationSharing,
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
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLocationSharing
                                ? AppL10n.select(
                                    context,
                                    en: 'Ustad is live en route',
                                    ur: 'استاد راستے میں ہیں',
                                  )
                                : AppL10n.select(
                                    context,
                                    en: 'Assigned Service Provider',
                                    ur: 'منتخب سروس فراہم کنندہ',
                                  ),
                            style: AppTextStyles.bodyPrimary.copyWith(
                              color: _isLocationSharing ? AppColors.primary : context.mutedColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (_formatLastUpdated().isNotEmpty)
                            Text(
                              _formatLastUpdated(),
                              style: AppTextStyles.labelCaption.copyWith(
                                color: context.mutedColor,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_workerCurrentLat != null && _workerCurrentLon != null)
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
                              '${_distanceKm.toStringAsFixed(1)} km',
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$_etaMinutes mins ETA',
                              style: AppTextStyles.labelCaption.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: AppDimensions.md),

                // ── Interactive Action Buttons ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onCallWorker ??
                            () {
                              HapticFeedback.mediumImpact();
                              Clipboard.setData(ClipboardData(text: widget.workerPhone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Phone number copied: ${widget.workerPhone}'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
