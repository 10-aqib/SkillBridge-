import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time settings for maps, routing and address search (Navigation
/// phase 2). None of them is a secret, and none needs an API key by default.
///
/// Every value can be changed without code changes, for example to move from
/// the public OpenStreetMap services (fine for development, but with no
/// availability guarantee and strict usage policies) to a paid or
/// self-hosted provider:
///
///   flutter run --dart-define=ROUTING_BASE_URL=https://osrm.example.com
///
/// A blank value (as in a copied `.env.example`) means "use the default".

/// Identifies the app to tile and geocoding servers (the OSM tile and
/// Nominatim policies require a real app identifier). Matches the Android
/// application id.
const appUserAgentPackage = 'com.skillbridge.skill_bridge';

String _orDefault(String value, String fallback) => value.trim().isEmpty ? fallback : value.trim();

/// Accepts https, or http only for a local development host.
bool _isAllowedBaseUri(Uri? uri) {
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return false;
  if (uri.scheme == 'https') return true;
  const localHosts = {'localhost', '127.0.0.1', '10.0.2.2', '[::1]', '::1'};
  return uri.scheme == 'http' && localHosts.contains(uri.host);
}

/// Map tiles: any XYZ raster tile server.
class MapTileConfig {
  const MapTileConfig({
    required this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
    required this.attributionUrl,
    this.maxZoom = 19,
  });

  static const defaultUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const defaultAttribution = '© OpenStreetMap contributors';
  static const defaultAttributionUrl = 'https://www.openstreetmap.org/copyright';

  /// `{z}`, `{x}` and `{y}` are required; `{s}` picks one of [subdomains];
  /// `{r}` is the retina suffix (flutter_map fills it in).
  final String urlTemplate;
  final List<String> subdomains;

  /// Shown on every map, as the tile provider's licence requires.
  final String attribution;
  final String attributionUrl;
  final int maxZoom;

  factory MapTileConfig.fromValues({
    String urlTemplate = '',
    String subdomains = '',
    String attribution = '',
    String attributionUrl = '',
    String maxZoom = '',
  }) {
    final zoom = int.tryParse(maxZoom.trim());
    return MapTileConfig(
      urlTemplate: _orDefault(urlTemplate, defaultUrlTemplate),
      subdomains: subdomains.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      attribution: _orDefault(attribution, defaultAttribution),
      attributionUrl: _orDefault(attributionUrl, defaultAttributionUrl),
      maxZoom: zoom == null ? 19 : zoom.clamp(1, 22),
    );
  }

  factory MapTileConfig.fromEnvironment() => MapTileConfig.fromValues(
        urlTemplate: const String.fromEnvironment('MAP_TILE_URL'),
        subdomains: const String.fromEnvironment('MAP_TILE_SUBDOMAINS'),
        attribution: const String.fromEnvironment('MAP_TILE_ATTRIBUTION'),
        attributionUrl: const String.fromEnvironment('MAP_TILE_ATTRIBUTION_URL'),
        maxZoom: const String.fromEnvironment('MAP_TILE_MAX_ZOOM'),
      );

  /// A usable template: https (or local http), all of `{z}` `{x}` `{y}`,
  /// and subdomains when it uses `{s}`. Otherwise maps show "unavailable".
  bool get isValid {
    final t = urlTemplate;
    if (!t.contains('{z}') || !t.contains('{x}') || !t.contains('{y}')) return false;
    if (t.contains('{s}') && subdomains.isEmpty) return false;
    final probe = t
        .replaceAll('{s}', subdomains.isEmpty ? 'a' : subdomains.first)
        .replaceAll(RegExp(r'\{[a-z]+\}'), '0');
    return _isAllowedBaseUri(Uri.tryParse(probe));
  }

  /// The public OSM servers: no bulk or offline downloads allowed.
  bool get isPublicOsm => urlTemplate.contains('tile.openstreetmap.org');
}

/// Road routing: an OSRM-compatible `/route/v1` service.
class RoutingConfig {
  const RoutingConfig({required this.baseUrl, required this.profile});

  static const defaultBaseUrl = 'https://router.project-osrm.org';
  static const defaultProfile = 'driving';

  final String baseUrl;

  /// OSRM profile in the URL (`driving`, `cycling`, `walking`); the public
  /// demo server only routes cars, whatever the profile says.
  final String profile;

  factory RoutingConfig.fromValues({String baseUrl = '', String profile = ''}) {
    var base = _orDefault(baseUrl, defaultBaseUrl);
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return RoutingConfig(baseUrl: base, profile: _orDefault(profile, defaultProfile));
  }

  factory RoutingConfig.fromEnvironment() => RoutingConfig.fromValues(
        baseUrl: const String.fromEnvironment('ROUTING_BASE_URL'),
        profile: const String.fromEnvironment('ROUTING_PROFILE'),
      );

  bool get isValid => _isAllowedBaseUri(Uri.tryParse(baseUrl)) && RegExp(r'^[a-z_-]{1,32}$').hasMatch(profile);

  /// The public demo server: development only, no availability guarantee.
  bool get isPublicDemo => Uri.tryParse(baseUrl)?.host == 'router.project-osrm.org';
}

enum GeocodingProvider {
  /// Nominatim-compatible search (public Nominatim, a self-hosted one, or a
  /// compatible commercial endpoint). Search runs only when the user submits,
  /// never as autocomplete, and at most once a second.
  nominatim,

  /// No address search: destinations are picked on the map.
  none,
}

/// Address search and reverse geocoding.
class GeocodingConfig {
  const GeocodingConfig({required this.provider, required this.baseUrl, required this.countryCodes});

  static const defaultBaseUrl = 'https://nominatim.openstreetmap.org';
  static const defaultCountryCodes = 'pk';

  final GeocodingProvider provider;
  final String baseUrl;

  /// ISO 3166-1 alpha-2 codes, comma separated, to limit results.
  final String countryCodes;

  /// With no provider chosen, debug builds search the public Nominatim
  /// server. Release builds don't: its policy
  /// (https://operations.osmfoundation.org/policies/nominatim/) requires
  /// that an app can switch away from it without a software update, which
  /// a compiled-in address can't do. Release builds pick on the map only,
  /// unless a provider is set explicitly.
  factory GeocodingConfig.fromValues({
    String provider = '',
    String baseUrl = '',
    String countryCodes = '',
    bool releaseBuild = false,
  }) {
    var base = _orDefault(baseUrl, defaultBaseUrl);
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final p = provider.trim().toLowerCase();
    final GeocodingProvider chosen;
    if (p == 'none' || p == 'off') {
      chosen = GeocodingProvider.none;
    } else if (p == 'nominatim') {
      chosen = GeocodingProvider.nominatim;
    } else {
      // Unset (or unknown): public server for development only.
      chosen = releaseBuild ? GeocodingProvider.none : GeocodingProvider.nominatim;
    }
    return GeocodingConfig(
      provider: chosen,
      baseUrl: base,
      countryCodes: _orDefault(countryCodes, defaultCountryCodes).toLowerCase(),
    );
  }

  factory GeocodingConfig.fromEnvironment() => GeocodingConfig.fromValues(
        provider: const String.fromEnvironment('GEOCODING_PROVIDER'),
        baseUrl: const String.fromEnvironment('GEOCODING_BASE_URL'),
        countryCodes: const String.fromEnvironment('GEOCODING_COUNTRY_CODES'),
        releaseBuild: kReleaseMode,
      );

  /// The public OSM server (strict policy: no autocomplete, ≤ 1 request/s).
  bool get isPublicNominatim => Uri.tryParse(baseUrl)?.host == 'nominatim.openstreetmap.org';

  /// Search is available: a provider is chosen and its address is usable.
  bool get searchEnabled => provider != GeocodingProvider.none && _isAllowedBaseUri(Uri.tryParse(baseUrl));
}

/// Overridden in tests.
final mapTileConfigProvider = Provider<MapTileConfig>((ref) => MapTileConfig.fromEnvironment());
final routingConfigProvider = Provider<RoutingConfig>((ref) => RoutingConfig.fromEnvironment());
final geocodingConfigProvider = Provider<GeocodingConfig>((ref) => GeocodingConfig.fromEnvironment());
