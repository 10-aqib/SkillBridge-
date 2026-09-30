import 'package:flutter/material.dart';

/// Dedicated Single-Language Helper for SkillBridge.
/// Ensures users see ONLY their selected language (English OR Urdu)
/// without combining languages in UI strings or notifications.
class AppL10n {
  AppL10n._();

  /// App is strictly English-only. Always returns false.
  static bool isUrdu(BuildContext context) => false;

  /// Selects a single string based on the active [BuildContext].
  /// App is English-only, so this always returns [en].
  static String select(
    BuildContext context, {
    required String en,
    required String ur,
  }) => en;

  /// Selects a single string based on an explicit [Locale].
  /// App is English-only, so this always returns [en].
  static String selectByLocale(
    Locale locale, {
    required String en,
    required String ur,
  }) => en;

  /// Formats Pakistani Rupee currency in English format (e.g. 'Rs. 3,500').
  static String formatCurrency(double amountPkr, {bool isUrdu = false}) {
    final intAmount = amountPkr.toInt();
    final formattedNum = _formatWithCommas(intAmount);
    return 'Rs. $formattedNum';
  }

  static String _formatWithCommas(int value) {
    final str = value.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
