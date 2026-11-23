class AppConstants {
  static const String appName = 'Skill Bridge';
  /// Shown in the side menu; keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '1.1.1';

  /// Every client and worker must add a phone number confirmed by an SMS
  /// code (Firebase phone auth) before using the app; Google sign-ins are
  /// asked right after signing in. Needs the Blaze plan for real SMS and the
  /// Phone provider enabled in the Firebase console.
  static const bool requireVerifiedPhone = true;
  static const String defaultLocale = 'en';
  static const double maxImageSizeMB = 5.0;
  static const int otpTimeoutSeconds = 60;
  static const double defaultCommissionRate = 0.10; // 10% Flat Rate (FYP Spec 2.1.7)
  static const String currencyCode = 'PKR';
  static const String currencySymbol = 'Rs';
}
