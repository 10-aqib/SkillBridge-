// Android and iOS: the Maps SDK reads its key from the platform build
// (Android manifest placeholder / iOS Info.plist), filled from the same
// `GOOGLE_MAPS_API_KEY` value as this check. See .env.example.

/// Whether this build was given a Maps key (empty means maps show
/// "Map unavailable" instead of a grey, unauthorised map).
bool get googleMapsKeyConfigured => const String.fromEnvironment('GOOGLE_MAPS_API_KEY').isNotEmpty;

/// Nothing to load on mobile: the native SDK ships with the app.
Future<bool> prepareGoogleMaps() async => googleMapsKeyConfigured;

/// Mobile SDKs report a bad key only in the device log.
bool get googleMapsAuthFailed => false;
