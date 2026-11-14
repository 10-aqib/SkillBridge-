import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show LocationServiceDisabledException, PermissionDeniedException;
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Continuous device location for screens that show or follow the user
/// (maps now, turn-by-turn navigation later). Navigation phase 4.
///
/// - Asks for permission once, and reports every reason location can't be
///   used (denied, blocked, GPS off, unavailable).
/// - Follows GPS being switched off and on while in use.
/// - Drops fixes that are invalid, older than the last one, cached from
///   long ago, or physically impossible jumps.
/// - Marks the signal lost when no fix arrives in time, so an old position
///   is never shown as the current one.
/// - Foreground only: stops when the app is hidden and resumes when shown.
/// - Stops when no screen listens (auto-dispose).
/// - Shared (Navigation phase 8): features [request] it by name
///   ("navigation", "sharing") and [release] it; one GPS stream runs with
///   the most demanding profile asked for, and stops with the last release.
/// - Standing still is not a lost signal: phones send no updates while not
///   moving, so before calling the signal lost the tracker asks for one
///   fresh fix.

enum DeviceLocationStatus { idle, starting, active, permissionDenied, permissionBlocked, serviceOff, unavailable, error }

/// Why a fix was dropped (for tests and logs).
enum FixRejection { invalid, outOfOrder, tooOld, impossibleJump }

@immutable
class DeviceLocationState {
  const DeviceLocationState({
    this.status = DeviceLocationStatus.idle,
    this.profile,
    this.fix,
    this.receivedAt,
    this.precise = true,
    this.signalLost = false,
    this.paused = false,
  });

  final DeviceLocationStatus status;
  final LocationProfile? profile;

  /// The last accepted fix. It may be old: check [signalLost].
  final GeoFix? fix;

  /// Device time the last accepted fix arrived.
  final DateTime? receivedAt;

  /// False when only approximate location is allowed.
  final bool precise;

  /// Tracking, but no fix for longer than the profile allows (or none yet).
  final bool signalLost;

  /// The app is in the background; tracking resumes when it returns.
  final bool paused;

  bool get isActive => status == DeviceLocationStatus.active;

  /// The fix to show as "you are here": none while the signal is lost.
  GeoFix? get currentFix => isActive && !signalLost && !paused ? fix : null;

  DeviceLocationState copyWith({
    DeviceLocationStatus? status,
    LocationProfile? profile,
    GeoFix? fix,
    DateTime? receivedAt,
    bool? precise,
    bool? signalLost,
    bool? paused,
  }) =>
      DeviceLocationState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        fix: fix ?? this.fix,
        receivedAt: receivedAt ?? this.receivedAt,
        precise: precise ?? this.precise,
        signalLost: signalLost ?? this.signalLost,
        paused: paused ?? this.paused,
      );

  @override
  String toString() => 'DeviceLocationState(${status.name}, ${profile?.name}, $fix, lost=$signalLost, paused=$paused, precise=$precise)';
}

/// Fastest believable movement between two fixes (≈ 250 km/h); faster
/// means a GPS glitch.
const maxBelievableSpeed = 70.0;

/// Decides whether [fix] may replace [previous]. Pure, for tests.
FixRejection? checkFix(GeoFix fix, {GeoFix? previous, required DateTime now, required LocationProfile profile}) {
  if (!fix.isValid) return FixRejection.invalid;
  // A cached fix from long ago must not look current. Device clocks can be
  // a little off, so allow the profile's stale window.
  if (fix.hasTimestamp && fix.ageAt(now) > profile.staleAfter * 2) return FixRejection.tooOld;
  if (previous == null) return null;
  if (fix.hasTimestamp && previous.hasTimestamp) {
    final dt = fix.timestamp.difference(previous.timestamp);
    if (dt.isNegative) return FixRejection.outOfOrder;
    final seconds = dt.inMilliseconds / 1000;
    if (seconds > 0) {
      // Allow for both fixes' error circles before calling it a jump.
      final moved = fix.metresTo(previous) - fix.accuracy - previous.accuracy;
      if (moved > 0 && moved / seconds > maxBelievableSpeed) return FixRejection.impossibleJump;
    }
  }
  return null;
}

class DeviceLocationTracker extends Notifier<DeviceLocationState> {
  DeviceLocationTracker({DateTime Function()? clock, bool followAppLifecycle = true})
      : _clock = clock ?? DateTime.now,
        _followLifecycle = followAppLifecycle;

  final DateTime Function() _clock;
  final bool _followLifecycle;

  StreamSubscription<GeoFix>? _positions;
  StreamSubscription<bool>? _service;
  Timer? _staleTimer;
  Timer? _restartTimer;
  AppLifecycleListener? _lifecycle;

  /// The profile in use: the most demanding one asked for (kept across
  /// pauses and GPS off/on).
  LocationProfile? _wanted;

  /// Who asked for tracking, and with which profile.
  final _owners = <String, LocationProfile>{};

  /// The owner behind plain [start]/[stop].
  static const mainOwner = 'main';

  /// How long a fresh-fix check may take before the signal counts as lost.
  static const probeTimeout = Duration(seconds: 8);
  int _generation = 0;
  int rejected = 0;

  @override
  DeviceLocationState build() {
    if (_followLifecycle) {
      _lifecycle = AppLifecycleListener(onHide: appHidden, onShow: appShown);
    }
    ref.onDispose(() {
      _wanted = null;
      _cancelStreams();
      _service?.cancel();
      _service = null;
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    return const DeviceLocationState();
  }

  LocationSource get source => ref.read(locationSourceProvider);

  /// Starts (or switches to) tracking with [profile] for the main owner.
  /// Asks for permission if needed. Returns the resulting status.
  Future<DeviceLocationStatus> start(LocationProfile profile) => request(mainOwner, profile);

  /// [owner] needs tracking with at least [profile]. The stream runs with
  /// the most demanding profile among all owners.
  Future<DeviceLocationStatus> request(String owner, LocationProfile profile) {
    _owners[owner] = profile;
    return _run(_strongest());
  }

  /// [owner] no longer needs tracking. The last release stops GPS; otherwise
  /// tracking continues with what the remaining owners need.
  void release(String owner) {
    if (_owners.remove(owner) == null) return;
    if (_owners.isEmpty) {
      _stopAll();
    } else {
      _run(_strongest());
    }
  }

  /// Display < sharing < navigation (accuracy and update rate).
  LocationProfile _strongest() => _owners.values.reduce((a, b) => a.index >= b.index ? a : b);

  Future<DeviceLocationStatus> _run(LocationProfile profile) async {
    if (_wanted == profile && (state.isActive || state.status == DeviceLocationStatus.starting)) return state.status;
    _wanted = profile;
    final gen = ++_generation;
    _cancelStreams();
    state = state.copyWith(status: DeviceLocationStatus.starting, profile: profile, paused: false);

    final access = await source.ensureAccess();
    if (gen != _generation) return state.status;
    final blocked = switch (access) {
      LocationAccess.granted => null,
      LocationAccess.denied => DeviceLocationStatus.permissionDenied,
      LocationAccess.deniedForever => DeviceLocationStatus.permissionBlocked,
      LocationAccess.serviceOff => DeviceLocationStatus.serviceOff,
      LocationAccess.unavailable => DeviceLocationStatus.unavailable,
    };
    _watchService();
    if (blocked != null) {
      state = state.copyWith(status: blocked, signalLost: true);
      return blocked;
    }

    final precise = await source.isPrecise();
    if (gen != _generation) return state.status;
    state = state.copyWith(status: DeviceLocationStatus.active, precise: precise, signalLost: state.fix == null || state.signalLost);
    _armStaleTimer(state.fix == null ? profile.firstFixTimeout : profile.staleAfter);
    _positions = source.watch(profile).listen(
      _onFix,
      onError: _onStreamError,
      onDone: () => _scheduleRestart(gen),
      cancelOnError: false,
    );
    return DeviceLocationStatus.active;
  }

  /// Stops tracking for everyone. The last fix is kept but marked lost.
  /// Features sharing the tracker use [release] instead.
  void stop() {
    _owners.clear();
    _stopAll();
  }

  void _stopAll() {
    _wanted = null;
    _generation++;
    _cancelStreams();
    _service?.cancel();
    _service = null;
    state = state.copyWith(status: DeviceLocationStatus.idle, signalLost: true);
  }

  /// Asks again (after the person fixed permission or GPS).
  Future<DeviceLocationStatus> retry() {
    if (_owners.isEmpty) return start(state.profile ?? LocationProfile.display);
    final wanted = _strongest();
    _wanted = null; // force a fresh start with the same profile
    return _run(wanted);
  }

  void _onFix(GeoFix fix) {
    final profile = _wanted;
    if (profile == null) return;
    final now = _clock();
    final rejection = checkFix(fix, previous: state.fix, now: now, profile: profile);
    if (rejection != null) {
      rejected++;
      // Once the signal is lost the last fix is no reference any more (the
      // device clock may have been corrected, or the person moved far):
      // accept the next valid, recent fix instead of rejecting forever.
      final recover = state.signalLost && (rejection == FixRejection.outOfOrder || rejection == FixRejection.impossibleJump);
      if (!recover) {
        Logger.d('[Location] dropped fix (${rejection.name}): $fix');
        return;
      }
    }
    state = state.copyWith(status: DeviceLocationStatus.active, fix: fix, receivedAt: now, signalLost: false);
    _armStaleTimer(profile.staleAfter);
  }

  void _onStreamError(Object error) {
    Logger.w('[Location] stream error: $error');
    if (error is LocationServiceDisabledException) {
      _cancelStreams();
      state = state.copyWith(status: DeviceLocationStatus.serviceOff, signalLost: true);
    } else if (error is PermissionDeniedException) {
      _cancelStreams();
      state = state.copyWith(status: DeviceLocationStatus.permissionDenied, signalLost: true);
    } else if (error is TimeoutException) {
      state = state.copyWith(signalLost: true);
    } else {
      state = state.copyWith(status: DeviceLocationStatus.error, signalLost: true);
    }
  }

  /// The platform ended the stream: try again once after a short wait.
  void _scheduleRestart(int gen) {
    if (gen != _generation || _wanted == null || state.paused) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 3), () {
      final wanted = _wanted;
      if (gen == _generation && wanted != null && !state.paused) {
        _generation++; // let _run() start again even though the profile is the same
        state = state.copyWith(status: DeviceLocationStatus.idle);
        _run(wanted);
      }
    });
  }

  void _watchService() {
    _service ??= source.serviceEnabledChanges().listen((enabled) {
      final wanted = _wanted;
      if (wanted == null) return;
      if (!enabled) {
        _generation++;
        _cancelStreams();
        state = state.copyWith(status: DeviceLocationStatus.serviceOff, signalLost: true);
      } else if (state.status == DeviceLocationStatus.serviceOff && !state.paused) {
        state = state.copyWith(status: DeviceLocationStatus.idle);
        _run(wanted);
      }
    });
  }

  void _armStaleTimer(Duration after) {
    _staleTimer?.cancel();
    final gen = _generation;
    _staleTimer = Timer(after, () {
      if (_wanted != null && state.isActive && gen == _generation) _probe(gen);
    });
  }

  /// No fix for a while: ask the device for one. Standing still (no updates
  /// because nothing moved) gets a fresh fix and carries on; a real loss of
  /// signal marks it lost, and asks again later.
  Future<void> _probe(int gen) async {
    final profile = _wanted;
    if (profile == null) return;
    try {
      final fix = await source.current(timeLimit: probeTimeout, profile: profile);
      if (gen != _generation || _wanted == null) return;
      if (checkFix(fix, previous: state.fix, now: _clock(), profile: profile) == null || state.signalLost) {
        if (fix.isValid && fix.ageAt(_clock()) <= profile.staleAfter) {
          _onFix(fix);
          return;
        }
      }
    } catch (_) {
      // Timed out or failed: treated as no signal below.
    }
    if (gen != _generation || _wanted == null || !state.isActive) return;
    if (!state.signalLost) state = state.copyWith(signalLost: true);
    _armStaleTimer(profile.staleAfter);
  }

  /// App went to the background: stop using GPS (foreground only).
  @visibleForTesting
  void appHidden() {
    if (_wanted == null || state.paused) return;
    _generation++;
    _cancelStreams();
    state = state.copyWith(paused: true, signalLost: true);
  }

  /// App came back: resume tracking with the same profile.
  @visibleForTesting
  void appShown() {
    final wanted = _wanted;
    if (wanted == null || !state.paused) return;
    state = state.copyWith(paused: false, status: DeviceLocationStatus.idle);
    _run(wanted);
  }

  void _cancelStreams() {
    _positions?.cancel();
    _positions = null;
    _staleTimer?.cancel();
    _staleTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
  }
}

/// Screens `ref.watch` this and call `start(profile)`; tracking stops when
/// the last screen goes away.
final deviceLocationProvider =
    NotifierProvider.autoDispose<DeviceLocationTracker, DeviceLocationState>(DeviceLocationTracker.new);
