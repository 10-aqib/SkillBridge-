/// Image compression and network bandwidth optimization helper for Pakistani 3G/4G networks.
/// Ensures profile photos and job inspection images load fast without consuming excessive mobile data.
class ImageCompressionUtil {
  static const int compressionThresholdBytes = 300 * 1024; // 300 KB
  static const int maxAllowedUploadSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Determine if an image file should undergo compression before upload.
  static bool shouldCompress(int fileSizeBytes) {
    return fileSizeBytes > compressionThresholdBytes;
  }

  /// Calculate the percentage of mobile data bandwidth saved after compression.
  /// Example return: '68.4%'
  static String calculateBandwidthSaved({
    required int originalBytes,
    required int compressedBytes,
  }) {
    if (originalBytes <= 0 || compressedBytes >= originalBytes) {
      return '0.0%';
    }
    final saved = ((originalBytes - compressedBytes) / originalBytes) * 100;
    return '${saved.toStringAsFixed(1)}%';
  }

  /// Return formatted file size string (e.g. '1.4 MB' or '320 KB').
  static String formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }
}
