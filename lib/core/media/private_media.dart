import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart' show MediaUploadException;

/// Private files on the free Firebase plan (Phase S6): chat photos, work
/// evidence and ID documents are kept as bytes inside Firestore documents,
/// where the rules let only the right people read them (the chat's members,
/// the contract's parties, the account owner) plus staff. They never go to
/// the public image host.
///
/// A Firestore document holds at most 1 MiB, so each file is limited to
/// [privateMediaMaxBytes]; photos are shrunk when picked.
const privateMediaMaxBytes = 700 * 1024;

const privateImageTypes = ['image/jpeg', 'image/png', 'image/webp'];

abstract final class PrivateMedia {
  /// Stores [bytes] at [ref] (create only: an existing file is never
  /// replaced) and returns the document path, which is what records keep.
  static Future<String> put(
    DocumentReference<Map<String, dynamic>> ref,
    Uint8List bytes, {
    required String contentType,
    Map<String, Object?> extra = const {},
  }) async {
    checkSize(bytes);
    try {
      await ref.set({'data': Blob(bytes), 'contentType': contentType, 'createdAt': FieldValue.serverTimestamp(), ...extra});
    } on FirebaseException catch (e) {
      throw MediaUploadException(e.code == 'permission-denied' ? 'permission-denied' : 'upload-failed');
    }
    return ref.path;
  }

  /// Refuses an empty file or one over [privateMediaMaxBytes].
  static void checkSize(Uint8List bytes) {
    if (bytes.isEmpty) throw const MediaUploadException('upload-failed');
    if (bytes.length > privateMediaMaxBytes) throw const MediaUploadException('too-large-private');
  }

  /// The file's bytes, read with the signed-in person's own access.
  static Future<Uint8List?> read(FirebaseFirestore db, String path) async {
    final data = (await db.doc(path).get()).data()?['data'];
    return data is Blob ? data.bytes : null;
  }
}
