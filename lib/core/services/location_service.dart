import 'package:geolocator/geolocator.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';

class LocationServiceException implements Exception {
  final String message;
  final bool isPermissionDenied;
  final bool isServiceDisabled;
  final bool isSettingsRequired;

  LocationServiceException(this.message, {
    this.isPermissionDenied = false,
    this.isServiceDisabled = false,
    this.isSettingsRequired = false,
  });

  @override
  String toString() => message;
}

class LocationService {
  /// Checks and requests location permissions.
  /// Throws [LocationServiceException] if permissions are denied or services are disabled.
  static Future<void> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are disabled. Please enable them in your device settings.',
        isServiceDisabled: true,
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permissions are denied.',
          isPermissionDenied: true,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permissions are permanently denied. Please grant permission in app settings.',
        isSettingsRequired: true,
      );
    }
  }

  /// Gets the current real device GPS position.
  static Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    await checkAndRequestPermission();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    } catch (e) {
      throw LocationServiceException('Failed to get current location: $e');
    }
  }

  /// Gets a continuous stream of location updates.
  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    // Note: Caller must handle checkAndRequestPermission before listening
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Opens the device app settings.
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens device location settings.
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Returns a clean UX state for a position's accuracy.
  static LocationAccuracyLevel evaluateAccuracy(Position position) {
    return GeoLocationUtil.evaluateAccuracy(position.accuracy);
  }
}
