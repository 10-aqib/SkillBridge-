import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/location/device_location_tracker.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/navigation_engine.dart';
import 'package:skill_bridge/features/navigation/domain/off_route_detector.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/screen_awake.dart';

/// One turn-by-turn session (Navigation phase 6): find the user, get road
/// routes, let them pick one, then follow their GPS along it to arrival.
///
/// initializing → locating → calculating → ready → navigating ⇄ paused
/// → arrived, or cancelled / error at any point. Leaving the route while
/// navigating (phase 7) goes navigating → rerouting → navigating on a new
/// route from the latest position.

enum NavStatus { initializing, locating, calculating, ready, navigating, rerouting, paused, arrived, cancelled, error }

enum NavError { noDestination, permissionDenied, permissionBlocked, serviceOff, noFix, noRoute, farFromRoad, offline, routing }

@immutable
class NavState {
  const NavState({
    this.status = NavStatus.initializing,
    this.error,
    this.destination,
    this.label,
    this.result,
    this.selected = 0,
    this.progress,
    this.fix,
    this.signalLost = false,
    this.precise = true,
    this.startedAt,
    this.arrivedAt,
    this.routeVersion = 0,
    this.rerouteCount = 0,
    this.rerouteProblem,
  });

  final NavStatus status;
  final NavError? error;
  final LatLng? destination;

  /// Name of the place (job title or address), or null.
  final String? label;
  final RouteResult? result;

  /// Index into [RouteResult.all] of the chosen route.
  final int selected;
  final NavProgress? progress;

  /// The latest usable device position (null while there is none).
  final GeoFix? fix;
  final bool signalLost;
  final bool precise;
  final DateTime? startedAt;
  final DateTime? arrivedAt;

  /// Bumped each time guidance switches to a new route (voice says so once).
  final int routeVersion;
  final int rerouteCount;

  /// Why the last attempt to find a new route failed (offline, no route,
  /// service trouble); guidance continues on the old route meanwhile.
  final NavError? rerouteProblem;

  NavRoute? get route => result == null ? null : result!.all[selected.clamp(0, result!.all.length - 1)];

  /// The routes not chosen (drawn muted).
  List<NavRoute> get otherRoutes => result == null ? const [] : [for (var i = 0; i < result!.all.length; i++) if (i != selected) result!.all[i]];

  bool get isGuiding => status == NavStatus.navigating || status == NavStatus.paused || status == NavStatus.rerouting;

  NavState copyWith({
    NavStatus? status,
    NavError? error,
    bool clearError = false,
    RouteResult? result,
    int? selected,
    NavProgress? progress,
    bool clearProgress = false,
    GeoFix? fix,
    bool clearFix = false,
    bool? signalLost,
    bool? precise,
    DateTime? startedAt,
    DateTime? arrivedAt,
    int? routeVersion,
    int? rerouteCount,
    NavError? rerouteProblem,
    bool clearRerouteProblem = false,
  }) =>
      NavState(
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
        destination: destination,
        label: label,
        result: result ?? this.result,
        selected: selected ?? this.selected,
        progress: clearProgress ? null : (progress ?? this.progress),
        fix: clearFix ? null : (fix ?? this.fix),
        signalLost: signalLost ?? this.signalLost,
        precise: precise ?? this.precise,
        startedAt: startedAt ?? this.startedAt,
        arrivedAt: arrivedAt ?? this.arrivedAt,
        routeVersion: routeVersion ?? this.routeVersion,
        rerouteCount: rerouteCount ?? this.rerouteCount,
        rerouteProblem: clearRerouteProblem ? null : (rerouteProblem ?? this.rerouteProblem),
      );
}

class NavigationController extends Notifier<NavState> {
  NavigationController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  NavigationEngine? _engine;
  Completer<GeoFix?>? _firstFix;
  int _gen = 0;

  final _detector = OffRouteDetector();
  double _bestAlong = 0;
  DateTime? _lastRerouteAt;
  bool _rerouting = false;

  /// This session's name on the shared GPS tracker (live sharing may use it
  /// at the same time).
  static const trackerOwner = 'navigation';

  /// Shortest time between two automatic reroute requests.
  static const rerouteCooldown = Duration(seconds: 15);

  /// The keep-awake handle while the screen is held on (kept so disposal can
  /// release it without reading providers, which Riverpod forbids there).
  ScreenAwake? _awake;

  @override
  NavState build() {
    // Listening keeps the device tracker alive for this session.
    ref.listen<DeviceLocationState>(deviceLocationProvider, _onLocation);
    ref.onDispose(() {
      _gen++;
      _releaseScreen();
    });
    return const NavState();
  }

  DeviceLocationTracker get _tracker => ref.read(deviceLocationProvider.notifier);

  /// Starts a session to [destination]. A missing or impossible destination
  /// is an error, never a guess.
  Future<void> prepare(LatLng? destination, {String? label}) async {
    final gen = ++_gen;
    _engine = null;
    state = NavState(status: NavStatus.initializing, destination: destination, label: label);
    if (destination == null || !isRoutablePoint(destination)) {
      state = state.copyWith(status: NavStatus.error, error: NavError.noDestination);
      return;
    }

    state = state.copyWith(status: NavStatus.locating);
    final status = await _tracker.request(trackerOwner, LocationProfile.navigation);
    if (gen != _gen) return;
    final blocked = switch (status) {
      DeviceLocationStatus.permissionDenied => NavError.permissionDenied,
      DeviceLocationStatus.permissionBlocked => NavError.permissionBlocked,
      DeviceLocationStatus.serviceOff => NavError.serviceOff,
      DeviceLocationStatus.unavailable || DeviceLocationStatus.error => NavError.noFix,
      _ => null,
    };
    if (blocked != null) {
      state = state.copyWith(status: NavStatus.error, error: blocked);
      return;
    }

    var fix = ref.read(deviceLocationProvider).currentFix;
    if (fix == null) {
      _firstFix = Completer<GeoFix?>();
      fix = await _firstFix!.future.timeout(LocationProfile.navigation.firstFixTimeout, onTimeout: () => null);
      _firstFix = null;
    }
    if (gen != _gen) return;
    if (fix == null) {
      state = state.copyWith(status: NavStatus.error, error: NavError.noFix);
      return;
    }
    state = state.copyWith(fix: fix);
    await _calculate(gen, fix.point, destination);
  }

  Future<void> _calculate(int gen, LatLng from, LatLng to) async {
    state = state.copyWith(status: NavStatus.calculating, clearError: true);
    try {
      final result = await ref.read(routingServiceProvider).getRoute(from, to, alternatives: true);
      if (gen != _gen) return;
      state = state.copyWith(status: NavStatus.ready, result: result, selected: 0, clearProgress: true);
    } on RoutingException catch (e) {
      if (gen != _gen) return;
      final online = ref.read(connectivityStatusProvider).value ?? true;
      final error = switch (e.failure) {
        RoutingFailure.noRoute => NavError.noRoute,
        RoutingFailure.tooFarFromRoad => NavError.farFromRoad,
        RoutingFailure.network || RoutingFailure.timeout when !online => NavError.offline,
        _ => NavError.routing,
      };
      state = state.copyWith(status: NavStatus.error, error: error);
    }
  }

  /// Chooses route [index] (0 = the engine's recommendation) before starting.
  void selectRoute(int index) {
    final all = state.result?.all;
    if (state.status != NavStatus.ready || all == null || index < 0 || index >= all.length) return;
    state = state.copyWith(selected: index);
  }

  /// Begins guidance on the chosen route.
  Future<void> start() async {
    final route = state.route;
    if (state.status != NavStatus.ready || route == null) return;
    _engine = NavigationEngine(route);
    _detector.reset();
    _bestAlong = 0;
    state = state.copyWith(status: NavStatus.navigating, startedAt: _clock());
    _keepScreen();
    final fix = ref.read(deviceLocationProvider).currentFix;
    if (fix != null) _advance(fix);
  }

  /// Ends the session (the person tapped End or left the screen).
  void end() {
    _gen++;
    _engine = null;
    _releaseScreen();
    _tracker.release(trackerOwner);
    state = state.copyWith(status: NavStatus.cancelled);
  }

  /// Tries again after an error (permission given, GPS on, back online).
  Future<void> retry() => prepare(state.destination, label: state.label);

  void _onLocation(DeviceLocationState? previous, DeviceLocationState next) {
    final current = next.currentFix;
    if (current != null) {
      final waiting = _firstFix;
      if (waiting != null && !waiting.isCompleted) waiting.complete(current);
    }
    if (state.status == NavStatus.cancelled || state.status == NavStatus.arrived) return;

    var s = state.copyWith(signalLost: next.signalLost, precise: next.precise, fix: current);
    // Background: guidance pauses; it resumes when the app is back.
    if (next.paused && s.status == NavStatus.navigating) {
      s = s.copyWith(status: NavStatus.paused);
    } else if (!next.paused && s.status == NavStatus.paused && next.isActive) {
      s = s.copyWith(status: NavStatus.navigating);
    }
    state = s;
    if (current != null && state.status == NavStatus.navigating) _advance(current);
  }

  void _advance(GeoFix fix) {
    final engine = _engine;
    if (engine == null) return;
    final now = _clock();
    final progress = engine.update(fix.point, now: now, accuracy: fix.accuracy);
    state = state.copyWith(progress: progress);
    if (!progress.arrived) {
      // Furthest progress counts only while on the route: positions far off
      // it can match a distant part of the route and would fake a later
      // "wrong way".
      if (progress.distanceFromRoute <= _detector.limitFor(fix.accuracy) && progress.snap.distanceAlong > _bestAlong) {
        _bestAlong = progress.snap.distanceAlong;
      }
      final adherence = _detector.update(
        distanceFromRoute: progress.distanceFromRoute,
        accuracy: fix.accuracy,
        at: now,
        progressDrop: _bestAlong - progress.snap.distanceAlong,
        signalLost: state.signalLost,
      );
      if (adherence == RouteAdherence.offRoute) {
        _reroute(fix);
      } else if (adherence == RouteAdherence.onRoute && state.rerouteProblem != null) {
        // Back on the old route: the failed reroute no longer matters.
        state = state.copyWith(clearRerouteProblem: true);
      }
    }
    if (progress.arrived) {
      _engine = null;
      _releaseScreen();
      // Nothing left to guide: stop using GPS.
      _tracker.release(trackerOwner);
      state = state.copyWith(status: NavStatus.arrived, arrivedAt: _clock());
    }
  }

  /// Asks for a new route now (the person tapped Try again).
  Future<void> rerouteNow() async {
    final fix = state.fix;
    if (fix != null && state.status == NavStatus.navigating) await _reroute(fix, manual: true);
  }

  /// A new route from [fix] to the destination. One request at a time, and
  /// automatic ones at most every [rerouteCooldown]. If it fails, guidance
  /// stays on the old route and the reason is shown.
  Future<void> _reroute(GeoFix fix, {bool manual = false}) async {
    final destination = state.destination;
    if (_rerouting || destination == null) return;
    final now = _clock();
    if (!manual && _lastRerouteAt != null && now.difference(_lastRerouteAt!) < rerouteCooldown) return;
    _rerouting = true;
    _lastRerouteAt = now;
    final gen = _gen;
    state = state.copyWith(status: NavStatus.rerouting);
    try {
      final result = await ref.read(routingServiceProvider).getRoute(fix.point, destination, alternatives: false);
      if (gen != _gen || state.status != NavStatus.rerouting) return;
      _engine = NavigationEngine(result.primary);
      _detector.reset();
      _bestAlong = 0;
      state = state.copyWith(
        status: NavStatus.navigating,
        result: result,
        selected: 0,
        routeVersion: state.routeVersion + 1,
        rerouteCount: state.rerouteCount + 1,
        clearRerouteProblem: true,
      );
      final latest = state.fix;
      if (latest != null) _advance(latest);
    } on RoutingException catch (e) {
      if (gen != _gen || state.status != NavStatus.rerouting) return;
      final online = ref.read(connectivityStatusProvider).value ?? true;
      final problem = switch (e.failure) {
        RoutingFailure.network || RoutingFailure.timeout when !online => NavError.offline,
        RoutingFailure.noRoute || RoutingFailure.tooFarFromRoad => NavError.noRoute,
        _ => NavError.routing,
      };
      state = state.copyWith(status: NavStatus.navigating, rerouteProblem: problem);
    } finally {
      _rerouting = false;
    }
  }

  void _keepScreen() {
    if (_awake != null) return;
    final awake = ref.read(screenAwakeProvider);
    _awake = awake;
    awake.keepOn();
  }

  void _releaseScreen() {
    final awake = _awake;
    if (awake == null) return;
    _awake = null;
    awake.allowOff();
  }
}

/// One session per navigation screen; ends when the screen closes.
final navigationControllerProvider =
    NotifierProvider.autoDispose<NavigationController, NavState>(NavigationController.new);
