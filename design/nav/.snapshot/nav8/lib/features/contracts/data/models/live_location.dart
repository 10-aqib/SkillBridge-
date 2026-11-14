import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

/// A position is "live" only if it was updated this recently; older ones are
/// shown as last known and possibly out of date, never as live.
const liveFreshFor = Duration(minutes: 2);

/// The worker's shared position for one contract (contracts/{id}/live/location).
class LiveLocation {
  const LiveLocation({required this.lat, required this.lng, this.accuracy, this.updatedAt, this.startedAt});
  final double lat;
  final double lng;
  final double? accuracy;

  /// Server time of the last update (null while this device's write is pending).
  final DateTime? updatedAt;
  final DateTime? startedAt;

  static LiveLocation? fromMap(Map<String, dynamic>? d) {
    final p = d?['position'];
    if (p is! GeoPoint) return null;
    DateTime? ts(String k) => d![k] is Timestamp ? (d[k] as Timestamp).toDate() : null;
    return LiveLocation(
      lat: p.latitude,
      lng: p.longitude,
      accuracy: (d!['accuracy'] as num?)?.toDouble(),
      updatedAt: ts('updatedAt'),
      startedAt: ts('startedAt'),
    );
  }

  /// Live if updated within [liveFreshFor] of [now].
  bool isLive(DateTime now) => updatedAt == null || now.difference(updatedAt!) < liveFreshFor;
}

/// Readable only by the two parties of the contract (and staff).
final contractLiveLocationProvider = StreamProvider.autoDispose.family<LiveLocation?, String>((ref, contractId) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref
      .watch(firestoreProvider)
      .collection(FirestorePaths.contracts)
      .doc(contractId)
      .collection('live')
      .doc('location')
      .snapshots()
      .map((d) => d.exists ? LiveLocation.fromMap(d.data()) : null);
});
