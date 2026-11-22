import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/maps_config.dart';
import 'package:skill_bridge/core/map/sb_google_map.dart';

/// Stands in for the Google map in widget tests: records what screens ask
/// it to draw and where they move the camera. Tests drive camera moves and
/// gestures through [FakeMaps.moveCamera].
class FakeMaps {
  SbMapViewSpec? spec;
  final controller = FakeMapController();
  int builds = 0;

  List<SbMarker> get markers => spec?.markers ?? const [];
  SbMarker? marker(String id) => markers.where((m) => m.id == id).firstOrNull;

  /// Map is available, drawn by this fake.
  List<Override> get overrides => [
        mapsAvailableProvider.overrideWithValue(true),
        sbMapViewBuilderProvider.overrideWithValue((context, spec) => _FakeMapView(maps: this, spec: spec)),
      ];

  /// The person (or the camera) moved the map to [center] at [zoom].
  void moveCamera(GeoCoord center, double zoom) {
    spec!.onCameraMove?.call((center: center, zoom: zoom));
    spec!.onCameraIdle?.call();
  }
}

class FakeMapController implements SbMapController {
  final calls = <String>[];
  ({GeoCoord point, double? zoom})? lastMove;
  List<GeoCoord>? lastFit;

  @override
  Future<void> moveTo(GeoCoord point, {double? zoom, bool animate = true}) async {
    lastMove = (point: point, zoom: zoom);
    calls.add('move:${point.urlValue}:${zoom ?? '-'}');
  }

  @override
  Future<void> fit(List<GeoCoord> points, {double padding = 56, double maxZoom = 16}) async {
    lastFit = points;
    calls.add('fit:${points.length}');
  }
}

class _FakeMapView extends StatefulWidget {
  const _FakeMapView({required this.maps, required this.spec});
  final FakeMaps maps;
  final SbMapViewSpec spec;

  @override
  State<_FakeMapView> createState() => _FakeMapViewState();
}

class _FakeMapViewState extends State<_FakeMapView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.spec.onCreated(widget.maps.controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.maps
      ..spec = widget.spec
      ..builds += 1;
    return const SizedBox.expand(key: Key('fake-google-map'), child: ColoredBox(color: Color(0xFFDDE8DD)));
  }
}
