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
  /// 'permission-denied' | 'not-configured' | 'cancelled'
  final String code;

  @override
  String toString() => 'MediaUploadException($code)';
}

/// Profile media (Phase G4):
///
/// * profile photo, portfolio and job photos are public: uploaded to
///   Firebase Storage in the owner's folder ([ImageHost]); the download link
///   is stored. With photo uploads off these are hidden ('not-configured').
/// * verification documents are private: stored in
///   `users/{uid}/verificationDocs/{id}` in Firestore (owner and staff only,
///   rules), and the record keeps that path, never a public link.
class ProfileMediaService {
  ProfileMediaService(this._db, this._host);

  final FirebaseFirestore _db;
  final ImageHost? _host;

  /// Public photos (storage.rules allow under 2 MB).
  static const int maxBytes = 2 * 1024 * 1024;

  /// The image type the file's first bytes show, or null when it isn't a
  /// JPEG, PNG or WebP image (a renamed file is refused).
  static String? sniffImageType(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 && b[4] == 0x0D && b[5] == 0x0A && b[6] == 0x1A && b[7] == 0x0A) {
      return 'image/png';
    }
    if (b.length >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

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

  Future<String> uploadProfilePhoto({required String uid, required XFile file, void Function(double)? onProgress, UploadCancel? cancel}) =>
      _public(uid: uid, folder: 'profile', base: 'avatar', file: file, onProgress: onProgress, cancel: cancel);

  Future<String> uploadPortfolioImage({required String uid, required XFile file}) =>
      _public(uid: uid, folder: 'portfolio', base: 'work', file: file);

  /// Photo for a job post (shown on the public job).
  Future<String> uploadJobPhoto({required String uid, required XFile file}) =>
      _public(uid: uid, folder: 'jobPhotos', base: 'job', file: file);

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

  /// Deletes one of [uid]'s own public photos by its link (after it was
  /// replaced or removed). Other links, e.g. a Google account photo or an old
  /// image-host link, are left alone. A file that's already gone is fine.
  Future<void> deleteOwnedByUrl({required String uid, required String url}) async {
    await _host?.deleteOwned(uid: uid, url: url);
  }

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

  Future<String> _public({
    required String uid,
    required String folder,
    required String base,
    required XFile file,
    void Function(double)? onProgress,
    UploadCancel? cancel,
  }) async {
    final host = _host;
    if (host == null) throw const MediaUploadException('not-configured');
    final declared = contentTypeFor(file.name, mimeType: file.mimeType);
    if (declared == null || declared == 'image/heic') throw const MediaUploadException('unsupported-type');
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const MediaUploadException('upload-failed');
    if (bytes.lengthInBytes >= maxBytes) throw const MediaUploadException('too-large');
    // Trust the bytes, not the name: an executable called photo.jpg is refused.
    final contentType = sniffImageType(bytes);
    if (contentType == null) throw const MediaUploadException('unsupported-type');
    final name = '${base}_${DateTime.now().millisecondsSinceEpoch}_${uniqueSuffix()}.${_extensionFor(contentType)}';
    try {
      return await host.upload(bytes, contentType: contentType, uid: uid, folder: folder, fileName: name, onProgress: onProgress, cancel: cancel);
    } on ImageHostException catch (e) {
      throw MediaUploadException(e.code);
    } catch (_) {
      throw const MediaUploadException('upload-failed');
    }
  }
}

final profileMediaServiceProvider = Provider<ProfileMediaService>((ref) {
  return ProfileMediaService(ref.watch(firestoreProvider), ref.watch(imageHostProvider));
});
