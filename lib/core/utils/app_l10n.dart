import 'package:flutter/material.dart';

/// Dedicated Single-Language Helper for SkillBridge.
/// Ensures users see ONLY their selected language (English OR Urdu)
/// without combining languages in UI strings or notifications.
class AppL10n {
  AppL10n._();

  /// Returns true if the current UI language is Urdu (RTL).
  static bool isUrdu(BuildContext context) {
    try {
      final directionality = Directionality.maybeOf(context);
      if (directionality == TextDirection.rtl) {
        return true;
      }
      final locale = Localizations.maybeLocaleOf(context);
      if (locale != null && locale.languageCode == 'ur') {
        return true;
      }
    } catch (_) {
      // Fallback to English if no context locale is available
      return false;
    }
    return false;
  }

  /// Selects a single string based on the active [BuildContext].
  /// Returns [ur] if Urdu is selected, otherwise [en].
  static String select(
    BuildContext context, {
    required String en,
    required String ur,
  }) {
    return isUrdu(context) ? ur : en;
  }

  /// Selects a single string based on an explicit [Locale].
  /// Returns [ur] if [locale.languageCode] is 'ur', otherwise [en].
  static String selectByLocale(
    Locale locale, {
    required String en,
    required String ur,
  }) {
    return locale.languageCode == 'ur' ? ur : en;
  }

  /// Formats Pakistani Rupee currency according to the active language.
  /// Example EN: 'Rs. 3,500' | Example UR: '3,500 روپے'
  static String formatCurrency(double amountPkr, {required bool isUrdu}) {
    final intAmount = amountPkr.toInt();
    final formattedNum = _formatWithCommas(intAmount);
    return isUrdu ? '$formattedNum روپے' : 'Rs. $formattedNum';
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
