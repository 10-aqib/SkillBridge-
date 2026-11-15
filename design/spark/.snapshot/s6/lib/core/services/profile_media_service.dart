import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';

/// Why an upload was refused before it reached Storage.
class MediaUploadException implements Exception {
  const MediaUploadException(this.code);

  /// 'too-large' | 'unsupported-type' | 'upload-failed' | 'permission-denied'
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
class ProfileMediaService {
  ProfileMediaService(this._storage);

  final FirebaseStorage _storage;

  /// Mirrors storage.rules (`size < 5 MB`).
  static const int maxBytes = 5 * 1024 * 1024;

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

  Future<String> uploadProfilePhoto({required String uid, required XFile file}) async {
    final ref = await _put(uid: uid, folder: 'profile', base: 'avatar', file: file);
    return ref.getDownloadURL();
  }

  Future<String> uploadPortfolioImage({required String uid, required XFile file}) async {
    final ref = await _put(uid: uid, folder: 'portfolio', base: 'work', file: file);
    return ref.getDownloadURL();
  }

  /// Photo for a job post, in the client's own folder (owner-only writes,
  /// public reads — job photos are shown on the public job).
  Future<String> uploadJobPhoto({required String uid, required XFile file}) async {
    final ref = await _put(uid: uid, folder: 'jobPhotos', base: 'job', file: file);
    return ref.getDownloadURL();
  }

  /// Returns the private storage path (e.g. users/abc/verificationDocuments/cnic_front_….jpg).
  Future<String> uploadVerificationDocument({
    required String uid,
    required XFile file,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final ref = await _put(
      uid: uid,
      folder: 'verificationDocuments',
      base: label,
      file: file,
      allowPdf: true,
      onProgress: onProgress,
    );
    return ref.fullPath;
  }

  /// Deletes an object this user owns, given its download URL. Files outside
  /// users/{uid}/ (e.g. Google profile photos) are left alone.
  Future<void> deleteOwnedByUrl({required String uid, required String url}) async {
    Reference ref;
    try {
      ref = _storage.refFromURL(url);
    } catch (_) {
      return; // not a Firebase Storage URL
    }
    if (!ref.fullPath.startsWith('users/$uid/')) return;
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }

  /// Removes one of this user's private verification uploads (e.g. replaced
  /// before submitting). Only paths inside users/{uid}/verificationDocuments.
  Future<void> deleteOwnedVerificationPath({required String uid, required String path}) async {
    if (!path.startsWith('users/$uid/verificationDocuments/')) return;
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  Future<Reference> _put({
    required String uid,
    required String folder,
    required String base,
    required XFile file,
    bool allowPdf = false,
    void Function(double progress)? onProgress,
  }) async {
    final contentType = contentTypeFor(file.name, mimeType: file.mimeType, allowPdf: allowPdf);
    if (contentType == null) throw const MediaUploadException('unsupported-type');
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes >= maxBytes) throw const MediaUploadException('too-large');

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = uniqueSuffix();
    final ref = _storage.ref('users/$uid/$folder/${base}_${stamp}_$suffix.${_extensionFor(contentType)}');
    try {
      final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
      // Progress is read from the latest snapshot on a timer. Listening to
      // snapshotEvents on the web kept the upload future from ever completing
      // (the screen stayed at "Uploading… 100%").
      Timer? ticker;
      if (onProgress != null) {
        ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
          final s = task.snapshot;
          if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
        });
      }
      try {
        await task;
      } finally {
        ticker?.cancel();
      }
      onProgress?.call(1);
      return ref;
    } on FirebaseException catch (e) {
      throw MediaUploadException(e.code == 'unauthorized' ? 'permission-denied' : 'upload-failed');
    }
  }
}

final profileMediaServiceProvider = Provider<ProfileMediaService>((ref) {
  return ProfileMediaService(ref.watch(firebaseStorageProvider));
});
