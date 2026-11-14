import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

/// Live location for one contract (Phase 4B).
///
/// The hired worker explicitly starts sharing from the contract; positions go
/// to `contracts/{id}/live/location`, readable only by the two parties. The
/// rules accept positions only while the contract is active and the work is
/// not waiting for review, at server time; the contract function deletes the
/// document when work is submitted, completed or cancelled. Nothing is
/// written to the worker's profile (`users/{uid}.location` is their service
/// area and is left alone).

// The device's location (access, fixes, profiles) lives in
// core/location/device_location.dart; re-exported for existing imports.
export 'package:skill_bridge/core/location/device_location.dart' show GeoFix, LocationAccess, LocationProfile, LocationSource, GeolocatorLocationSource, locationSourceProvider;

/// Positions older than this are never written: the server stamps each
/// write with its own time, so an old cached fix would look live.
const liveMaxFixAge = Duration(seconds: 30);

/// Where positions are written: contracts/{id}/live/location.
abstract class LiveLocationSink {
  Future<void> start(String contractId, String workerId, GeoFix fix);
  Future<void> update(String contractId, GeoFix fix);
  Future<void> remove(String contractId);
}

class FirestoreLiveLocationSink implements LiveLocationSink {
  FirestoreLiveLocationSink(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String contractId) =>
      _firestore.collection(FirestorePaths.contracts).doc(contractId).collection('live').doc('location');

  // Times are the server's (the rules require it), never the device's.
  @override
  Future<void> start(String contractId, String workerId, GeoFix fix) => _doc(contractId).set({
        'workerId': workerId,
        'position': GeoPoint(fix.lat, fix.lng),
        'accuracy': fix.accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
        'startedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> update(String contractId, GeoFix fix) => _doc(contractId).update({
        'position': GeoPoint(fix.lat, fix.lng),
        'accuracy': fix.accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> remove(String contractId) => _doc(contractId).delete();
}

final liveLocationSinkProvider = Provider<LiveLocationSink>((ref) => FirestoreLiveLocationSink(ref.watch(firestoreProvider)));

enum LiveShareStatus {
  idle,
  starting,
  sharing,
  permissionDenied,
  permissionBlocked,
  serviceOff,
  unavailable,

  /// The server no longer accepts positions (work submitted, contract
  /// completed or cancelled): sharing stopped by itself.
  ended,
  error,
}

class LiveShareState {
  const LiveShareState({this.contractId, this.status = LiveShareStatus.idle, this.lastSentAt});
  final String? contractId;
  final LiveShareStatus status;
  final DateTime? lastSentAt;

  bool sharingFor(String id) => contractId == id && (status == LiveShareStatus.sharing || status == LiveShareStatus.starting);
}

/// Fewest seconds between position writes, and the longest gap: a fresh fix
/// is sent at least this often so the client can tell sharing is live.
const liveMinGap = Duration(seconds: 15);
const liveHeartbeat = Duration(seconds: 60);

class LiveLocationController extends Notifier<LiveShareState> {
  /// [source] replaces the device location in tests.
  LiveLocationController([this._sourceOverride, this._minGap = liveMinGap]);
  final LocationSource? _sourceOverride;
  final Duration _minGap;

  StreamSubscription<GeoFix>? _sub;
  Timer? _heartbeat;
  DateTime? _lastWrite;

  @override
  LiveShareState build() {
    // Signing out or switching accounts stops sharing.
    ref.listen(currentUserProvider.select((u) => u?.uid), (prev, next) {
      if (prev != next) _stopLocal(LiveShareStatus.idle);
    });
    ref.onDispose(_cancelStreams);
    return const LiveShareState();
  }

  LocationSource get source => _sourceOverride ?? ref.read(locationSourceProvider);

  LiveLocationSink get _sink => ref.read(liveLocationSinkProvider);

  bool get _online => ref.read(connectivityStatusProvider).value ?? true;

  /// Asks for location access and starts sharing for [contractId] (one
  /// contract at a time). Call only after the worker agreed to share.
  Future<LiveShareStatus> start(String contractId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return LiveShareStatus.error;
    if (state.sharingFor(contractId)) return state.status;
    if (state.contractId != null && state.contractId != contractId) await stop();
    state = LiveShareState(contractId: contractId, status: LiveShareStatus.starting);

    final access = await source.ensureAccess();
    final blocked = switch (access) {
      LocationAccess.granted => null,
      LocationAccess.denied => LiveShareStatus.permissionDenied,
      LocationAccess.deniedForever => LiveShareStatus.permissionBlocked,
      LocationAccess.serviceOff => LiveShareStatus.serviceOff,
      LocationAccess.unavailable => LiveShareStatus.unavailable,
    };
    if (blocked != null) {
      state = LiveShareState(contractId: contractId, status: blocked);
      return blocked;
    }

    try {
      final fix = await source.current(profile: LocationProfile.sharing);
      if (!_usable(fix)) throw StateError('no usable fix');
      await _sink.start(contractId, uid, fix);
      _lastWrite = DateTime.now();
    } on FirebaseException catch (e) {
      final status = e.code == 'permission-denied' ? LiveShareStatus.ended : LiveShareStatus.error;
      state = LiveShareState(contractId: contractId, status: status);
      return status;
    } catch (e) {
      Logger.w('[LiveLocation] first fix failed: $e');
      state = LiveShareState(contractId: contractId, status: LiveShareStatus.error);
      return LiveShareStatus.error;
    }

    state = LiveShareState(contractId: contractId, status: LiveShareStatus.sharing, lastSentAt: _lastWrite);
    _sub = source.watch(LocationProfile.sharing).listen((fix) => _send(contractId, fix), onError: (Object e) => Logger.w('[LiveLocation] stream error: $e'));
    _heartbeat = Timer.periodic(liveHeartbeat, (_) async {
      if (_lastWrite != null && DateTime.now().difference(_lastWrite!) < liveHeartbeat - const Duration(seconds: 5)) return;
      try {
        await _send(contractId, await source.current(profile: LocationProfile.sharing), force: true);
      } catch (_) {}
    });
    return LiveShareStatus.sharing;
  }

  Future<void> _send(String contractId, GeoFix fix, {bool force = false}) async {
    if (state.contractId != contractId || state.status != LiveShareStatus.sharing) return;
    if (!_usable(fix)) return;
    final now = DateTime.now();
    if (!force && _lastWrite != null && now.difference(_lastWrite!) < _minGap) return;
    // Offline writes would be queued and stamped with the reconnect time,
    // making an old position look live; skip them and send a fresh fix later.
    if (!_online) return;
    _lastWrite = now;
    try {
      await _sink.update(contractId, fix);
      if (state.contractId == contractId && state.status == LiveShareStatus.sharing) {
        state = LiveShareState(contractId: contractId, status: LiveShareStatus.sharing, lastSentAt: now);
      }
    } on FirebaseException catch (e) {
      // Refused (work submitted, contract closed) or deleted by the server.
      if (e.code == 'permission-denied' || e.code == 'not-found') _stopLocal(LiveShareStatus.ended);
    }
  }

  /// Valid coordinates, taken recently (never an old cached position).
  bool _usable(GeoFix fix) => fix.isValid && fix.ageAt(DateTime.now()) <= liveMaxFixAge;

  /// Stops sharing and removes the position.
  Future<void> stop() async {
    final id = state.contractId;
    _stopLocal(LiveShareStatus.idle);
    if (id == null) return;
    try {
      await _sink.remove(id);
    } catch (e) {
      Logger.w('[LiveLocation] delete failed: $e');
    }
  }

  /// The contract moved past the point where sharing makes sense; the
  /// server already removed the position.
  void contractClosed(String contractId) {
    if (state.contractId == contractId && state.sharingFor(contractId)) _stopLocal(LiveShareStatus.ended);
  }

  void _cancelStreams() {
    _sub?.cancel();
    _sub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastWrite = null;
  }

  void _stopLocal(LiveShareStatus status) {
    _cancelStreams();
    state = LiveShareState(contractId: status == LiveShareStatus.idle ? null : state.contractId, status: status);
  }
}

final liveLocationControllerProvider = NotifierProvider<LiveLocationController, LiveShareState>(LiveLocationController.new);
