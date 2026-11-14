import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/services/profile_media_service.dart';

/// Upload file names must be creatable on every platform.
/// (`nextInt(1 << 32)` passed on the VM but threw on the web, where `1 << 32`
/// is 0, so every web upload failed.)
void main() {
  test('upload name suffix works and varies', () {
    final suffixes = {for (var i = 0; i < 50; i++) ProfileMediaService.uniqueSuffix()};
    expect(suffixes.every((s) => RegExp(r'^[0-9a-z]+$').hasMatch(s)), isTrue);
    expect(suffixes.length, greaterThan(40));
  });
}
