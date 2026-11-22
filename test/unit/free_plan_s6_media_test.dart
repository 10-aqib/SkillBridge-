import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/core/media/image_host.dart';
import 'package:skill_bridge/core/media/private_media.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';

// Public photos in Firebase Storage (Phase G4; replaced the S6 image host)
// and private files in Firestore (S6, unchanged).

class _NoDb extends Fake implements FirebaseFirestore {}

class _Host implements ImageHost {
  final calls = <String>[];
  final deletes = <String>[];
  Object? failWith;
  double? reportProgress;

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
    calls.add('$uid/$folder|$contentType|${bytes.length}|$fileName');
    if (reportProgress != null) onProgress?.call(reportProgress!);
    if (failWith != null) throw failWith!;
    return 'https://firebasestorage.googleapis.com/v0/b/demo.appspot.com/o/users%2F$uid%2F$folder%2F$fileName?alt=media&token=t';
  }

  @override
  Future<void> deleteOwned({required String uid, required String url}) async => deletes.add('$uid|$url');
}

final _jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(60, 0)]);
final _pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ...List.filled(60, 0)]);
final _webpBytes = Uint8List.fromList([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, ...List.filled(60, 0)]);

XFile _file(Uint8List bytes, {String name = 'photo.jpg', String mime = 'image/jpeg'}) => XFile.fromData(bytes, name: name, mimeType: mime);

void main() {
  group('photo uploads switch', () {
    test('off without a Firebase app (tests, misconfigured builds): uploads hidden', () {
      expect(photoUploadsConfigured(), isFalse);
    });
  });

  group('Storage links', () {
    const url = 'https://firebasestorage.googleapis.com/v0/b/skill-bridge-c68c3.firebasestorage.app/o/users%2Fu1%2Fprofile%2Favatar_1.jpg?alt=media&token=abc';

    test('the object path is read from a download link', () {
      expect(storagePathOf(url), 'users/u1/profile/avatar_1.jpg');
      expect(storagePathOf('https://lh3.googleusercontent.com/a/photo'), isNull);
      expect(storagePathOf('https://res.cloudinary.com/demo/image/upload/a.jpg'), isNull);
    });

    test("only the person's own public photo folders count as theirs", () {
      expect(isOwnedPublicPhotoPath('users/u1/profile/a.jpg', 'u1'), isTrue);
      expect(isOwnedPublicPhotoPath('users/u1/portfolio/a.jpg', 'u1'), isTrue);
      expect(isOwnedPublicPhotoPath('users/u1/jobPhotos/a.jpg', 'u1'), isTrue);
      expect(isOwnedPublicPhotoPath('users/u2/profile/a.jpg', 'u1'), isFalse, reason: 'someone else');
      expect(isOwnedPublicPhotoPath('users/u1/verificationDocuments/a.jpg', 'u1'), isFalse);
      expect(isOwnedPublicPhotoPath('users/u1/profile/x/a.jpg', 'u1'), isFalse);
      expect(isOwnedPublicPhotoPath('chats/c/u1/m/a.jpg', 'u1'), isFalse);
    });
  });

  group('image check', () {
    test('JPEG, PNG and WebP are recognised by their first bytes', () {
      expect(ProfileMediaService.sniffImageType(_jpegBytes), 'image/jpeg');
      expect(ProfileMediaService.sniffImageType(_pngBytes), 'image/png');
      expect(ProfileMediaService.sniffImageType(_webpBytes), 'image/webp');
      expect(ProfileMediaService.sniffImageType(Uint8List.fromList('MZ executable'.codeUnits)), isNull);
      expect(ProfileMediaService.sniffImageType(Uint8List(0)), isNull);
    });
  });

  group('profile media', () {
    test('without photo uploads: not-configured', () async {
      final media = ProfileMediaService(_NoDb(), null);
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _file(_jpegBytes)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'not-configured')));
    });

    test('photos go to the owner\'s folder by kind, typed from their bytes, with progress', () async {
      final host = _Host()..reportProgress = 0.5;
      final media = ProfileMediaService(_NoDb(), host);
      final seen = <double>[];
      final url = await media.uploadProfilePhoto(uid: 'u1', file: _file(_pngBytes, name: 'p.png', mime: 'image/png'), onProgress: seen.add);
      expect(url, startsWith('https://firebasestorage.googleapis.com/'));
      expect(seen, [0.5]);
      await media.uploadPortfolioImage(uid: 'u1', file: _file(_jpegBytes));
      await media.uploadJobPhoto(uid: 'u1', file: _file(_webpBytes, name: 'w.webp', mime: 'image/webp'));
      expect(host.calls[0], startsWith('u1/profile|image/png|'));
      expect(host.calls[0], endsWith('.png'));
      expect(host.calls[1], startsWith('u1/portfolio|image/jpeg|'));
      expect(host.calls[2], startsWith('u1/jobPhotos|image/webp|'));
    });

    test('over 2 MB, wrong types and renamed non-images are refused before upload', () async {
      final host = _Host();
      final media = ProfileMediaService(_NoDb(), host);
      final big = Uint8List(2 * 1024 * 1024)..setAll(0, [0xFF, 0xD8, 0xFF]);
      await expectLater(media.uploadJobPhoto(uid: 'u1', file: _file(big)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'too-large')));
      await expectLater(media.uploadJobPhoto(uid: 'u1', file: _file(Uint8List(10), name: 'a.gif', mime: 'text/plain')),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'unsupported-type')));
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _file(Uint8List.fromList('MZ not an image'.codeUnits))),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'unsupported-type')), reason: 'named .jpg but not a JPEG');
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _file(Uint8List(0))),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'upload-failed')));
      expect(host.calls, isEmpty);
    });

    test('a cancelled or refused upload reports why', () async {
      final host = _Host()..failWith = const ImageHostException('cancelled');
      final media = ProfileMediaService(_NoDb(), host);
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _file(_jpegBytes)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'cancelled')));
      host.failWith = const ImageHostException('permission-denied');
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _file(_jpegBytes)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'permission-denied')));
      host.failWith = StateError('network');
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _file(_jpegBytes)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'upload-failed')));
    });

    test('deleting by link goes to the host (which only deletes the person\'s own files)', () async {
      final host = _Host();
      final media = ProfileMediaService(_NoDb(), host);
      await media.deleteOwnedByUrl(uid: 'u1', url: 'https://x/y');
      expect(host.deletes, ['u1|https://x/y']);
      // Without photo uploads there is nothing to delete.
      await ProfileMediaService(_NoDb(), null).deleteOwnedByUrl(uid: 'u1', url: 'https://x/y');
    });

    test('UploadCancel cancels a task attached later, and one attached after cancel', () async {
      var cancelled = 0;
      final c = UploadCancel();
      c.attach(() async {
        cancelled++;
        return true;
      });
      await c.cancel();
      expect(c.isCancelled, isTrue);
      expect(cancelled, 1);
      final late = UploadCancel();
      await late.cancel();
      late.attach(() async {
        cancelled++;
        return true;
      });
      expect(cancelled, 2);
    });

    test('private files are limited to 700 KB', () async {
      expect(privateMediaMaxBytes, 700 * 1024);
      // Checked by PrivateMedia.put before anything is written.
      expect(() => PrivateMedia.checkSize(Uint8List(privateMediaMaxBytes + 1)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'too-large-private')));
      expect(() => PrivateMedia.checkSize(Uint8List(0)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'upload-failed')));
      expect(() => PrivateMedia.checkSize(Uint8List(privateMediaMaxBytes)), returnsNormally);
    });
  });
}
