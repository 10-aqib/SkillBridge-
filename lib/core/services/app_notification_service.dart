import 'dart:ui';

/// Represents a bilingual (English / Urdu) notification for Pakistani users.
class AppNotificationMessage {
  final String titleEn;
  final String titleUr;
  final String bodyEn;
  final String bodyUr;

  const AppNotificationMessage({
    required this.titleEn,
    required this.titleUr,
    required this.bodyEn,
    required this.bodyUr,
  });

  /// Formats the notification title as bilingual English • اردو
  String formatBilingualTitle() => '$titleEn • $titleUr';

  /// Formats the notification body as bilingual English • اردو
  String formatBilingualBody() => '$bodyEn \n$bodyUr';

  /// Returns ONLY English title if locale is English, OR ONLY Urdu title if Urdu.
  String localizedTitle(Locale locale) {
    return locale.languageCode == 'ur' ? titleUr : titleEn;
  }

  /// Returns ONLY English body if locale is English, OR ONLY Urdu body if Urdu.
  String localizedBody(Locale locale) {
    return locale.languageCode == 'ur' ? bodyUr : bodyEn;
  }
}

/// Service for generating and triggering Pakistani bilingual
/// push and in-app notifications.
class AppNotificationService {
  /// Notification when Raast Escrow funds are locked safely.
  static AppNotificationMessage escrowConfirmed(double amountPkr) {
    final amountFormatted = 'Rs. ${amountPkr.toInt()}';
    return AppNotificationMessage(
      titleEn: '$amountFormatted Raast Escrow Confirmed',
      titleUr: 'راست ایسکرو تصدیق شدہ',
      bodyEn:
          'Your $amountFormatted payment is securely locked in escrow until you verify completion.',
      bodyUr:
          'آپ کی رقم ایسکرو میں محفوظ ہے اور کام کی تصدیق کے بعد جاری ہوگی۔',
    );
  }

  /// Notification when worker GPS tracking detects arrival.
  static AppNotificationMessage workerArrived(String workerName) {
    return AppNotificationMessage(
      titleEn: '$workerName Arrived at Location',
      titleUr: 'استاد آپ کے پتے پر پہنچ گئے',
      bodyEn:
          '$workerName is outside your location. Please check your door or call via app.',
      bodyUr:
          '$workerName آپ کے پتے پر پہنچ چکے ہیں، براہ کرم ان سے رابطہ کریں۔',
    );
  }

  /// Notification for 4-Digit Job Completion Sign-Off OTP.
  static AppNotificationMessage otpSignoffRequired(String jobId) {
    return AppNotificationMessage(
      titleEn: '4-Digit OTP Sign-Off Required',
      titleUr: 'جاب مکمل کرنے کا کوڈ',
      bodyEn:
          'Share your 4-digit verification code with the worker to finalize job and release escrow.',
      bodyUr:
          'کام مکمل ہونے پر 4 ہندسوں کا کوڈ کاریگر کو فراہم کریں تاکہ رقم جاری کی جا سکے۔',
    );
  }

  /// Notification when a worker submits a proposal/bid on a job.
  static AppNotificationMessage proposalReceived(
    String workerName,
    double amountPkr,
  ) {
    final amountFormatted = 'Rs. ${amountPkr.toInt()}';
    return AppNotificationMessage(
      titleEn: 'New Bid of $amountFormatted from $workerName',
      titleUr: '$workerName کی طرف سے نئی پیشکش',
      bodyEn:
          '$workerName has submitted an estimate for your job. Tap to review profile and rating.',
      bodyUr:
          '$workerName نے آپ کے کام کے لیے ایسٹیمیٹ بھیجا ہے۔ ریٹنگ اور پروفائل دیکھنے کے لیے کلک کریں۔',
    );
  }
}
