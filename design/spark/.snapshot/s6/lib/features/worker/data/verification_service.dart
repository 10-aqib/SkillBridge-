import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';

/// State of a worker's private verification submission.
class VerificationSubmission {
  const VerificationSubmission({
    required this.status,
    required this.documentCount,
    this.maskedCnic,
    this.submittedAt,
  });

  /// 'pending' | 'verified' | 'rejected'
  final String status;
  final int documentCount;

  /// e.g. "35202-•••••••-1" — the full number is never shown back.
  final String? maskedCnic;
  final DateTime? submittedAt;

  static String? mask(String? cnic) {
    if (cnic == null || cnic.length != 15) return null;
    return '${cnic.substring(0, 5)}-•••••••-${cnic.substring(14)}';
  }
}

/// CNIC + document submission, stored at users/{uid}/private/verification.
/// The firestore rules make that document readable only by its owner and staff,
/// and the documents themselves live in the owner/staff-only Storage folder.
class VerificationService {
  VerificationService(this._firestore);

  final FirebaseFirestore _firestore;

  static final RegExp cnicPattern = RegExp(r'^\d{5}-\d{7}-\d$');

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('private').doc('verification');

  Stream<VerificationSubmission?> watch(String uid) {
    return _doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return VerificationSubmission(
        status: data['status'] as String? ?? 'pending',
        documentCount: (data['documents'] as List?)?.length ?? 0,
        maskedCnic: VerificationSubmission.mask(data['cnicNumber'] as String?),
        submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  /// [documentPaths] are Storage paths returned by
  /// ProfileMediaService.uploadVerificationDocument — never download URLs.
  Future<void> submit({
    required String uid,
    required String cnic,
    required List<String> documentPaths,
  }) async {
    if (!cnicPattern.hasMatch(cnic)) {
      throw ArgumentError.value(cnic, 'cnic', 'must look like 12345-1234567-1');
    }
    if (documentPaths.isEmpty || documentPaths.length > 3) {
      throw ArgumentError.value(documentPaths.length, 'documentPaths', 'must be 1–3');
    }
    final batch = _firestore.batch();
    batch.set(_doc(uid), {
      'cnicNumber': cnic,
      'documents': documentPaths,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Public, non-sensitive status so the profile can show "Under review".
    batch.update(_firestore.collection('users').doc(uid), {
      'workerProfile.verificationStatus': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService(ref.watch(firestoreProvider));
});

final verificationSubmissionProvider =
    StreamProvider.family<VerificationSubmission?, String>((ref, uid) {
  return ref.watch(verificationServiceProvider).watch(uid);
});
