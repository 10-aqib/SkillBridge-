import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skill_bridge/core/utils/logger.dart';

enum LocationTrackingStatus {
  idle,
  checkingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  tracking,
  error,
}

class LocationTrackingService {
  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastFirestoreWriteTime;
  String? _activeTrackingUserId;

  LocationTrackingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  bool get isTracking => _positionSubscription != null;
  String? get activeTrackingUserId => _activeTrackingUserId;

  /// Verifies GPS services and location permissions on the device.
  /// Returns null if all permissions are granted, or an error status if not.
  Future<LocationTrackingStatus?> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.w('[LocationTrackingService] Device location services are disabled.');
        return LocationTrackingStatus.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.w('[LocationTrackingService] Location permission denied by user.');
          return LocationTrackingStatus.permissionDenied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.w('[LocationTrackingService] Location permission permanently denied.');
        return LocationTrackingStatus.permissionPermanentlyDenied;
      }

      return null; // All permissions granted
    } catch (e, stack) {
      Logger.e('[LocationTrackingService] Error checking permissions', e, stack);
      return LocationTrackingStatus.error;
    }
  }

  /// Starts real-time location tracking for a specific worker/hirer.
  /// Obtains the real device GPS location and publishes throttled updates to Firestore.
  Future<LocationTrackingStatus> startTracking(String userId) async {
    try {
      if (userId.isEmpty) {
        return LocationTrackingStatus.error;
      }

      // If already tracking for this user, return current status
      if (isTracking && _activeTrackingUserId == userId) {
        return LocationTrackingStatus.tracking;
      }

      // If tracking for a different user, stop it first
      if (isTracking) {
        await stopTracking();
      }

      final permissionError = await checkAndRequestPermission();
      if (permissionError != null) {
        return permissionError;
      }

      _activeTrackingUserId = userId;

      // 1. Fetch initial real GPS coordinate immediately
      Position initialPosition;
      try {
        initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        // Fallback to last known position if immediate fetch times out
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) {
          rethrow;
        }
        initialPosition = lastKnown;
      }

      await _publishPositionToFirestore(userId, initialPosition);

      // 2. Configure real-time position stream with distance filter and throttling
      // - distanceFilter: 10 meters (only trigger when moved by 10m)
      // - throttling: minimum 10 seconds between writes to preserve battery & Firestore
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          final now = DateTime.now();
          if (_lastFirestoreWriteTime != null &&
              now.difference(_lastFirestoreWriteTime!).inSeconds < 10) {
            return; // Throttled to protect battery & network
          }
          await _publishPositionToFirestore(userId, position);
        },
        onError: (err) {
          Logger.e('[LocationTrackingService] Position stream error: $err');
        },
        cancelOnError: false,
      );

      Logger.i('[LocationTrackingService] Live GPS tracking started for user $userId');
      return LocationTrackingStatus.tracking;
    } catch (e, stack) {
      Logger.e('[LocationTrackingService] Failed to start tracking', e, stack);
      await stopTracking();
      return LocationTrackingStatus.error;
    }
  }

  /// Stops tracking, cancels GPS stream, and marks isLocationSharing as false in Firestore.
  Future<void> stopTracking([String? userId]) async {
    final targetId = userId ?? _activeTrackingUserId;
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _lastFirestoreWriteTime = null;

      if (targetId != null && targetId.isNotEmpty) {
        await _firestore.collection('users').doc(targetId).update({
          'isLocationSharing': false,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });
        Logger.i('[LocationTrackingService] Location sharing stopped in Firestore for $targetId');
      }
    } catch (e) {
      Logger.w('[LocationTrackingService] Non-critical error updating stopped state: $e');
    } finally {
      _activeTrackingUserId = null;
    }
  }

  Future<void> _publishPositionToFirestore(String userId, Position pos) async {
    try {
      _lastFirestoreWriteTime = DateTime.now();
      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(pos.latitude, pos.longitude),
        'isLocationSharing': true,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'heading': pos.heading,
      });
      Logger.d(
        '[LocationTrackingService] Real GPS published for $userId: (${pos.latitude}, ${pos.longitude})',
      );
    } catch (e) {
      Logger.w('[LocationTrackingService] Error publishing location to Firestore: $e');
    }
  }

  /// Helper to open device location settings when GPS is off.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Helper to open app settings when permission was permanently denied.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeTrackingUserId = null;
  }
}

/// Global provider for LocationTrackingService
final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  final service = LocationTrackingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of a specific user's live location and sharing status from Firestore
final userLiveLocationStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return {
      'location': data['location'] as GeoPoint?,
      'isLocationSharing': data['isLocationSharing'] as bool? ?? false,
      'locationUpdatedAt': data['locationUpdatedAt'] as Timestamp?,
      'heading': (data['heading'] as num?)?.toDouble(),
      'displayName': data['displayName'] as String? ?? 'User',
      'photoUrl': data['photoUrl'] as String?,
    };
  });
});
