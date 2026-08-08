import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/config/theme/outdoor_theme_mode.dart';

void main() {
  group('OutdoorThemeMode High-Contrast Test', () {
    test('OutdoorThemeColors provide maximum contrast', () {
      expect(OutdoorThemeColors.background, const Color(0xFFFFFFFF));
      expect(OutdoorThemeColors.text, const Color(0xFF000000));
      expect(OutdoorThemeColors.border, const Color(0xFF0A0E1A));
    });

    testWidgets(
      'OutdoorThemeMode.themeData has high-contrast borders and bold typography',
      (tester) async {
        final theme = OutdoorThemeMode.themeData;
        expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.side.width, 2.0);
        expect(shape.side.color, OutdoorThemeColors.border);
      },
    );

    testWidgets('isOutdoorModeProvider toggles cleanly in ProviderContainer', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isOutdoorModeProvider), isFalse);

      container.read(isOutdoorModeProvider.notifier).toggle();
      expect(container.read(isOutdoorModeProvider), isTrue);

      container.read(isOutdoorModeProvider.notifier).setOutdoorMode(false);
      expect(container.read(isOutdoorModeProvider), isFalse);
    });
  });
}
