import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/core/media/image_host.dart';
import 'package:skill_bridge/core/media/private_media.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';

/// Why an upload was refused.
class MediaUploadException implements Exception {
  const MediaUploadException(this.code);

  /// 'too-large' | 'too-large-private' | 'unsupported-type' | 'upload-failed' |
  /// 'permission-denied' | 'not-configured'
  final String code;

  @override
  String toString() => 'MediaUploadException($code)';
}

/// Uploads profile media to Firebase Storage using the paths the rules allow:
///
/// * `users/{uid}/profile/…`   public (profile photo)
/// * `users/{uid}/portfolio/…` public (work photos)
/// * `users/{uid}/verificationDocuments/…` owner + staff only. For these the
///   service returns the **storage path**, never a download URL, so no
///   public link to a verification document is ever stored in Firestore.
/// Profile media on the free Firebase plan (Phase S6; Firebase Storage needs
/// the paid plan):
///
/// * profile photo, portfolio and job photos are public: uploaded to the
///   image host ([ImageHost]); the link is stored. Without a configured host
///   these uploads are hidden ('not-configured').
/// * verification documents are private: stored in
///   `users/{uid}/verificationDocs/{id}` (owner and staff only, rules), and the
///   record keeps that path, never a public link.
class ProfileMediaService {
  ProfileMediaService(this._db, this._host);

  final FirebaseFirestore _db;
  final ImageHost? _host;

  /// Public photos (the image host's upload preset allows 2 MB).
  static const int maxBytes = 2 * 1024 * 1024;

  /// Random file-name suffix. Not `nextInt(1 << 32)`: on the web `1 << 32`
  /// is 0 and nextInt throws, which made every web upload fail.
  @visibleForTesting
  static String uniqueSuffix([Random? random]) =>
      (random ?? Random()).nextInt(0x7fffffff).toRadixString(36);

  static const Map<String, String> _imageTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
  };

  /// Content type for an upload, or null if the file type isn't allowed.
  static String? contentTypeFor(String fileName, {String? mimeType, bool allowPdf = false}) {
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return mimeType;
      if (allowPdf && mimeType == 'application/pdf') return mimeType;
    }
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (_imageTypes.containsKey(ext)) return _imageTypes[ext];
    if (allowPdf && ext == 'pdf') return 'application/pdf';
    return null;
  }

  static String _extensionFor(String contentType) => switch (contentType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/heic' => 'heic',
        'application/pdf' => 'pdf',
        _ => 'jpg',
      };

  Future<String> uploadProfilePhoto({required String uid, required XFile file}) =>
      _public(uid: uid, folder: 'profile', base: 'avatar', file: file);

  Future<String> uploadPortfolioImage({required String uid, required XFile file}) =>
      _public(uid: uid, folder: 'portfolio', base: 'work', file: file);

  /// Photo for a job post (shown on the public job).
  Future<String> uploadJobPhoto({required String uid, required XFile file}) =>
      _public(uid: uid, folder: 'jobs', base: 'job', file: file);

  /// Stores a verification document privately and returns its path
  /// (e.g. users/abc/verificationDocs/cnic_front_…). Images are shrunk when
  /// picked; a PDF must already be under the private size limit.
  Future<String> uploadVerificationDocument({
    required String uid,
    required XFile file,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final contentType = contentTypeFor(file.name, mimeType: file.mimeType, allowPdf: true);
    if (contentType == null || contentType == 'image/heic') throw const MediaUploadException('unsupported-type');
    final bytes = await file.readAsBytes();
    final id = '${label}_${DateTime.now().millisecondsSinceEpoch}_${uniqueSuffix()}';
    final path = await PrivateMedia.put(
      _db.collection('users').doc(uid).collection('verificationDocs').doc(id),
      bytes,
      contentType: contentType,
    );
    onProgress?.call(1);
    return path;
  }

  /// Old public photos can't be deleted from the app on the free plan (the
  /// image host needs its secret for that); they're removed from the
  /// profile, and staff can delete them in the host's dashboard.
  Future<void> deleteOwnedByUrl({required String uid, required String url}) async {}

  /// Removes one of this user's private verification uploads (e.g. replaced
  /// before submitting). Only paths inside users/{uid}/verificationDocs.
  Future<void> deleteOwnedVerificationPath({required String uid, required String path}) async {
    if (!path.startsWith('users/$uid/verificationDocs/')) return;
    try {
      await _db.doc(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  Future<String> _public({required String uid, required String folder, required String base, required XFile file}) async {
    final host = _host;
    if (host == null) throw const MediaUploadException('not-configured');
    final contentType = contentTypeFor(file.name, mimeType: file.mimeType);
    if (contentType == null || contentType == 'image/heic') throw const MediaUploadException('unsupported-type');
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes >= maxBytes) throw const MediaUploadException('too-large');
    final name = '${base}_${DateTime.now().millisecondsSinceEpoch}_${uniqueSuffix()}.${_extensionFor(contentType)}';
    try {
      return await host.upload(bytes, contentType: contentType, folder: '$folder/$uid', fileName: name);
    } catch (_) {
      throw const MediaUploadException('upload-failed');
    }
  }
}

final profileMediaServiceProvider = Provider<ProfileMediaService>((ref) {
  return ProfileMediaService(ref.watch(firestoreProvider), ref.watch(imageHostProvider));
});
