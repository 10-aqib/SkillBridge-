import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/features/navigation/data/osrm_routing_service.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/screen_awake.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/voice_guidance.dart';

/// Parses a recorded OSRM answer from test/fixtures/osrm.
RouteResult recordedRoute(String name, {LatLng origin = const LatLng(31.59, 74.31), LatLng destination = const LatLng(31.58, 74.31)}) =>
    OsrmRoutingService.parseResponse(
      jsonDecode(File('test/fixtures/osrm/$name.json').readAsStringSync()),
      origin: origin,
      destination: destination,
      fetchedAt: DateTime.now(),
    );

/// Routing for tests: a recorded answer, or a chosen failure.
class FakeRouting extends RoutingService {
  FakeRouting({this.fixture = 'lahore_route', this.failure});
  String fixture;
  RoutingFailure? failure;
  final calls = <(LatLng, LatLng)>[];

  @override
  Future<RouteResult> getRoute(LatLng origin, LatLng destination, {bool alternatives = true}) async {
    calls.add((origin, destination));
    final f = failure;
    if (f != null) throw RoutingException(f);
    return recordedRoute(fixture, origin: origin, destination: destination);
  }
}

/// Records keep-screen-on calls.
class FakeScreenAwake implements ScreenAwake {
  final calls = <String>[];
  bool get on => calls.isNotEmpty && calls.last == 'on';

  @override
  Future<void> keepOn() async => calls.add('on');

  @override
  Future<void> allowOff() async => calls.add('off');
}

/// Text to speech for tests: records what would be said.
class FakeSpeaker implements Speaker {
  FakeSpeaker({Set<String>? voices}) : voices = voices ?? {'en-GB', 'en-US', 'en', 'ur-PK', 'ur'};
  final Set<String> voices;
  String? language;
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<bool> setLanguage(String languageTag) async {
    if (!voices.contains(languageTag)) return false;
    language = languageTag;
    return true;
  }

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;

  @override
  void dispose() {}
}
