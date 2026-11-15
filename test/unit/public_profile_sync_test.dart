import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/services/public_profile_sync.dart';

class _Store implements PublicProfileStore {
  Map<String, dynamic>? stored;
  final writes = <Map<String, Object?>>[];
  bool failNext = false;

  @override
  Future<Map<String, dynamic>?> read(String uid) async => stored;

  @override
  Future<void> write(String uid, Map<String, Object?> data) async {
    if (failNext) {
      failNext = false;
      throw StateError('permission-denied');
    }
    writes.add(data);
    stored = Map<String, dynamic>.from(data);
  }
}

Map<String, dynamic> worker({Map<String, dynamic> extra = const {}, Map<String, dynamic> wp = const {}}) => {
      'uid': 'w1',
      'role': 'worker',
      'displayName': 'Bilal Ahmed',
      'email': 'bilal@example.com',
      'phoneNumber': '+923001234567',
      'address': 'House 5, Gulberg III',
      'fcmToken': 'secret-token',
      'cnicNumber': '35202-1234567-1',
      'isActive': true,
      'isEmailVerified': true,
      'isPhoneVerified': false,
      'isCnicVerified': false,
      'rating': 4.5,
      'totalReviews': 2,
      'city': 'Lahore',
      'location': const GeoPoint(31.520412, 74.358734),
      'workerProfile': {
        'headline': 'Electrician',
        'hourlyRate': 800.0,
        'totalEarnings': 90000,
        'verificationStatus': 'pending',
        'averageRating': 4.5,
        'totalReviews': 2,
        'totalJobsCompleted': 3,
        'certifications': [
          {'name': 'Wiring', 'issuedBy': 'TEVTA', 'year': 2020, 'imageUrl': 'https://x/cert.jpg'},
        ],
        ...wp,
      },
      ...extra,
    };

void main() {
  group('publicProfileOf', () {
    test('keeps only public fields', () {
      final p = publicProfileOf('w1', worker(), emailVerified: true, phoneVerified: false);
      for (final secret in ['email', 'phoneNumber', 'address', 'fcmToken', 'cnicNumber']) {
        expect(p.containsKey(secret), isFalse, reason: secret);
      }
      final wp = p['workerProfile']! as Map;
      expect(wp.containsKey('totalEarnings'), isFalse);
      expect(wp.containsKey('verificationStatus'), isFalse);
      expect(wp['headline'], 'Electrician');
      expect(wp['totalJobsCompleted'], 3);
      expect(p['uid'], 'w1');
      expect(p['rating'], 4.5);
    });

    test('worker location is coarsened to about 1 km, with a matching geohash', () {
      final p = publicProfileOf('w1', worker(), emailVerified: true, phoneVerified: false);
      expect(p['location'], const GeoPoint(31.52, 74.36));
      expect(p['locationAccuracy'], 'approximate');
      expect((p['geohash']! as String).length, 9);
      expect((p['workerProfile']! as Map)['location'], const GeoPoint(31.52, 74.36));
    });

    test('a hidden location is not published', () {
      final p = publicProfileOf('w1', worker(extra: {'locationVisibility': 'hidden'}),
          emailVerified: true, phoneVerified: false);
      expect(p.containsKey('location'), isFalse);
      expect((p['workerProfile']! as Map).containsKey('location'), isFalse);
    });

    test('certificates keep name, issuer and year only', () {
      final p = publicProfileOf('w1', worker(), emailVerified: true, phoneVerified: false);
      expect((p['workerProfile']! as Map)['certifications'], [
        {'name': 'Wiring', 'issuedBy': 'TEVTA', 'year': 2020},
      ]);
    });

    test('verified badges only when the sign-in account confirms them', () {
      final p = publicProfileOf('w1', worker(extra: {'isPhoneVerified': true}),
          emailVerified: false, phoneVerified: false);
      expect(p['isEmailVerified'], isFalse);
      expect(p['isPhoneVerified'], isFalse);
    });

    test('clients publish no location and no worker profile', () {
      final p = publicProfileOf('c1', {
        'role': 'client', 'displayName': 'Ayesha', 'location': const GeoPoint(31.5, 74.3),
        'workerProfile': {'headline': 'x'},
      }, emailVerified: false, phoneVerified: false);
      expect(p.containsKey('location'), isFalse);
      expect(p.containsKey('workerProfile'), isFalse);
    });
  });

  group('PublicProfileSync', () {
    test('creates a missing public profile on the first account snapshot', () async {
      final store = _Store();
      final sync = PublicProfileSync(store);
      await sync.onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      expect(store.writes, hasLength(1));
    });

    test('writes nothing when the public view is unchanged', () async {
      final store = _Store();
      final sync = PublicProfileSync(store);
      await sync.onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      // A push-token change and a GPS fix within the same ~1 km.
      await sync.onAccount('w1', worker(extra: {'fcmToken': 'new', 'location': const GeoPoint(31.5204, 74.3589)}),
          emailVerified: true, phoneVerified: false);
      expect(store.writes, hasLength(1));
    });

    test('an up-to-date stored profile is not rewritten after restart', () async {
      final store = _Store()
        ..stored = Map<String, dynamic>.from(
            publicProfileOf('w1', worker(), emailVerified: true, phoneVerified: false));
      await PublicProfileSync(store).onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      expect(store.writes, isEmpty);
    });

    test('a stale stored profile is repaired', () async {
      final store = _Store()..stored = {'uid': 'w1', 'role': 'worker', 'displayName': 'Old name'};
      await PublicProfileSync(store).onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      expect(store.writes.single['displayName'], 'Bilal Ahmed');
    });

    test('a public change is written', () async {
      final store = _Store();
      final sync = PublicProfileSync(store);
      await sync.onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      await sync.onAccount('w1', worker(wp: {'headline': 'Senior electrician'}),
          emailVerified: true, phoneVerified: false);
      expect(store.writes, hasLength(2));
      expect((store.writes.last['workerProfile']! as Map)['headline'], 'Senior electrician');
    });

    test('a refused write does not break the app, and the next change retries', () async {
      final store = _Store()..failNext = true;
      final sync = PublicProfileSync(store);
      await sync.onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      expect(store.writes, isEmpty);
      await sync.onAccount('w1', worker(), emailVerified: true, phoneVerified: false);
      expect(store.writes, hasLength(1));
    });

    test('no account document yet: nothing written', () async {
      final store = _Store();
      await PublicProfileSync(store).onAccount('w1', null, emailVerified: false, phoneVerified: false);
      expect(store.writes, isEmpty);
    });
  });
}
