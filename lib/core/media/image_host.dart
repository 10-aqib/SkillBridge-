import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Public photos on the free Firebase plan (Phase S6): profile photos,
/// portfolio and job photos go to an image host, because Firebase Storage
/// needs the paid plan. Private files (chat and work photos, ID documents)
/// never go here: they stay in Firestore (see private_media.dart).
///
/// Build-time settings (`--dart-define` or `--dart-define-from-file=.env`):
/// * `CLOUDINARY_CLOUD_NAME`: the account's cloud name.
/// * `CLOUDINARY_UPLOAD_PRESET`: an **unsigned** upload preset limited to
///   images (jpg, png, webp), 2 MB, folder `skillbridge/`.
/// Neither is a secret. The API secret must never be put in the app.
/// Without both, public photo uploads are switched off and hidden.
class ImageHostConfig {
  const ImageHostConfig({required this.cloudName, required this.uploadPreset});

  factory ImageHostConfig.fromEnvironment() => const ImageHostConfig(
        cloudName: String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
        uploadPreset: String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET'),
      );

  final String cloudName;
  final String uploadPreset;

  static final _safe = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  bool get isConfigured => _safe.hasMatch(cloudName.trim()) && _safe.hasMatch(uploadPreset.trim());
}

/// Uploads one image and returns its public https link.
abstract class ImageHost {
  Future<String> upload(Uint8List bytes, {required String contentType, required String folder, required String fileName});
}

class ImageHostException implements Exception {
  const ImageHostException(this.message);
  final String message;
  @override
  String toString() => 'ImageHostException($message)';
}

/// Cloudinary unsigned upload (https://cloudinary.com/documentation/upload_images#unsigned_upload).
class CloudinaryImageHost implements ImageHost {
  CloudinaryImageHost(this.config, {http.Client? client}) : _client = client ?? http.Client();

  final ImageHostConfig config;
  final http.Client _client;

  @override
  Future<String> upload(Uint8List bytes, {required String contentType, required String folder, required String fileName}) async {
    final uri = Uri.https('api.cloudinary.com', '/v1_1/${config.cloudName.trim()}/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = config.uploadPreset.trim()
      ..fields['folder'] = 'skillbridge/$folder'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final res = await http.Response.fromStream(await _client.send(req).timeout(const Duration(seconds: 60)));
    if (res.statusCode != 200) throw ImageHostException('upload refused (${res.statusCode})');
    final url = (jsonDecode(res.body) as Map<String, dynamic>)['secure_url'];
    if (url is! String || !isHostedImageUrl(url)) throw const ImageHostException('unexpected response');
    return url;
  }
}

/// Whether [url] is an image on the configured host (https only).
bool isHostedImageUrl(String url) => url.startsWith('https://res.cloudinary.com/');

final imageHostConfigProvider = Provider<ImageHostConfig>((ref) => ImageHostConfig.fromEnvironment());

/// The image host, or null when it isn't configured (uploads hidden).
final imageHostProvider = Provider<ImageHost?>((ref) {
  final config = ref.watch(imageHostConfigProvider);
  return config.isConfigured ? CloudinaryImageHost(config) : null;
});

/// Whether public photo uploads are available in this build.
final publicPhotoUploadsProvider = Provider<bool>((ref) => ref.watch(imageHostConfigProvider).isConfigured);
