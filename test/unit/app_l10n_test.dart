import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/services/app_notification_service.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';

void main() {
  group('AppL10n Single-Language Helper', () {
    test(
      'selectByLocale returns ONLY English for en_US and ONLY Urdu for ur_PK',
      () {
        const enText = 'No jobs posted yet';
        const urText = 'ابھی کوئی جاب نہیں';

        final resultEn = AppL10n.selectByLocale(
          const Locale('en', 'US'),
          en: enText,
          ur: urText,
        );
        expect(resultEn, equals(enText));

        final resultUr = AppL10n.selectByLocale(
          const Locale('ur', 'PK'),
          en: enText,
          ur: urText,
        );
        expect(resultUr, equals(urText));
      },
    );

    test('formatCurrency formats PKR with commas according to language', () {
      final formattedEn = AppL10n.formatCurrency(3500, isUrdu: false);
      expect(formattedEn, equals('Rs. 3,500'));

      final formattedUr = AppL10n.formatCurrency(3500, isUrdu: true);
      expect(formattedUr, equals('3,500 روپے'));
    });
  });

  group('AppNotificationMessage localizedTitle & localizedBody', () {
    test('localizedTitle returns ONLY the language of the specified locale', () {
      final notif = AppNotificationService.escrowConfirmed(3500);
      final titleEn = notif.localizedTitle(const Locale('en', 'US'));
      final titleUr = notif.localizedTitle(const Locale('ur', 'PK'));

      expect(titleEn, equals('Rs. 3500 Raast Escrow Confirmed'));
      expect(titleUr, equals('راست ایسکرو تصدیق شدہ'));
      expect(titleEn, isNot(contains('راست')));
      expect(titleUr, isNot(contains('Escrow')));
    });

    test('localizedBody returns ONLY the language of the specified locale', () {
      final notif = AppNotificationService.workerArrived('Ustad Ali');
      final bodyEn = notif.localizedBody(const Locale('en', 'US'));
      final bodyUr = notif.localizedBody(const Locale('ur', 'PK'));

      expect(bodyEn, contains('outside your location'));
      expect(bodyUr, contains('آپ کے پتے پر پہنچ چکے ہیں'));
    });
  });
}
