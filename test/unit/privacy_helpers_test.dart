import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/utils/privacy_helpers.dart';

void main() {
  group('PrivacyHelpers', () {
    test('maskPhone formats Pakistani 03xx numbers correctly', () {
      expect(PrivacyHelpers.maskPhone('0300-1234567'), equals('0300-***4567'));
      expect(PrivacyHelpers.maskPhone('03211234567'), equals('0321-***4567'));
      expect(PrivacyHelpers.maskPhone('+923001234567'), equals('+92 300-***4567'));
      expect(PrivacyHelpers.maskPhone(null), equals('03**-***0000'));
      expect(PrivacyHelpers.maskPhone(''), equals('03**-***0000'));
    });

    test('generateJobCompletionOtp produces a 4-digit numeric code', () {
      final otp1 = PrivacyHelpers.generateJobCompletionOtp('job_12345');
      expect(otp1.length, equals(4));
      expect(int.tryParse(otp1), isNotNull);

      // Deterministic
      final otp2 = PrivacyHelpers.generateJobCompletionOtp('job_12345');
      expect(otp1, equals(otp2));
    });

    test('verifyJobCompletionOtp validates correctly', () {
      final otp = PrivacyHelpers.generateJobCompletionOtp('job_abc');
      expect(
        PrivacyHelpers.verifyJobCompletionOtp(
          jobId: 'job_abc',
          inputOtp: otp,
        ),
        isTrue,
      );
      expect(
        PrivacyHelpers.verifyJobCompletionOtp(
          jobId: 'job_abc',
          inputOtp: '9999_wrong',
        ),
        isFalse,
      );
    });
  });
}
