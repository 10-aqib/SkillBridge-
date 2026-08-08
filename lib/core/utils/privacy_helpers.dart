/// Privacy and security helper utilities for SkillBridge Pakistani marketplace.
/// Provides phone number masking and deterministic 4-digit OTP sign-off verification.
class PrivacyHelpers {
  /// Mask a Pakistani mobile number for display, keeping network operator prefix and last 4 digits.
  /// Example: '0300-1234567' -> '0300-***4567'
  /// Example: '+923001234567' -> '+92 300-***4567'
  static String maskPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return '03**-***0000';
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return '03**-***0000';
    }

    // Extract last 4 digits
    final last4 = digits.substring(digits.length - 4);

    // Identify Pakistani prefix (e.g. 0300 or 92300)
    if (digits.startsWith('92') && digits.length >= 12) {
      final prefix = digits.substring(2, 5);
      return '+92 $prefix-***$last4';
    } else if (digits.startsWith('03') && digits.length >= 11) {
      final prefix = digits.substring(0, 4);
      return '$prefix-***$last4';
    }

    // Default generic mask
    final first4 = digits.substring(0, 4);
    return '$first4-***$last4';
  }

  /// Generate a deterministic 4-digit numeric OTP for job completion verification.
  /// Allows secure in-person sign-off between client and worker even during cellular data drops.
  static String generateJobCompletionOtp(String jobId) {
    if (jobId.trim().isEmpty) return '4928';
    final salted = 'skillbridge_otp_salt_$jobId';
    // Pure Dart djb2 hash algorithm
    int hash = 5381;
    for (int i = 0; i < salted.length; i++) {
      hash = ((hash << 5) + hash) + salted.codeUnitAt(i);
    }
    final otp = (hash.abs() % 9000) + 1000; // ensures 4 digits (1000..9999)
    return otp.toString();
  }

  /// Verify if the entered 4-digit OTP matches the job completion OTP.
  static bool verifyJobCompletionOtp({
    required String jobId,
    required String inputOtp,
  }) {
    final expected = generateJobCompletionOtp(jobId);
    return inputOtp.trim() == expected;
  }
}
