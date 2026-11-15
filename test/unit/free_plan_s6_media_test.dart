import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/core/media/image_host.dart';
import 'package:skill_bridge/core/media/private_media.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';

class _NoDb extends Fake implements FirebaseFirestore {}

class _Host implements ImageHost {
  final calls = <String>[];
  @override
  Future<String> upload(Uint8List bytes, {required String contentType, required String folder, required String fileName}) async {
    calls.add('$folder|$contentType|${bytes.length}');
    return 'https://res.cloudinary.com/demo/image/upload/v1/skillbridge/$folder/$fileName';
  }
}

XFile _jpg([int size = 1024]) => XFile.fromData(Uint8List(size), name: 'photo.jpg', mimeType: 'image/jpeg');

void main() {
  group('image host settings', () {
    test('off unless both the cloud name and the preset are set', () {
      expect(const ImageHostConfig(cloudName: '', uploadPreset: '').isConfigured, isFalse);
      expect(const ImageHostConfig(cloudName: 'demo', uploadPreset: '').isConfigured, isFalse);
      expect(const ImageHostConfig(cloudName: 'demo', uploadPreset: 'sb_unsigned').isConfigured, isTrue);
    });
    test('odd characters are rejected (no URL injection)', () {
      expect(const ImageHostConfig(cloudName: 'demo/../x', uploadPreset: 'p').isConfigured, isFalse);
    });
    test('the default build has public uploads off', () {
      expect(ImageHostConfig.fromEnvironment().isConfigured, isFalse);
    });
  });

  group('Cloudinary upload', () {
    test('sends an unsigned upload to the account, in the skillbridge folder, and returns the https link', () async {
      late http.BaseRequest seen;
      final client = MockClient.streaming((req, body) async {
        seen = req;
        final text = utf8.decode(await body.toBytes(), allowMalformed: true);
        expect(text, contains('name="upload_preset"'));
        expect(text, contains('sb_unsigned'));
        expect(text, contains('skillbridge/profile/u1'));
        expect(text, isNot(contains('api_secret')));
        return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode({
          'secure_url': 'https://res.cloudinary.com/demo/image/upload/v1/skillbridge/profile/u1/a.jpg',
        }))), 200);
      });
      final host = CloudinaryImageHost(const ImageHostConfig(cloudName: 'demo', uploadPreset: 'sb_unsigned'), client: client);
      final url = await host.upload(Uint8List(10), contentType: 'image/jpeg', folder: 'profile/u1', fileName: 'a.jpg');
      expect(seen.url.toString(), 'https://api.cloudinary.com/v1_1/demo/image/upload');
      expect(url, startsWith('https://res.cloudinary.com/'));
    });
    test('a refused upload or an unexpected link is an error', () async {
      final refused = CloudinaryImageHost(const ImageHostConfig(cloudName: 'demo', uploadPreset: 'p'),
          client: MockClient((_) async => http.Response('{"error":{}}', 400)));
      await expectLater(refused.upload(Uint8List(1), contentType: 'image/jpeg', folder: 'x', fileName: 'a.jpg'),
          throwsA(isA<ImageHostException>()));
      final odd = CloudinaryImageHost(const ImageHostConfig(cloudName: 'demo', uploadPreset: 'p'),
          client: MockClient((_) async => http.Response('{"secure_url":"http://evil.example/a.jpg"}', 200)));
      await expectLater(odd.upload(Uint8List(1), contentType: 'image/jpeg', folder: 'x', fileName: 'a.jpg'),
          throwsA(isA<ImageHostException>()));
    });
  });

  group('profile media', () {
    test('public photos need the image host: not-configured without it', () async {
      final media = ProfileMediaService(_NoDb(), null);
      await expectLater(media.uploadProfilePhoto(uid: 'u1', file: _jpg()),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'not-configured')));
    });
    test('public photos go to the host, per person and kind', () async {
      final host = _Host();
      final media = ProfileMediaService(_NoDb(), host);
      final url = await media.uploadPortfolioImage(uid: 'u1', file: _jpg());
      expect(url, startsWith('https://res.cloudinary.com/'));
      expect(host.calls.single, startsWith('portfolio/u1|image/jpeg|'));
    });
    test('public photos over 2 MB and unsupported types are refused before upload', () async {
      final host = _Host();
      final media = ProfileMediaService(_NoDb(), host);
      await expectLater(media.uploadJobPhoto(uid: 'u1', file: _jpg(2 * 1024 * 1024)),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'too-large')));
      await expectLater(media.uploadJobPhoto(uid: 'u1', file: XFile.fromData(Uint8List(10), name: 'a.gif', mimeType: 'text/plain')),
          throwsA(isA<MediaUploadException>().having((e) => e.code, 'code', 'unsupported-type')));
      expect(host.calls, isEmpty);
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
