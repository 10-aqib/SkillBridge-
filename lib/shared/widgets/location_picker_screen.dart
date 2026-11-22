import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show LocationAccuracy;
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/map_unavailable.dart';
import 'package:skill_bridge/core/map/maps_api.dart';
import 'package:skill_bridge/core/map/maps_config.dart';
import 'package:skill_bridge/core/map/sb_google_map.dart';
import 'package:skill_bridge/core/services/location_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// A place chosen on the map.
class LocationResult {
  final double latitude;
  final double longitude;

  /// The place's address, or the coordinates when no address is known.
  final String formattedAddress;

  /// Town or city in English, or '' when unknown.
  final String city;

  /// GPS accuracy when the pin is still where the device located itself;
  /// unknown once the person moves the map.
  final LocationAccuracyLevel accuracy;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.accuracy,
  });
}

/// The device's location, behind a function so tests can replace it.
typedef PickerLocator = Future<({GeoCoord point, double accuracy})> Function();

Future<({GeoCoord point, double accuracy})> _deviceLocation() async {
  final p = await LocationService.getCurrentLocation(accuracy: LocationAccuracy.high);
  return (point: GeoCoord(p.latitude, p.longitude), accuracy: p.accuracy);
}

/// Choose a place by moving a Google map under a fixed pin (Phase G2),
/// starting from the device's GPS position or the place already chosen
/// ([initialLocation]). Address search (submit only) and the address of the
/// pinned spot come from Google through the maps functions (G3); when those
/// aren't deployed, the pin still works with coordinates as the address.
/// Without a Maps key the screen still works: it confirms the GPS position
/// (or the kept place) without a map.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation, this.locator = _deviceLocation});

  final GeoCoord? initialLocation;
  final PickerLocator locator;

  /// Whole-country view before the device is located (a viewport only;
  /// nothing can be confirmed until the person zooms in on a place).
  static const pakistanOverview = GeoCoord(30.3753, 69.3451);

  /// Closest zoom out at which a pin on the map can be confirmed.
  static const minConfirmZoom = 13.0;

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

enum _LocateProblem { denied, blocked, serviceOff, failed }

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late GeoCoord? _point = widget.initialLocation != null && widget.initialLocation!.isValid ? widget.initialLocation : null;

  SbMapController? _map;

  /// The map's centre and zoom while the map is shown.
  late GeoCoord _center = _point ?? LocationPickerScreen.pakistanOverview;
  late double _zoom = _point != null ? 16 : 5;

  bool _locating = false;
  _LocateProblem? _locateProblem;
  ({GeoCoord point, double accuracy})? _gps;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;
  List<MapPlace>? _results;
  String? _searchMessage;

  /// Address of the pinned spot, and where it was looked up.
  MapPlace? _place;
  GeoCoord? _lookedUpAt;
  bool _addressLoading = false;
  int _reverseSeq = 0;
  Timer? _settle;

  MapsApi get _api => ref.read(mapsApiProvider);

  @override
  void initState() {
    super.initState();
    if (_point == null) {
      _locate();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lookUpAddress(_point!);
      });
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Looks up the address of [point] once the map has settled there.
  Future<void> _lookUpAddress(GeoCoord point) async {
    if (!_withMap || !_api.available) return;
    final last = _lookedUpAt;
    if (last != null && distanceMetres(last, point) < 2) return;
    final seq = ++_reverseSeq;
    _lookedUpAt = point;
    setState(() => _addressLoading = true);
    MapPlace? place;
    try {
      place = await _api.reverse(point);
    } on MapsApiException {
      place = null;
    }
    if (!mounted || seq != _reverseSeq) return;
    setState(() {
      _place = place;
      _addressLoading = false;
    });
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    final l = context.l10n;
    if (q.length < 3) {
      setState(() {
        _results = null;
        _searchMessage = l.pickerSearchTooShort;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final found = await _api.search(q, near: _gps?.point ?? (_zoom >= 10 ? _center : null));
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = found;
        _searchMessage = found.isEmpty ? l.pickerSearchNoResults : null;
      });
    } on MapsApiException {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = null;
        _searchMessage = l.pickerSearchFailed;
      });
    }
  }

  void _choose(MapPlace place) {
    _searchFocus.unfocus();
    setState(() {
      _results = null;
      _locateProblem = null;
      _place = place;
      _lookedUpAt = place.point;
      _addressLoading = false;
      _reverseSeq++;
      _center = place.point;
      _zoom = 17;
    });
    _map?.moveTo(place.point, zoom: 17);
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locateProblem = null;
    });
    try {
      final fix = await widget.locator();
      if (!mounted) return;
      if (!fix.point.isValid) throw const FormatException('invalid fix');
      setState(() {
        _gps = fix;
        _point = fix.point;
        _center = fix.point;
        _zoom = 17;
        _locating = false;
      });
      _map?.moveTo(fix.point, zoom: 17);
      // Location is allowed now, so the map can draw the blue dot.
      ref.invalidate(mapMyLocationAllowedProvider);
      _lookUpAddress(fix.point);
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locateProblem = e.isSettingsRequired
            ? _LocateProblem.blocked
            : e.isServiceDisabled
                ? _LocateProblem.serviceOff
                : e.isPermissionDenied
                    ? _LocateProblem.denied
                    : _LocateProblem.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locateProblem = _LocateProblem.failed;
      });
    }
  }

  bool get _withMap => ref.read(mapsAvailableProvider);

  /// The place that would be confirmed: the map centre with a map,
  /// otherwise the GPS fix or kept place.
  GeoCoord? get _chosen => _withMap ? _center : _point;

  bool get _gpsStillHere => _gps != null && _chosen != null && distanceMetres(_gps!.point, _chosen!) < 3;

  bool get _canConfirm =>
      !_locating && !_addressLoading && _chosen != null && (!_withMap || (_mapReady && _zoom >= LocationPickerScreen.minConfirmZoom));

  /// The looked-up address, if it is for the spot that would be confirmed.
  MapPlace? get _placeHere {
    final place = _place, here = _chosen;
    if (place == null || here == null) return null;
    final at = _lookedUpAt ?? place.point;
    return distanceMetres(at, here) < 25 ? place : null;
  }

  bool _mapReady = false;

  void _onCamera(SbCamera cam) {
    _center = cam.center;
    _zoom = cam.zoom;
  }

  void _onCameraIdle() {
    if (!mounted) return;
    setState(() {});
    _settle?.cancel();
    // Look the address up once the map stops moving, not on every frame.
    _settle = Timer(const Duration(milliseconds: 700), () {
      if (mounted && _zoom >= LocationPickerScreen.minConfirmZoom) _lookUpAddress(_center);
    });
  }

  void _confirm() {
    final p = _chosen!;
    final coords = '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    final place = _placeHere;
    Navigator.of(context).pop(LocationResult(
      latitude: p.latitude,
      longitude: p.longitude,
      formattedAddress: place != null && place.label.isNotEmpty ? place.label : coords,
      city: place?.city ?? '',
      accuracy: _gpsStillHere ? GeoLocationUtil.evaluateAccuracy(_gps!.accuracy) : LocationAccuracyLevel.unknown,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;

    final (String? problem, String? fixLabel, VoidCallback? fix) = switch (_locateProblem) {
      null => (null, null, null),
      _LocateProblem.denied => (l.pickerLocationDenied, l.tryAgain, _locate),
      // Browsers have no app or location settings page to open; there the
      // person changes the site's permission themselves.
      _LocateProblem.blocked => kIsWeb
          ? (l.pickerLocationBlocked, null, null)
          : (l.pickerLocationBlocked, l.liveOpenSettings, () => LocationService.openAppSettings()),
      _LocateProblem.serviceOff => kIsWeb
          ? (l.pickerLocationServiceOff, null, null)
          : (l.pickerLocationServiceOff, l.liveOpenSettings, () => LocationService.openLocationSettings()),
      _LocateProblem.failed => (l.pickerLocationFailed, l.tryAgain, _locate),
    };

    final withMap = ref.watch(mapsAvailableProvider);
    final searchEnabled = withMap && ref.watch(mapsApiProvider).available;
    final p = _chosen;
    final place = _placeHere;
    final hint = _locating
        ? l.pickerLocating
        : _zoom < LocationPickerScreen.minConfirmZoom
            ? l.pickerZoomInHint
            : l.pickerMoveHint;
    return Scaffold(
      appBar: AppBar(title: Text(l.pickerTitle)),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (searchEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(SbSpace.s4, SbSpace.s2, SbSpace.s4, SbSpace.s2),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: l.pickerSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(SbSpace.s3), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(tooltip: l.search, icon: const Icon(Icons.arrow_forward_rounded), onPressed: _search),
              ),
            ),
          ),
        if (_searchMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(SbSpace.s4, 0, SbSpace.s4, SbSpace.s2),
            child: SbInlineBanner(message: _searchMessage!, tone: SbTone.info),
          ),
        if (_results != null && _results!.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Material(
              color: sb.surface,
              child: ListView(shrinkWrap: true, children: [
                for (final r in _results!)
                  ListTile(
                    leading: Icon(Icons.place_outlined, color: sb.primary),
                    title: Text(r.name.isEmpty ? r.label : r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(r.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _choose(r),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(SbSpace.s4, SbSpace.s1, SbSpace.s4, SbSpace.s2),
                  child: Text(l.pickerSearchAttributionGoogle, style: t.labelSmall),
                ),
              ]),
            ),
          ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(SbSpace.s4, SbSpace.s3, SbSpace.s4, 0),
            child: SbInlineBanner(message: problem, tone: SbTone.warning, actionLabel: fixLabel, onAction: fix),
          ),
        Expanded(
          child: !withMap
              ? SbMapUnavailable.standard(context)
              : Stack(children: [
                  Positioned.fill(
                    child: SbGoogleMap(
                      initialCenter: _center,
                      initialZoom: _zoom,
                      showMyLocation: true,
                      showZoomButtons: true,
                      onRecenter: _locating ? null : _locate,
                      onCreated: (m) {
                        _map = m;
                        setState(() => _mapReady = true);
                      },
                      onCameraMove: _onCamera,
                      onCameraIdle: _onCameraIdle,
                      onUserGesture: () {
                        // They're choosing on the map now; the location notice and old
                        // search results have done their job.
                        if (_locateProblem != null || _results != null) {
                          setState(() {
                            _locateProblem = null;
                            _results = null;
                          });
                        }
                      },
                    ),
                  ),
                  // The fixed pin: its tip marks the map's centre.
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 44),
                        child: Icon(Icons.location_on, size: 48, color: sb.error, semanticLabel: l.pickerPinnedLocation),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: SbSpace.s3,
                    start: SbSpace.s3,
                    end: SbSpace.s3,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3, vertical: SbSpace.s2),
                          decoration: BoxDecoration(color: sb.surfaceRaised, borderRadius: BorderRadius.circular(SbRadius.full), boxShadow: SbElevation.overlay),
                          child: Text(hint, style: t.bodySmall, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                ]),
        ),
        Material(
          color: sb.surface,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(SbSpace.s4),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.place_rounded, color: sb.accent),
                  const SizedBox(width: SbSpace.s3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                          _locating
                              ? l.pickerLocating
                              : _addressLoading
                                  ? l.pickerFindingAddress
                                  : (place?.label ?? '').isNotEmpty
                                      ? place!.label
                                      : l.pickerPinnedLocation,
                          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (p != null)
                        Text('${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                            style: SbTypography.numeric(t.bodySmall!), textDirection: TextDirection.ltr),
                      if (_gpsStillHere) Text(l.liveAccuracy(_gps!.accuracy.round()), style: t.bodySmall),
                    ]),
                  ),
                ]),
                const SizedBox(height: SbSpace.s3),
                if (!withMap) ...[
                  SbButton(
                    label: l.mapRecenter,
                    icon: Icons.my_location_rounded,
                    variant: SbButtonVariant.secondary,
                    expand: true,
                    isLoading: _locating,
                    onPressed: _locating ? null : _locate,
                  ),
                  const SizedBox(height: SbSpace.s2),
                ],
                SbButton(label: l.pickerConfirm, icon: Icons.check_rounded, expand: true, onPressed: _canConfirm ? _confirm : null),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
