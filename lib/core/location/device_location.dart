import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/utils/logger.dart';

export 'package:skill_bridge/core/location/geo_coord.dart' show GeoCoord, bearingBetween, distanceMetres;

/// The device's location (Navigation phase 4): one source for every feature
/// that needs GPS (map screens, live sharing, directions), so
/// permission, accuracy, timeouts and battery use are handled in one place.
///
/// Foreground only: no background location permission is requested, and on
/// iOS background updates are explicitly switched off.

/// Device location access, before using location.
enum LocationAccess { granted, denied, deniedForever, serviceOff, unavailable }

/// One position fix. Optional values are null when the device didn't report
/// them or reported them as invalid (iOS uses -1, some Android devices 0).
@immutable
class GeoFix {
  const GeoFix({
    required this.lat,
    required this.lng,
    required this.accuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
    this.altitude,
    this.takenAt,
    this.isMocked = false,
  });

  final double lat;
  final double lng;

  /// Horizontal accuracy radius in metres (68 % confidence).
  final double accuracy;

  /// Direction of travel, degrees clockwise from true north (0–360).
  final double? heading;
  final double? headingAccuracy;

  /// Metres per second.
  final double? speed;
  final double? speedAccuracy;
  final double? altitude;

  /// When the device took the fix (device clock); null if not reported.
  final DateTime? takenAt;

  DateTime get timestamp => takenAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  bool get hasTimestamp => takenAt != null;

  /// Reported by a mock-location app (Android developer option).
  final bool isMocked;

  GeoCoord get point => GeoCoord(lat, lng);

  /// Valid coordinates and a usable accuracy value.
  bool get isValid =>
      lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180 && !(lat == 0 && lng == 0) && accuracy.isFinite && accuracy >= 0;

  /// Speed below which the reported heading is noise (≈ 5 km/h).
  static const minSpeedForHeading = 1.4;

  /// Heading is meaningful only while moving; standing still, GPS headings
  /// swing randomly.
  bool get hasReliableHeading =>
      heading != null && speed != null && speed! >= minSpeedForHeading && (headingAccuracy == null || headingAccuracy! <= 45);

  /// Age of the fix at [now].
  Duration ageAt(DateTime now) => hasTimestamp ? now.difference(timestamp) : Duration.zero;

  static double? _valid(double v, {double min = 0, double max = double.infinity}) =>
      v.isFinite && v >= min && v <= max ? v : null;

  factory GeoFix.fromPosition(Position p) {
    final speed = _valid(p.speed, max: 100);
    final heading = _valid(p.heading, max: 360);
    final headingAccuracy = _valid(p.headingAccuracy);
    return GeoFix(
      lat: p.latitude,
      lng: p.longitude,
      accuracy: p.accuracy,
      // A heading of exactly 0 with no accuracy is how many devices say
      // "unknown"; treat it as missing unless the device is moving.
      heading: heading == 0 && (headingAccuracy == null || headingAccuracy == 0) && (speed ?? 0) < GeoFix.minSpeedForHeading ? null : heading,
      headingAccuracy: headingAccuracy == 0 ? null : headingAccuracy,
      speed: speed,
      speedAccuracy: _valid(p.speedAccuracy) == 0 ? null : _valid(p.speedAccuracy),
      altitude: p.altitude.isFinite ? p.altitude : null,
      takenAt: p.timestamp,
      isMocked: p.isMocked,
    );
  }

  /// Straight-line distance in metres (for filtering, never shown as a
  /// road distance).
  double metresTo(GeoFix other) => distanceMetres(point, other.point);

  // Safe for any value, including NaN and infinity (dropped fixes are logged).
  @override
  String toString() {
    String n(double? v, int digits) => v == null ? '-' : (v.isFinite ? v.toStringAsFixed(digits) : '$v');
    return 'GeoFix(${n(lat, 6)}, ${n(lng, 6)} ±${n(accuracy, 0)}m'
        '${heading == null ? '' : ' ${n(heading, 0)}°'}${speed == null ? '' : ' ${n(speed, 1)}m/s'})';
  }
}

/// How often and how precisely to track, by use. Each feature asks for the
/// least it needs, to save battery.
enum LocationProfile {
  /// Showing "you are here" on a map.
  display(
    accuracy: LocationAccuracy.high,
    distanceFilter: 15,
    interval: Duration(seconds: 5),
    staleAfter: Duration(seconds: 45),
    firstFixTimeout: Duration(seconds: 20),
  ),

  /// Live sharing with the client (positions are written at most every 15 s).
  sharing(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
    interval: Duration(seconds: 5),
    staleAfter: Duration(seconds: 60),
    firstFixTimeout: Duration(seconds: 20),
  ),

  /// Turn-by-turn navigation: best accuracy, about one fix a second.
  navigation(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
    interval: Duration(seconds: 1),
    staleAfter: Duration(seconds: 12),
    firstFixTimeout: Duration(seconds: 25),
  );

  const LocationProfile({
    required this.accuracy,
    required this.distanceFilter,
    required this.interval,
    required this.staleAfter,
    required this.firstFixTimeout,
  });

  final LocationAccuracy accuracy;

  /// Metres the device must move before a new fix is delivered.
  final int distanceFilter;

  /// Android: wanted time between fixes.
  final Duration interval;

  /// No new fix for this long means the signal is lost (tunnel, indoors,
  /// GPS off): positions are then shown as old, never as current.
  final Duration staleAfter;

  /// Longest wait for the first fix.
  final Duration firstFixTimeout;

  /// Platform settings for this profile. Never background updates.
  LocationSettings settings({bool web = kIsWeb, TargetPlatform? platform}) {
    if (web) {
      // Browsers decide intervals themselves; maximumAge 0 refuses cached
      // positions so an old one isn't shown as new.
      return WebSettings(accuracy: accuracy, distanceFilter: distanceFilter, maximumAge: Duration.zero);
    }
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(accuracy: accuracy, distanceFilter: distanceFilter, intervalDuration: interval);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          activityType: this == LocationProfile.navigation ? ActivityType.automotiveNavigation : ActivityType.other,
          // iOS may pause updates when the device stops moving, except
          // while navigating.
          pauseLocationUpdatesAutomatically: this != LocationProfile.navigation,
          allowBackgroundLocationUpdates: false,
          showBackgroundLocationIndicator: false,
        );
      default:
        return LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
    }
  }
}

/// The device's location, behind an interface so it can be replaced in tests.
abstract class LocationSource {
  /// Current access without asking (for showing state).
  Future<LocationAccess> checkAccess();

  /// Current access, asking for permission if it hasn't been decided yet.
  Future<LocationAccess> ensureAccess();

  /// False when the person allowed only approximate location (Android 12+,
  /// iOS 14+): positions can then be kilometres off.
  Future<bool> isPrecise();

  /// One fresh fix. Throws [TimeoutException] after [timeLimit].
  Future<GeoFix> current({Duration timeLimit = const Duration(seconds: 20), LocationProfile profile = LocationProfile.sharing});

  /// Continuous fixes for [profile] until the subscription is cancelled.
  Stream<GeoFix> watch([LocationProfile profile = LocationProfile.sharing]);

  /// True/false as location services (GPS) are switched on or off. Empty
  /// where the platform can't report it (web).
  Stream<bool> serviceEnabledChanges();

  /// Whether [openAppSettings]/[openLocationSettings] can do anything here
  /// (not in a browser).
  bool get canOpenSettings;

  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  static LocationAccess _access(LocationPermission p) => switch (p) {
        LocationPermission.denied => LocationAccess.denied,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.unableToDetermine => LocationAccess.unavailable,
        _ => LocationAccess.granted,
      };

  @override
  Future<LocationAccess> checkAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
      return _access(await Geolocator.checkPermission());
    } catch (e) {
      Logger.w('[Location] access check failed: $e');
      return LocationAccess.unavailable;
    }
  }

  @override
  Future<LocationAccess> ensureAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      return _access(permission);
    } catch (e) {
      Logger.w('[Location] permission request failed: $e');
      return LocationAccess.unavailable;
    }
  }

  @override
  Future<bool> isPrecise() async {
    if (kIsWeb) return true; // browsers don't report it
    try {
      return await Geolocator.getLocationAccuracy() != LocationAccuracyStatus.reduced;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<GeoFix> current({Duration timeLimit = const Duration(seconds: 20), LocationProfile profile = LocationProfile.sharing}) async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: profile.accuracy, timeLimit: timeLimit),
    ).timeout(timeLimit + const Duration(seconds: 3));
    return GeoFix.fromPosition(p);
  }

  @override
  Stream<GeoFix> watch([LocationProfile profile = LocationProfile.sharing]) =>
      Geolocator.getPositionStream(locationSettings: profile.settings()).map(GeoFix.fromPosition);

  @override
  Stream<bool> serviceEnabledChanges() {
    if (kIsWeb) return const Stream.empty();
    return Geolocator.getServiceStatusStream().map((s) => s == ServiceStatus.enabled).handleError((Object e) {
      Logger.w('[Location] service status stream failed: $e');
    });
  }

  @override
  bool get canOpenSettings => !kIsWeb;

  @override
  Future<bool> openAppSettings() => kIsWeb ? Future.value(false) : Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => kIsWeb ? Future.value(false) : Geolocator.openLocationSettings();
}

/// Overridden in tests.
final locationSourceProvider = Provider<LocationSource>((ref) => const GeolocatorLocationSource());
