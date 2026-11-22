import 'package:flutter/services.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

/// Status of an identity verification (server-controlled values).
enum IdentityStatus {
  notStarted,
  consentPending,
  pending,
  capturing,
  submitted,
  processing,
  verified,
  rejected,
  failed,
  manualReview,
  expired,
  cancelled;

  static IdentityStatus parse(Object? raw) => switch (raw) {
        'consent_pending' => consentPending,
        'pending' => pending,
        'capturing' => capturing,
        'submitted' => submitted,
        'processing' => processing,
        'verified' => verified,
        'rejected' => rejected,
        'failed' => failed,
        'manual_review' => manualReview,
        'expired' => expired,
        'cancelled' => cancelled,
        _ => notStarted,
      };

  bool get isFinal => const {verified, rejected, failed, manualReview, expired, cancelled}.contains(this);
}

/// Which identity badge a profile may show. Each has its own meaning:
/// * [nadraVerified]: an authentic, successful NADRA fingerprint check
///   (server-set `verified: true`, provider `nadra`, not a test);
/// * [testVerification]: a simulated success in the test environment only;
///   never a real verification;
/// * [documentReviewed]: staff reviewed the person's ID documents (the
///   older manual review); not a NADRA check.
enum IdentityBadge { nadraVerified, testVerification, documentReviewed }

/// The identity state of a person, from their account or public profile.
class IdentityState {
  const IdentityState({required this.status, required this.verified, required this.provider, required this.test, this.verifiedAt});

  final IdentityStatus status;

  /// True only for an authentic NADRA verification (set by the server).
  final bool verified;
  final String provider;
  final bool test;
  final DateTime? verifiedAt;

  static const none = IdentityState(status: IdentityStatus.notStarted, verified: false, provider: '', test: false);

  factory IdentityState.fromMap(Map<String, dynamic>? m) {
    if (m == null) return none;
    final at = m['verifiedAt'];
    DateTime? when;
    try {
      when = at == null ? null : (at as dynamic).toDate() as DateTime;
    } catch (_) {
      when = null;
    }
    final status = IdentityStatus.parse(m['status']);
    final provider = m['provider'] is String ? m['provider'] as String : '';
    final test = m['test'] == true;
    return IdentityState(
      status: status,
      // Defence in depth: "verified" needs the real provider and no test flag.
      verified: m['verified'] == true && provider == 'nadra' && !test && status == IdentityStatus.verified,
      provider: provider,
      test: test,
      verifiedAt: when,
    );
  }

  factory IdentityState.of(UserEntity? user) => IdentityState.fromMap(user?.identityVerification);
}

/// Badges for a person: NADRA (or test) and, separately, document review.
List<IdentityBadge> identityBadgesFor(UserEntity? user) {
  if (user == null) return const [];
  final s = IdentityState.of(user);
  return [
    if (s.verified) IdentityBadge.nadraVerified,
    if (!s.verified && s.test && s.status == IdentityStatus.verified) IdentityBadge.testVerification,
    if (user.isCnicVerified || (user.workerProfile?.isVerified ?? false)) IdentityBadge.documentReviewed,
  ];
}

/// CNIC format checks and display (CNICValidationService). A valid format
/// proves nothing about the person: only NADRA's check does.
abstract final class CnicValidation {
  static final _formatted = RegExp(r'^\d{5}-\d{7}-\d$');

  /// Digits only.
  static String digitsOf(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// XXXXX-XXXXXXX-X for up to 13 digits (partial while typing).
  static String format(String digits) {
    final d = digits.length > 13 ? digits.substring(0, 13) : digits;
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 5 || i == 12) b.write('-');
      b.write(d[i]);
    }
    return b.toString();
  }

  /// True for a complete, plausible CNIC (13 digits, not starting with 0,
  /// not one repeated digit).
  static bool isValid(String input) {
    final d = digitsOf(input);
    if (d.length != 13 || !_formatted.hasMatch(format(d))) return false;
    if (d.startsWith('0')) return false;
    if (RegExp(r'^(\d)\1{12}$').hasMatch(d)) return false;
    return true;
  }

  /// 35202-•••••••-1
  static String mask(String input) {
    final d = digitsOf(input);
    if (d.length != 13) return '';
    return '${d.substring(0, 5)}-•••••••-${d.substring(12)}';
  }

  /// Synthetic identities accepted by the test simulator only.
  static const syntheticTestCnics = <(String, String)>[
    ('99999-0000001-1', 'Simulated successful match'),
    ('99999-0000002-2', 'Simulated fingerprint mismatch'),
    ('99999-0000003-3', 'Simulated CNIC mismatch'),
    ('99999-0000004-4', 'Simulated NADRA service unavailable'),
    ('99999-0000005-5', 'Simulated NADRA timeout'),
    ('99999-0000006-6', 'Simulated additional review'),
  ];
}

/// Formats typing into XXXXX-XXXXXXX-X, digits only, 13 at most.
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = CnicValidation.digitsOf(newValue.text);
    final text = CnicValidation.format(digits);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
