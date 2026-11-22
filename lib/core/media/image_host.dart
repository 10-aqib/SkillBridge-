import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/utils/logger.dart';

/// Public photos (Phase G4): profile photo, portfolio and job photos are
/// stored in **Firebase Storage** under the owner's folder,
///
///   users/{uid}/profile/…     users/{uid}/portfolio/…     users/{uid}/jobPhotos/…
///
/// where `storage.rules` let only the owner write (images only, < 2 MB) and
/// keep the files readable for the app. The app saves the download link.
///
/// Private files (chat and work photos, ID documents) never go here: they
/// stay in Firestore (see private_media.dart).
///
/// Storage needs the Blaze plan and Storage enabled in the Firebase console.
/// Build with `--dart-define=PHOTO_UPLOADS=off` to hide photo uploads (for a
/// build that must run against a project without Storage).

/// Cancels an upload that is still running.
class UploadCancel {
  bool _cancelled = false;
  Future<bool> Function()? _onCancel;

  bool get isCancelled => _cancelled;

  Future<void> cancel() async {
    _cancelled = true;
    await _onCancel?.call();
  }

  void attach(Future<bool> Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) onCancel();
  }
}

class ImageHostException implements Exception {
  const ImageHostException(this.code);

  /// 'cancelled' | 'permission-denied' | 'upload-failed'
  final String code;
  @override
  String toString() => 'ImageHostException($code)';
}

/// Uploads one public image for [uid] and returns its https link; deletes
/// the person's own uploads by link.
abstract class ImageHost {
  /// Folders a person may upload public photos into.
  static const folders = {'profile', 'portfolio', 'jobPhotos'};

  Future<String> upload(
    Uint8List bytes, {
    required String contentType,
    required String uid,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  });

  /// Deletes [url] if it is one of [uid]'s own uploads in [folders].
  /// Links that aren't (a Google account photo, someone else's file) are left
  /// alone. A file that is already gone is fine.
  Future<void> deleteOwned({required String uid, required String url});
}

/// Whether [url] is a Firebase Storage download link.
bool isStorageDownloadUrl(String url) =>
    url.startsWith('https://firebasestorage.googleapis.com/') || url.startsWith('http://127.0.0.1:9199/') || url.startsWith('http://localhost:9199/');

/// The object path inside a Firebase Storage download link, or null.
/// `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded path>?alt=media&token=…`
String? storagePathOf(String url) {
  if (!isStorageDownloadUrl(url)) return null;
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  final o = segments.indexOf('o');
  if (o < 0 || o + 1 >= segments.length) return null;
  return segments.sublist(o + 1).join('/');
}

/// Whether [path] is inside [uid]'s own public photo folders.
bool isOwnedPublicPhotoPath(String path, String uid) {
  final parts = path.split('/');
  return parts.length == 4 && parts[0] == 'users' && parts[1] == uid && ImageHost.folders.contains(parts[2]) && parts[3].isNotEmpty && !parts.contains('..');
}

class FirebaseStorageImageHost implements ImageHost {
  FirebaseStorageImageHost(this._storage);
  final FirebaseStorage _storage;

  @override
  Future<String> upload(
    Uint8List bytes, {
    required String contentType,
    required String uid,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  }) async {
    if (!ImageHost.folders.contains(folder)) throw ArgumentError.value(folder, 'folder');
    final ref = _storage.ref('users/$uid/$folder/$fileName');
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType, cacheControl: 'public, max-age=31536000'));
    cancel?.attach(task.cancel);
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call((s.bytesTransferred / s.totalBytes).clamp(0, 1).toDouble());
    }, onError: (_) {});
    try {
      await task;
      onProgress?.call(1);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'canceled' || e.code == 'cancelled' || (cancel?.isCancelled ?? false)) throw const ImageHostException('cancelled');
      Logger.w('[Photos] upload failed: ${e.code}');
      throw ImageHostException(e.code == 'unauthorized' || e.code == 'permission-denied' ? 'permission-denied' : 'upload-failed');
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<void> deleteOwned({required String uid, required String url}) async {
    final path = storagePathOf(url);
    if (path == null || !isOwnedPublicPhotoPath(path, uid)) return;
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

/// Whether this build should offer photo uploads: Storage is configured for
/// the Firebase app and not switched off with PHOTO_UPLOADS=off.
bool photoUploadsConfigured() {
  if (const String.fromEnvironment('PHOTO_UPLOADS') == 'off') return false;
  try {
    return (Firebase.app().options.storageBucket ?? '').isNotEmpty;
  } catch (_) {
    return false; // no Firebase app (tests, misconfigured build)
  }
}

/// The photo host, or null when photo uploads are off (they are hidden).
final imageHostProvider = Provider<ImageHost?>((ref) {
  if (!photoUploadsConfigured()) return null;
  return FirebaseStorageImageHost(FirebaseStorage.instance);
});

/// Whether public photo uploads are available in this build.
final publicPhotoUploadsProvider = Provider<bool>((ref) => ref.watch(imageHostProvider) != null);
