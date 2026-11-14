import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show LocationAccuracy;
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/map/geocoding.dart';
import 'package:skill_bridge/core/map/map_markers.dart';
import 'package:skill_bridge/core/map/sb_map.dart';
import 'package:skill_bridge/core/services/location_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// A place chosen on the map.
class LocationResult {
  final double latitude;
  final double longitude;

  /// The provider's address, or the coordinates when no address is known
  /// (address search switched off, or nothing found at that spot).
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
typedef PickerLocator = Future<({LatLng point, double accuracy})> Function();

Future<({LatLng point, double accuracy})> _deviceLocation() async {
  final p = await LocationService.getCurrentLocation(accuracy: LocationAccuracy.high);
  return (point: LatLng(p.latitude, p.longitude), accuracy: p.accuracy);
}

/// Choose a place by moving the map under a fixed pin (Navigation phase 3).
/// Address search (when configured) runs only when the person submits it.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation, this.locator = _deviceLocation});

  final LatLng? initialLocation;
  final PickerLocator locator;

  /// Whole-country view before the device is located (a viewport only;
  /// nothing can be confirmed until the person zooms in on a place).
  static const pakistanOverview = LatLng(30.3753, 69.3451);

  /// Closest zoom out at which a pin can be confirmed.
  static const minConfirmZoom = 13.0;

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

enum _LocateProblem { denied, blocked, serviceOff, failed }

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _map = MapController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  late LatLng _center = widget.initialLocation ?? LocationPickerScreen.pakistanOverview;
  late double _zoom = widget.initialLocation != null ? 16 : 5;
  bool _mapReady = false;

  GeocodedPlace? _place;
  bool _addressLoading = false;
  int _reverseSeq = 0;
  Timer? _settle;
  LatLng? _skipReverseAt;

  bool _locating = false;
  _LocateProblem? _locateProblem;
  ({LatLng point, double accuracy})? _gps;

  bool _searching = false;
  List<GeocodedPlace>? _results;
  String? _searchMessage;

  GeocodingService get _geo => ref.read(geocodingServiceProvider);

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _lookUpAddress(_center);
    } else {
      _locate();
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    _map.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _moveTo(LatLng point, double zoom) {
    _center = point;
    _zoom = zoom;
    if (_mapReady) _map.move(point, zoom);
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locateProblem = null;
    });
    try {
      final fix = await widget.locator();
      if (!mounted) return;
      setState(() {
        _gps = fix;
        _locating = false;
      });
      _moveTo(fix.point, 17);
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

  void _onCameraChanged(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    _zoom = camera.zoom;
    _settle?.cancel();
    // Look the address up once the map stops moving, not on every frame.
    _settle = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {});
      final skip = _skipReverseAt;
      if (skip != null && const Distance().as(LengthUnit.Meter, skip, _center) < 2) return;
      _skipReverseAt = null;
      _lookUpAddress(_center);
    });
    if (hasGesture && (_place != null || _results != null || _locateProblem != null)) {
      setState(() {
        _place = null;
        _results = null;
        // They're choosing on the map now; the location notice has done its job.
        _locateProblem = null;
      });
    }
  }

  Future<void> _lookUpAddress(LatLng point) async {
    if (!_geo.searchEnabled) return;
    final seq = ++_reverseSeq;
    setState(() => _addressLoading = true);
    final place = await _geo.reverse(point);
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
      final found = await _geo.search(q);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = found;
        _searchMessage = found.isEmpty ? l.pickerSearchNoResults : null;
      });
    } on GeocodingException {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = null;
        _searchMessage = l.pickerSearchFailed;
      });
    }
  }

  void _choose(GeocodedPlace place) {
    _searchFocus.unfocus();
    setState(() {
      _results = null;
      _locateProblem = null;
      _place = place;
      _addressLoading = false;
      _reverseSeq++;
      _skipReverseAt = place.point;
    });
    _moveTo(place.point, 17);
  }

  bool get _gpsStillHere => _gps != null && const Distance().as(LengthUnit.Meter, _gps!.point, _center) < 3;

  bool get _canConfirm => _mapReady && _zoom >= LocationPickerScreen.minConfirmZoom && !_addressLoading;

  void _confirm() {
    final p = _center;
    final coords = '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    final place = _place;
    Navigator.of(context).pop(LocationResult(
      latitude: p.latitude,
      longitude: p.longitude,
      formattedAddress: (place?.label ?? '').isNotEmpty ? place!.label : coords,
      city: place?.city ?? '',
      accuracy: _gpsStillHere ? GeoLocationUtil.evaluateAccuracy(_gps!.accuracy) : LocationAccuracyLevel.unknown,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    final searchEnabled = ref.watch(geocodingServiceProvider).searchEnabled;

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

    final hint = _locating
        ? l.pickerLocating
        : _zoom < LocationPickerScreen.minConfirmZoom
            ? l.pickerZoomInHint
            : l.pickerMoveHint;

    final coords = '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
    final address = _addressLoading
        ? l.pickerFindingAddress
        : (_place?.label ?? '').isNotEmpty
            ? _place!.label
            : l.pickerPinnedLocation;

    return Scaffold(
      appBar: AppBar(title: Text(l.pickerTitle)),
      body: Column(children: [
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
                  child: Text(l.pickerSearchAttribution, style: t.labelSmall),
                ),
              ]),
            ),
          ),
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: SbMap(
                controller: _map,
                initialCenter: _center,
                initialZoom: _zoom,
                allowRotation: false,
                showZoomButtons: true,
                onRecenter: _locating ? null : _locate,
                onMapReady: () {
                  _mapReady = true;
                  if (mounted) setState(() {});
                },
                onPositionChanged: _onCameraChanged,
                layers: [
                  if (_gps != null)
                    MarkerLayer(markers: [sbCurrentLocationMarker(_gps!.point, semanticLabel: l.mapYouAreHere)]),
                ],
              ),
            ),
            // The fixed pin: its tip marks the map's centre.
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 52),
                  child: SizedBox(width: 44, height: 52, child: SbDestinationPin(semanticLabel: l.pickerPinnedLocation)),
                ),
              ),
            ),
            PositionedDirectional(
              top: SbSpace.s3,
              start: SbSpace.s3,
              end: SbSpace.s3,
              child: problem != null
                  ? SbInlineBanner(message: problem, tone: SbTone.warning, actionLabel: fixLabel, onAction: fix)
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3, vertical: SbSpace.s2),
                        decoration: BoxDecoration(color: sb.surfaceRaised, borderRadius: BorderRadius.circular(SbRadius.full), boxShadow: SbElevation.overlay),
                        child: Text(hint, style: t.bodySmall, textAlign: TextAlign.center),
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
                      Text(address, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(coords, style: SbTypography.numeric(t.bodySmall!), textDirection: TextDirection.ltr),
                      if (_gpsStillHere) Text(l.liveAccuracy(_gps!.accuracy.round()), style: t.bodySmall),
                    ]),
                  ),
                ]),
                const SizedBox(height: SbSpace.s3),
                SbButton(label: l.pickerConfirm, icon: Icons.check_rounded, expand: true, onPressed: _canConfirm ? _confirm : null),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
