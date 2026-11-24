class AppConstants {
  static const String appName = 'Skill Bridge';
  /// Shown in the side menu; keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '1.2.0';

  /// Staff sign in with a username such as `skillbridge@admin` (no ".com"),
  /// not an email. Firebase only accepts real email addresses, so a username
  /// is turned into an internal address on the project's own Firebase domain
  /// (`skillbridge.admin@skill-bridge-c68c3.firebaseapp.com`). That domain
  /// has no mailbox, and "Forgot password" refuses staff usernames, so a staff
  /// password can only be changed by the owner (super_admin_web/create-admin.js,
  /// which uses the same rule).
  static const String staffEmailDomain = 'skill-bridge-c68c3.firebaseapp.com';
  static final RegExp _staffUsername = RegExp(r'^[a-z0-9._-]{2,40}@[a-z0-9-]{2,30}$');

  /// The internal sign-in address for a staff [username], or null when the
  /// input isn't a staff username (for example a normal email address).
  static String? staffEmailForUsername(String? username) {
    final v = username?.trim().toLowerCase() ?? '';
    if (!_staffUsername.hasMatch(v)) return null;
    return '${v.replaceAll('@', '.')}@$staffEmailDomain';
  }

  /// What to sign in with: a staff username becomes its internal address;
  /// anything else is used as typed (trimmed).
  static String signInEmail(String input) => staffEmailForUsername(input) ?? input.trim();

  /// A staff username, or a staff internal address.
  static bool isStaffEmail(String? input) {
    final v = input?.trim().toLowerCase() ?? '';
    return staffEmailForUsername(v) != null || v.endsWith('@$staffEmailDomain');
  }

  /// Every client and worker must add a phone number confirmed by an SMS
  /// code (Firebase phone auth) before using the app; Google sign-ins are
  /// asked right after signing in. Needs the Blaze plan for real SMS and the
  /// Phone provider enabled in the Firebase console.
  /// Back on since 23 Nov 2026 (billing linked, SHA-256 registered). People
  /// can still tap "Add later" and add the number from their profile.
  static const bool requireVerifiedPhone = true;
  static const String defaultLocale = 'en';
  static const double maxImageSizeMB = 5.0;
  static const int otpTimeoutSeconds = 60;
  static const double defaultCommissionRate = 0.10; // 10% Flat Rate (FYP Spec 2.1.7)
  static const String currencyCode = 'PKR';
  static const String currencySymbol = 'Rs';
}
