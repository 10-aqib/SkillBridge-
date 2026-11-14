import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light, bool rtl = false, double width = 390}) {
  final locale = rtl ? const Locale('ur') : const Locale('en');
  final theme = brightness == Brightness.light
      ? SbTheme.light(locale: locale, useGoogleFonts: false)
      : SbTheme.dark(locale: locale, useGoogleFonts: false);
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 844)),
    child: MaterialApp(
      theme: theme,
      home: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('SbTheme', () {
    test('installs SbColors extension for both modes', () {
      expect(SbTheme.light(useGoogleFonts: false).extension<SbColors>(), SbColors.light);
      expect(SbTheme.dark(useGoogleFonts: false).extension<SbColors>(), SbColors.dark);
    });

    test('brand palette matches the approved tokens', () {
      expect(SbColors.light.primary, SbBrand.inkBlue);
      expect(SbColors.light.accent, SbBrand.craftAmber);
      expect(SbColors.light.success, SbBrand.trustTeal);
      expect(SbColors.light.canvas, SbBrand.warmCanvas);
    });

    test('Urdu text theme is larger with more line height and no tracking', () {
      final en = SbTheme.light(locale: const Locale('en'), useGoogleFonts: false).textTheme.bodyMedium!;
      final ur = SbTheme.light(locale: const Locale('ur'), useGoogleFonts: false).textTheme.bodyMedium!;
      expect(ur.fontSize, greaterThan(en.fontSize!));
      expect(ur.height, greaterThan(en.height!));
      expect(ur.letterSpacing, 0);
    });

    test('font fallback puts Noto Sans before Nastaliq in both locales', () {
      // Regression: screens that name an unregistered family (e.g. 'Inter')
      // rendered Latin text in Nastaliq's serif glyphs when Nastaliq came first.
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final locale in const [Locale('en'), Locale('ur')]) {
        final fallback = SbTheme.light(locale: locale).textTheme.bodyMedium!.fontFamilyFallback!;
        expect(fallback.first, startsWith('NotoSans'), reason: 'locale ${locale.languageCode}');
        expect(fallback.last, startsWith('NotoNastaliqUrdu'));
      }
    });

    test('window size classes follow the 600 / 1024 breakpoints', () {
      expect(SbWindowSize.fromWidth(390), SbWindowSize.compact);
      expect(SbWindowSize.fromWidth(600), SbWindowSize.medium);
      expect(SbWindowSize.fromWidth(1023), SbWindowSize.medium);
      expect(SbWindowSize.fromWidth(1024), SbWindowSize.expanded);
    });
  });

  group('SbButton', () {
    testWidgets('regular buttons are at least 48dp tall', (tester) async {
      await tester.pumpWidget(_host(SbButton(label: 'Post a job', onPressed: () {})));
      expect(tester.getSize(find.byType(SbButton)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('loading disables taps and keeps the label width', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(Center(
        child: SbButton(label: 'Send proposal', isLoading: true, onPressed: () => taps++),
      )));
      await tester.tap(find.byType(SbButton), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    for (final b in Brightness.values) {
      testWidgets('all variants render in ${b.name} mode', (tester) async {
        await tester.pumpWidget(_host(
          Column(children: [
            for (final v in SbButtonVariant.values) SbButton(label: v.name, variant: v, onPressed: () {}),
            const SbButton(label: 'disabled', onPressed: null),
          ]),
          brightness: b,
        ));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Cards', () {
    testWidgets('worker card hides rating when there are no reviews', (tester) async {
      await tester.pumpWidget(_host(const SbWorkerCard(
        name: 'Test Worker',
        trade: 'Electrician',
        newProfileLabel: 'New profile',
      )));
      expect(find.text('New profile'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    });

    testWidgets('worker card shows verified only when labelled', (tester) async {
      await tester.pumpWidget(_host(const SbWorkerCard(
        name: 'Test Worker',
        trade: 'Plumber',
        verifiedLabel: 'Verified',
        rating: 4.8,
        reviewsLabel: '12',
      )));
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('cards lay out right-to-left in Urdu without overflow', (tester) async {
      await tester.pumpWidget(_host(
        const Column(children: [
          SbWorkerCard(
            name: 'ٹیسٹ کاریگر',
            trade: 'الیکٹریشن',
            rateLabel: 'ریٹ پوچھیں',
            availabilityLabel: 'دستیاب',
            isAvailable: true,
          ),
          SbJobCard(
            title: 'پنکھا لگوانا ہے',
            category: 'بجلی',
            locationLabel: 'جی-11',
            budgetLabel: 'Rs 2,000',
            urgentLabel: 'فوری',
          ),
        ]),
        rtl: true,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(SbWorkerCard));
      final avatar = tester.getRect(find.byType(SbAvatar));
      expect(avatar.center.dx, greaterThan(card.center.dx), reason: 'avatar should sit on the right in RTL');
    });
  });

  group('States', () {
    testWidgets('empty, error and offline states are visually distinct', (tester) async {
      await tester.pumpWidget(_host(Column(children: [
        SbStateView(kind: SbStateKind.empty, title: 'No jobs yet', actionLabel: 'Post a job', onAction: () {}),
        SbStateView(kind: SbStateKind.error, title: 'Could not load', actionLabel: 'Retry', onAction: () {}),
        const SbStateView(kind: SbStateKind.offline, title: 'You are offline'),
      ])));
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('adaptive scaffold switches bottom bar to rail at 600dp', (tester) async {
      Widget shell(double w) => MediaQuery(
            data: MediaQueryData(size: Size(w, 900)),
            child: MaterialApp(
              theme: SbTheme.light(useGoogleFonts: false),
              home: SbAdaptiveScaffold(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                body: const SizedBox(),
                destinations: const [
                  SbNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
                  SbNavDestination(icon: Icons.work_outline, selectedIcon: Icons.work, label: 'Jobs'),
                ],
              ),
            ),
          );
      await tester.pumpWidget(shell(390));
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.pumpWidget(shell(800));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
