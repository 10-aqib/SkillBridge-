class AppConstants {
  static const String appName = 'Skill Bridge';
  /// Shown in the side menu; keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '1.2.0';

  /// Staff sign-in addresses. They can't be reset with "Forgot password"
  /// (in the app or on the admin website); the owner changes them with
  /// super_admin_web/create-admin.js. They also have no real mailbox, so a
  /// reset link could never be delivered anyway.
  static const Set<String> staffEmails = {'skillbridge@admin'};

  static bool isStaffEmail(String? email) => staffEmails.contains(email?.trim().toLowerCase());

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
