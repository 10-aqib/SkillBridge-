import 'dart:async';

import 'package:skill_bridge/core/location/device_location.dart';

/// Device location for tests: each watch() gets its own stream, so tests can
/// see when the tracker listens and stops listening.
class FakeTrackSource implements LocationSource {
  LocationAccess access = LocationAccess.granted;
  bool precise = true;
  final service = StreamController<bool>.broadcast();
  final watches = <LocationProfile>[];
  StreamController<GeoFix>? live;
  int cancels = 0;

  bool get listening => live != null && live!.hasListener;
  void emit(GeoFix f) => live!.add(f);

  @override
  Future<LocationAccess> checkAccess() async => access;
  @override
  Future<LocationAccess> ensureAccess() async => access;
  @override
  Future<bool> isPrecise() async => precise;
  /// What a one-shot fix request returns; null: it times out (no signal).
  GeoFix? oneShot;
  int oneShotRequests = 0;

  @override
  Future<GeoFix> current({Duration timeLimit = const Duration(seconds: 20), LocationProfile profile = LocationProfile.sharing}) async {
    oneShotRequests++;
    final f = oneShot;
    if (f == null) throw TimeoutException('no fix');
    return f;
  }
  @override
  Stream<GeoFix> watch([LocationProfile profile = LocationProfile.sharing]) {
    watches.add(profile);
    final c = StreamController<GeoFix>(onCancel: () => cancels++);
    live = c;
    return c.stream;
  }

  @override
  Stream<bool> serviceEnabledChanges() => service.stream;
  @override
  bool get canOpenSettings => true;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

