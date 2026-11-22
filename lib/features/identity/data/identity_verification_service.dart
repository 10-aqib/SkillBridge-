import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/identity/domain/identity_models.dart';

/// Server configuration for identity verification. [provider] is null when
/// verification isn't available (no authorised NADRA access yet and not a
/// test environment).
class IdentityConfig {
  const IdentityConfig({required this.provider, required this.test, required this.consentVersion, required this.maxAttempts, this.nadraChecks = const {}});
  final String? provider;
  final bool test;
  final String consentVersion;
  final int maxAttempts;
  final Map<String, bool> nadraChecks;

  static const unavailable = IdentityConfig(provider: null, test: false, consentVersion: '', maxAttempts: 0);
  bool get available => provider != null;
}

class IdentitySession {
  const IdentitySession({required this.sessionId, required this.provider, required this.test, required this.expiresAt});
  final String sessionId;
  final String provider;
  final bool test;
  final DateTime expiresAt;
}

class IdentitySubmitResult {
  const IdentitySubmitResult({required this.status, this.failureCategory, required this.test, this.attemptsLeft = 0});
  final IdentityStatus status;
  final String? failureCategory;
  final bool test;
  final int attemptsLeft;

  /// Pending after a submit = a retryable problem (poor quality, service).
  bool get retryable => status == IdentityStatus.pending && attemptsLeft > 0;
}

enum IdentityProblem { recentLogin, consent, invalidCnic, syntheticOnly, inUse, alreadyVerified, dailyLimit, attemptLimit, expired, notAvailable, offline, generic }

class IdentityException implements Exception {
  const IdentityException(this.problem);
  final IdentityProblem problem;
  @override
  String toString() => 'IdentityException($problem)';
}

/// Talks to the trusted identity functions (IdentityVerificationService).
/// The app never decides a result: it sends the CNIC, consent and the
/// capture, and shows what the server answers.
class IdentityVerificationService {
  IdentityVerificationService(this._functions);
  final FirebaseFunctions Function() _functions;

  static IdentityProblem problemFor(String code, String? message) {
    final m = message ?? '';
    return switch (code) {
      'failed-precondition' when m.contains('recent-login') => IdentityProblem.recentLogin,
      'failed-precondition' when m.contains('consent') => IdentityProblem.consent,
      'failed-precondition' when m.contains('not-available') => IdentityProblem.notAvailable,
      'failed-precondition' when m.contains('expired') => IdentityProblem.expired,
      'deadline-exceeded' when m.contains('expired') => IdentityProblem.expired,
      'invalid-argument' when m.contains('synthetic') => IdentityProblem.syntheticOnly,
      'invalid-argument' when m.contains('cnic') => IdentityProblem.invalidCnic,
      'already-exists' when m.contains('cnic-in-use') => IdentityProblem.inUse,
      'already-exists' => IdentityProblem.alreadyVerified,
      'resource-exhausted' when m.contains('attempt') => IdentityProblem.attemptLimit,
      'resource-exhausted' => IdentityProblem.dailyLimit,
      'not-found' || 'unimplemented' => IdentityProblem.notAvailable,
      'unavailable' || 'deadline-exceeded' => IdentityProblem.offline,
      _ => IdentityProblem.generic,
    };
  }

  Future<Map<String, dynamic>> _call(String name, [Map<String, dynamic>? data]) async {
    final FirebaseFunctions f;
    try {
      f = _functions();
    } catch (_) {
      throw const IdentityException(IdentityProblem.notAvailable);
    }
    try {
      final r = await f.httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 60))).call<Object?>(data);
      final v = r.data;
      return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      // Never log the request: it can contain a CNIC or a capture.
      Logger.w('[Identity] $name refused: ${e.code}');
      throw IdentityException(problemFor(e.code, e.message));
    } catch (e) {
      Logger.w('[Identity] $name failed: ${e.runtimeType}');
      throw const IdentityException(IdentityProblem.offline);
    }
  }

  Future<IdentityConfig> config() async {
    try {
      final d = await _call('getIdentityVerificationConfig');
      final checks = d['nadra'] is Map && (d['nadra'] as Map)['checks'] is Map
          ? {for (final e in ((d['nadra'] as Map)['checks'] as Map).entries) e.key.toString(): e.value == true}
          : <String, bool>{};
      return IdentityConfig(
        provider: d['provider'] is String ? d['provider'] as String : null,
        test: d['test'] == true,
        consentVersion: d['consentVersion'] is String ? d['consentVersion'] as String : '',
        maxAttempts: d['maxAttempts'] is num ? (d['maxAttempts'] as num).toInt() : 0,
        nadraChecks: checks,
      );
    } on IdentityException catch (e) {
      if (e.problem == IdentityProblem.notAvailable) return IdentityConfig.unavailable;
      rethrow;
    }
  }

  Future<IdentitySession> start({required String cnic, required String consentVersion}) async {
    final d = await _call('createIdentityVerificationSession', {'cnic': cnic, 'consentAccepted': true, 'consentVersion': consentVersion});
    return IdentitySession(
      sessionId: d['sessionId'] as String,
      provider: d['provider'] as String? ?? '',
      test: d['test'] == true,
      expiresAt: DateTime.fromMillisecondsSinceEpoch((d['expiresAt'] as num?)?.toInt() ?? 0),
    );
  }

  Future<IdentitySubmitResult> submit({
    required String sessionId,
    required String cnic,
    required String requestId,
    required Map<String, Object?> capture,
  }) async {
    final d = await _call('submitIdentityFingerprint', {'sessionId': sessionId, 'cnic': cnic, 'requestId': requestId, 'capture': capture});
    return IdentitySubmitResult(
      status: IdentityStatus.parse(d['status']),
      failureCategory: d['failureCategory'] as String?,
      test: d['test'] == true,
      attemptsLeft: (d['attemptsLeft'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> cancel(String sessionId) async {
    await _call('cancelIdentityVerificationSession', {'sessionId': sessionId});
  }
}

final identityVerificationServiceProvider =
    Provider<IdentityVerificationService>((ref) => IdentityVerificationService(() => ref.read(firebaseFunctionsProvider)));

final identityConfigProvider = FutureProvider.autoDispose<IdentityConfig>((ref) => ref.watch(identityVerificationServiceProvider).config());

/// One past verification attempt (VerificationHistory).
class IdentityAttempt {
  const IdentityAttempt({required this.id, required this.status, required this.maskedCnic, required this.test, this.failureCategory, this.createdAt});
  final String id;
  final IdentityStatus status;
  final String maskedCnic;
  final bool test;
  final String? failureCategory;
  final DateTime? createdAt;
}

/// The signed-in person's own attempts, newest first (VerificationStatusService).
/// The rules let only the owner (and staff) read them.
final identityHistoryProvider = StreamProvider.autoDispose<List<IdentityAttempt>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('identityVerifications')
      .where('userId', isEqualTo: uid)
      .limit(50)
      .snapshots()
      .map((s) {
    final list = [
      for (final d in s.docs)
        IdentityAttempt(
          id: d.id,
          status: IdentityStatus.parse(d.data()['status']),
          maskedCnic: d.data()['maskedCnic'] as String? ?? '',
          test: d.data()['test'] == true,
          failureCategory: d.data()['failureCategory'] as String?,
          createdAt: d.data()['createdAt'] is Timestamp ? (d.data()['createdAt'] as Timestamp).toDate() : null,
        ),
    ];
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  });
});
