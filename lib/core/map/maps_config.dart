import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/location/device_location.dart';

import 'maps_platform_io.dart' if (dart.library.js_interop) 'maps_platform_web.dart' as platform;

export 'maps_platform_io.dart' if (dart.library.js_interop) 'maps_platform_web.dart' show prepareGoogleMaps;

/// Whether Google Maps can be drawn in this build: a key was configured
/// (and, on web, the Maps JavaScript API loaded and accepted it).
/// Overridden in tests.
final mapsAvailableProvider = Provider<bool>((ref) => platform.googleMapsKeyConfigured && !platform.googleMapsAuthFailed);

/// Whether the "you are here" dot may be drawn: location is already
/// allowed. Maps never ask for location on their own; the screens that need
/// a position ask, with an explanation.
final mapMyLocationAllowedProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await ref.watch(locationSourceProvider).checkAccess() == LocationAccess.granted;
  } catch (_) {
    return false;
  }
});
