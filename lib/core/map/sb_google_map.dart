import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/map_unavailable.dart';
import 'package:skill_bridge/core/map/maps_config.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The one map widget every screen uses (Phase G2): Google Maps through
/// `google_maps_flutter`, with the states a map can be in (no key, loading,
/// offline) and SkillBridge's own controls (recenter, zoom).
///
/// Screens describe what to draw with plain data ([SbMarker], [SbCircle],
/// [SbPolyline]) in [GeoCoord]s; only this file knows Google's types, and
/// tests swap the Google view for a fake through [sbMapViewBuilderProvider].

/// What a marker stands for; decides its colour.
enum SbMarkerKind {
  /// A pinned job place or route destination (red).
  destination,

  /// A person: the worker on the client's map, or a nearby worker (azure).
  person,

  /// The person selected in a list (orange).
  selectedPerson,

  /// A searched or chosen centre that isn't the device (green).
  place,
}

@immutable
class SbMarker {
  const SbMarker({required this.id, required this.position, required this.kind, this.title, this.stale = false, this.onTap});
  final String id;
  final GeoCoord position;
  final SbMarkerKind kind;

  /// Shown in the marker's info window when tapped.
  final String? title;

  /// An out-of-date position, drawn faded.
  final bool stale;
  final VoidCallback? onTap;
}

@immutable
class SbCircle {
  const SbCircle({required this.id, required this.center, required this.radiusMetres});
  final String id;
  final GeoCoord center;
  final double radiusMetres;
}

@immutable
class SbPolyline {
  const SbPolyline({required this.id, required this.points});
  final String id;
  final List<GeoCoord> points;
}

/// Camera position reported by the map.
typedef SbCamera = ({GeoCoord center, double zoom});

/// Moves the camera. Calls before the map is ready are ignored.
abstract class SbMapController {
  Future<void> moveTo(GeoCoord point, {double? zoom, bool animate = true});

  /// Shows all [points], [padding] pixels from the edges, never closer than
  /// [maxZoom] (so two nearby points don't fill the screen).
  Future<void> fit(List<GeoCoord> points, {double padding = 56, double maxZoom = 16});
}

/// Everything the Google view needs; built by [SbGoogleMap].
@immutable
class SbMapViewSpec {
  const SbMapViewSpec({
    required this.initialCenter,
    required this.initialZoom,
    required this.markers,
    required this.circles,
    required this.polylines,
    required this.interactive,
    required this.lite,
    required this.showMyLocation,
    required this.dark,
    required this.padding,
    required this.onCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
  });

  final GeoCoord initialCenter;
  final double initialZoom;
  final List<SbMarker> markers;
  final List<SbCircle> circles;
  final List<SbPolyline> polylines;
  final bool interactive;
  final bool lite;
  final bool showMyLocation;
  final bool dark;
  final EdgeInsets padding;
  final void Function(SbMapController controller) onCreated;
  final void Function(SbCamera camera)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final void Function(GeoCoord point)? onTap;
}

typedef SbMapViewBuilder = Widget Function(BuildContext context, SbMapViewSpec spec);

/// Builds the real Google map. Tests override this with a fake view.
final sbMapViewBuilderProvider = Provider<SbMapViewBuilder>((ref) => (context, spec) => _GoogleMapView(spec: spec));

class SbGoogleMap extends ConsumerStatefulWidget {
  const SbGoogleMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15,
    this.markers = const [],
    this.circles = const [],
    this.polylines = const [],
    this.interactive = true,
    this.lite = false,
    this.showMyLocation = false,
    this.padding = EdgeInsets.zero,
    this.onCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onUserGesture,
    this.onTap,
    this.onRecenter,
    this.showZoomButtons = false,
    this.semanticLabel,
  });

  final GeoCoord initialCenter;
  final double initialZoom;
  final List<SbMarker> markers;
  final List<SbCircle> circles;
  final List<SbPolyline> polylines;

  /// False for small previews inside scrolling pages: no gestures, no
  /// controls; the page scrolls over it.
  final bool interactive;

  /// Android lite mode (a static map image; cheap for previews).
  final bool lite;

  /// Draw the device's blue dot when location is already allowed.
  final bool showMyLocation;

  /// Space covered by the screen's own panels, so Google's logo and the
  /// camera centre stay visible.
  final EdgeInsets padding;
  final void Function(SbMapController controller)? onCreated;
  final void Function(SbCamera camera)? onCameraMove;
  final VoidCallback? onCameraIdle;

  /// The person touched the map (to stop following, for example).
  final VoidCallback? onUserGesture;
  final void Function(GeoCoord point)? onTap;

  /// Shows a "show my location" button that calls this.
  final VoidCallback? onRecenter;
  final bool showZoomButtons;
  final String? semanticLabel;

  @override
  ConsumerState<SbGoogleMap> createState() => _SbGoogleMapState();
}

class _SbGoogleMapState extends ConsumerState<SbGoogleMap> {
  SbMapController? _controller;
  SbCamera? _camera;
  bool _ready = false;

  void _onCreated(SbMapController c) {
    _controller = c;
    if (mounted) setState(() => _ready = true);
    widget.onCreated?.call(c);
  }

  Future<void> _zoomBy(double delta) async {
    final c = _controller;
    final cam = _camera ?? (center: widget.initialCenter, zoom: widget.initialZoom);
    if (c == null) return;
    await c.moveTo(cam.center, zoom: (cam.zoom + delta).clamp(3, 20).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    if (!ref.watch(mapsAvailableProvider) || !widget.initialCenter.isValid) {
      return SbMapUnavailable.standard(context);
    }
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final myLocation = widget.showMyLocation && (ref.watch(mapMyLocationAllowedProvider).value ?? false);
    final spec = SbMapViewSpec(
      initialCenter: widget.initialCenter,
      initialZoom: widget.initialZoom,
      markers: widget.markers,
      circles: widget.circles,
      polylines: widget.polylines,
      interactive: widget.interactive,
      lite: widget.lite,
      showMyLocation: myLocation,
      dark: Theme.of(context).brightness == Brightness.dark,
      padding: widget.padding,
      onCreated: _onCreated,
      onCameraMove: (cam) {
        _camera = cam;
        widget.onCameraMove?.call(cam);
      },
      onCameraIdle: widget.onCameraIdle,
      onTap: widget.onTap,
    );

    Widget map = ref.watch(sbMapViewBuilderProvider)(context, spec);
    if (widget.onUserGesture != null) {
      map = Listener(onPointerDown: (_) => widget.onUserGesture!(), child: map);
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? l.mapLabel,
      child: Stack(children: [
        Positioned.fill(child: map),
        if (!_ready)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: sb.surfaceSunken,
                child: const Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
              ),
            ),
          ),
        if (!online)
          PositionedDirectional(
            top: SbSpace.s2,
            start: SbSpace.s2,
            end: SbSpace.s2,
            child: SbOfflineNote(message: l.mapOffline, onSurface: true),
          ),
        if (widget.interactive && (widget.onRecenter != null || widget.showZoomButtons))
          PositionedDirectional(
            end: SbSpace.s3,
            bottom: widget.padding.bottom + SbSpace.s3 + 28,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.showZoomButtons) ...[
                _MapButton(tooltip: l.mapZoomIn, onPressed: () => _zoomBy(1), icon: Icons.add_rounded),
                const SizedBox(height: SbSpace.s2),
                _MapButton(tooltip: l.mapZoomOut, onPressed: () => _zoomBy(-1), icon: Icons.remove_rounded),
              ],
              if (widget.onRecenter != null) ...[
                if (widget.showZoomButtons) const SizedBox(height: SbSpace.s2),
                _MapButton(tooltip: l.mapRecenter, onPressed: widget.onRecenter!, icon: Icons.my_location_rounded),
              ],
            ]),
          ),
      ]),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.tooltip, required this.onPressed, required this.icon});
  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Material(
      color: sb.surfaceRaised,
      shape: CircleBorder(side: BorderSide(color: sb.border)),
      elevation: 3,
      child: IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon, color: sb.primary)),
    );
  }
}

// ── Google view ─────────────────────────────────────────────────────────

gm.LatLng _ll(GeoCoord p) => gm.LatLng(p.latitude, p.longitude);
GeoCoord _gc(gm.LatLng p) => GeoCoord(p.latitude, p.longitude);

double _hue(SbMarkerKind kind) => switch (kind) {
      SbMarkerKind.destination => gm.BitmapDescriptor.hueRed,
      SbMarkerKind.person => gm.BitmapDescriptor.hueAzure,
      SbMarkerKind.selectedPerson => gm.BitmapDescriptor.hueOrange,
      SbMarkerKind.place => gm.BitmapDescriptor.hueGreen,
    };

class _GoogleController implements SbMapController {
  _GoogleController(this._c);
  final gm.GoogleMapController _c;
  bool disposed = false;

  Future<void> _run(gm.CameraUpdate u, bool animate) async {
    if (disposed) return;
    try {
      animate ? await _c.animateCamera(u) : await _c.moveCamera(u);
    } catch (_) {
      // The map went away mid-animation; nothing to move any more.
    }
  }

  @override
  Future<void> moveTo(GeoCoord point, {double? zoom, bool animate = true}) =>
      _run(zoom == null ? gm.CameraUpdate.newLatLng(_ll(point)) : gm.CameraUpdate.newLatLngZoom(_ll(point), zoom), animate);

  @override
  Future<void> fit(List<GeoCoord> points, {double padding = 56, double maxZoom = 16}) async {
    final valid = points.where((p) => p.isValid).toList();
    if (valid.isEmpty || disposed) return;
    if (valid.length == 1) return moveTo(valid.first, zoom: maxZoom);
    var s = valid.first.latitude, n = s, w = valid.first.longitude, e = w;
    for (final p in valid) {
      if (p.latitude < s) s = p.latitude;
      if (p.latitude > n) n = p.latitude;
      if (p.longitude < w) w = p.longitude;
      if (p.longitude > e) e = p.longitude;
    }
    if (n - s < 1e-6 && e - w < 1e-6) return moveTo(valid.first, zoom: maxZoom);
    final bounds = gm.LatLngBounds(southwest: gm.LatLng(s, w), northeast: gm.LatLng(n, e));
    await _run(gm.CameraUpdate.newLatLngBounds(bounds, padding), true);
    try {
      if (!disposed && await _c.getZoomLevel() > maxZoom) await _run(gm.CameraUpdate.zoomTo(maxZoom), true);
    } catch (_) {}
  }
}

class _GoogleMapView extends StatefulWidget {
  const _GoogleMapView({required this.spec});
  final SbMapViewSpec spec;

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  _GoogleController? _controller;

  @override
  void dispose() {
    _controller?.disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    final sb = context.sb;
    final markers = <gm.Marker>{
      for (final m in s.markers)
        if (m.position.isValid)
          gm.Marker(
            markerId: gm.MarkerId(m.id),
            position: _ll(m.position),
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(_hue(m.kind)),
            alpha: m.stale ? 0.5 : 1,
            zIndexInt: m.kind == SbMarkerKind.selectedPerson ? 2 : (m.kind == SbMarkerKind.destination ? 1 : 0),
            infoWindow: m.title == null ? gm.InfoWindow.noText : gm.InfoWindow(title: m.title),
            onTap: m.onTap,
          ),
    };
    final circles = <gm.Circle>{
      for (final c in s.circles)
        if (c.center.isValid && c.radiusMetres > 0)
          gm.Circle(
            circleId: gm.CircleId(c.id),
            center: _ll(c.center),
            radius: c.radiusMetres,
            fillColor: sb.primary.withValues(alpha: 0.10),
            strokeColor: sb.primary.withValues(alpha: 0.45),
            strokeWidth: 2,
          ),
    };
    final polylines = <gm.Polyline>{
      for (final p in s.polylines)
        if (p.points.length >= 2)
          gm.Polyline(
            polylineId: gm.PolylineId(p.id),
            points: [for (final q in p.points) _ll(q)],
            color: sb.primary,
            width: 6,
            jointType: gm.JointType.round,
            startCap: gm.Cap.roundCap,
            endCap: gm.Cap.roundCap,
          ),
    };
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(target: _ll(s.initialCenter), zoom: s.initialZoom),
      onMapCreated: (c) {
        final ctrl = _GoogleController(c);
        _controller = ctrl;
        s.onCreated(ctrl);
      },
      style: s.dark ? _darkStyle : null,
      markers: markers,
      circles: circles,
      polylines: polylines,
      liteModeEnabled: s.lite && defaultTargetPlatform == TargetPlatform.android && !kIsWeb,
      myLocationEnabled: s.showMyLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: s.interactive,
      rotateGesturesEnabled: s.interactive,
      scrollGesturesEnabled: s.interactive,
      zoomGesturesEnabled: s.interactive,
      tiltGesturesEnabled: false,
      buildingsEnabled: false,
      padding: s.padding,
      webGestureHandling: s.interactive ? gm.WebGestureHandling.greedy : gm.WebGestureHandling.none,
      // A full-screen map takes every drag; previews leave drags to the page.
      gestureRecognizers: s.interactive
          ? <Factory<OneSequenceGestureRecognizer>>{Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)}
          : const <Factory<OneSequenceGestureRecognizer>>{},
      onCameraMove: s.onCameraMove == null ? null : (p) => s.onCameraMove!((center: _gc(p.target), zoom: p.zoom)),
      onCameraIdle: s.onCameraIdle,
      onTap: s.onTap == null ? null : (p) => s.onTap!(_gc(p)),
    );
  }
}

/// Google's standard "night" style, so dark mode doesn't flash a white map.
const _darkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]
''';
