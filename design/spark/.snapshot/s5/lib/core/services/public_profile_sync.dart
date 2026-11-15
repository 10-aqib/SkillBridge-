import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/core/utils/geohash_util.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';

/// Public profiles on the free Firebase plan (Phase S2).
///
/// `users/{uid}` is private (owner and staff only). Other people read
/// `publicProfiles/{uid}`, an allowlisted view. With Cloud Functions that view
/// was written by a trusted trigger; without them each person's app writes its
/// own, and the Firestore rules check it: allowlisted fields only, reputation
/// and verification values equal to the private account, ~1 km locations.
///
/// This mirrors `publicProfileOf` in functions/src/profiles.ts.

/// Account fields that are safe to show to any signed-in user.
const publicUserFields = <String>[
  'displayName', 'photoUrl', 'role', 'isActive', 'city',
  'isEmailVerified', 'isPhoneVerified', 'isCnicVerified',
  'createdAt', 'rating', 'totalReviews',
];

/// Worker profile fields shown on public profiles and in discovery.
const publicWorkerFields = <String>[
  'headline', 'bio', 'categoryId', 'categoryName', 'skills', 'experience',
  'hourlyRate', 'dailyRate', 'availability', 'isVerified', 'city',
  'serviceRadius', 'totalJobsCompleted', 'averageRating', 'totalReviews',
  'coverImage', 'languages', 'responseTime', 'portfolioImages', 'beforeAfterImages',
];

/// About 1.1 km: enough for "near you" and distance, not a doorstep.
double coarse(double value) => (value * 100).round() / 100;

GeoPoint? _asPoint(Object? v) => v is GeoPoint ? v : null;

bool _locationHidden(Map<String, dynamic> user) {
  final v = user['locationVisibility'];
  return v is String && v != 'public';
}

/// The public view of a private account. Everything not allowlisted is left
/// out: phone, email, CNIC, push token, addresses, exact location, earnings,
/// verification documents and status, onboarding flags.
///
/// [emailVerified] and [phoneVerified] come from the signed-in account: the
/// rules only accept "verified" badges the sign-in token confirms.
Map<String, Object?> publicProfileOf(
  String uid,
  Map<String, dynamic> user, {
  required bool emailVerified,
  required bool phoneVerified,
}) {
  final out = <String, Object?>{'uid': uid};
  for (final f in publicUserFields) {
    if (user.containsKey(f) && user[f] != null) out[f] = user[f];
  }
  if (out['isEmailVerified'] == true && !emailVerified) out['isEmailVerified'] = false;
  if (out['isPhoneVerified'] == true && !phoneVerified) out['isPhoneVerified'] = false;

  final isWorker = user['role'] == 'worker';
  final exact = isWorker && !_locationHidden(user) ? _asPoint(user['location']) : null;
  if (exact != null) {
    final lat = coarse(exact.latitude), lng = coarse(exact.longitude);
    out['location'] = GeoPoint(lat, lng);
    out['geohash'] = GeohashUtil.encode(lat, lng);
    out['locationAccuracy'] = 'approximate';
  }

  final wp = user['workerProfile'];
  if (isWorker && wp is Map) {
    final src = Map<String, dynamic>.from(wp);
    final pub = <String, Object?>{};
    for (final f in publicWorkerFields) {
      if (src.containsKey(f) && src[f] != null) pub[f] = src[f];
    }
    final certs = src['certifications'];
    if (certs is List) {
      // Name, issuer and year only; certificate images can be documents.
      pub['certifications'] = [
        for (final c in certs.whereType<Map>().take(20))
          {
            for (final f in const ['name', 'issuedBy', 'year'])
              if (c[f] != null) f: c[f],
          },
      ];
    }
    final area = _locationHidden(user) ? null : (_asPoint(src['location']) ?? exact);
    if (area != null) {
      final lat = coarse(area.latitude), lng = coarse(area.longitude);
      pub['location'] = GeoPoint(lat, lng);
      pub['geohash'] = GeohashUtil.encode(lat, lng);
      pub['locationAccuracy'] = 'approximate';
    }
    out['workerProfile'] = pub;
  }
  return out;
}

/// Deep, order-independent equality for Firestore values.
bool sameValue(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !sameValue(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!sameValue(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Writes public profiles. Separate from Firestore so it can be tested.
abstract class PublicProfileStore {
  Future<Map<String, dynamic>?> read(String uid);
  Future<void> write(String uid, Map<String, Object?> data);
}

class FirestorePublicProfileStore implements PublicProfileStore {
  FirestorePublicProfileStore(this._db);
  final FirebaseFirestore _db;

  @override
  Future<Map<String, dynamic>?> read(String uid) async =>
      (await _db.collection(FirestorePaths.publicProfiles).doc(uid).get()).data();

  @override
  Future<void> write(String uid, Map<String, Object?> data) =>
      _db.collection(FirestorePaths.publicProfiles).doc(uid).set(data);
}

/// Keeps one person's public profile in step with their private account.
/// Writes only when the public view actually changes (a push-token update or
/// a GPS fix within the same ~1 km costs nothing). The first account snapshot
/// also creates or repairs a missing or stale public profile, which covers
/// accounts made while no trusted function was running.
class PublicProfileSync {
  PublicProfileSync(this._store);
  final PublicProfileStore _store;

  Map<String, Object?>? _last;
  bool _checkedStored = false;
  Future<void> _queue = Future.value();

  /// Handles one snapshot of `users/{uid}`. Calls are serialised.
  Future<void> onAccount(
    String uid,
    Map<String, dynamic>? user, {
    required bool emailVerified,
    required bool phoneVerified,
  }) {
    final next = _queue.then((_) async {
      if (user == null) return; // no account document yet
      final profile = publicProfileOf(uid, user, emailVerified: emailVerified, phoneVerified: phoneVerified);
      if (!_checkedStored) {
        _checkedStored = true;
        final stored = await _store.read(uid);
        if (stored != null) {
          final comparable = Map<String, Object?>.from(stored)..remove('updatedAt');
          _last = comparable;
        }
      }
      if (_last != null && sameValue(_last, profile)) return;
      await _store.write(uid, profile);
      _last = profile;
    }).catchError((Object e) {
      // Never break the app over this; the next account change retries.
      Logger.w('Public profile not updated: $e');
    });
    _queue = next;
    return next;
  }
}

/// Starts the sync for whoever is signed in; stops on sign-out. Watched once
/// by the app root.
final publicProfileSyncProvider = Provider<void>((ref) {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
  String? currentUid;

  void stop() {
    sub?.cancel();
    sub = null;
    currentUid = null;
  }

  void start(String uid) {
    if (currentUid == uid) return;
    stop();
    currentUid = uid;
    final db = ref.read(firestoreProvider);
    final auth = ref.read(firebaseAuthProvider);
    final sync = PublicProfileSync(FirestorePublicProfileStore(db));
    sub = db.collection(FirestorePaths.users).doc(uid).snapshots().listen((snap) {
      final User? me = auth.currentUser;
      if (me == null || me.uid != uid) return;
      sync.onAccount(
        uid,
        snap.data(),
        emailVerified: me.emailVerified,
        phoneVerified: (me.phoneNumber ?? '').isNotEmpty,
      );
    }, onError: (Object e) => Logger.w('Account listener stopped: $e'));
  }

  ref.listen(authStateProvider, (_, next) {
    final uid = next.value?.uid;
    if (uid == null) {
      stop();
    } else {
      start(uid);
    }
  }, fireImmediately: true);
  ref.onDispose(stop);
});
