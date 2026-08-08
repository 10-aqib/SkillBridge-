import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  // Numeric only formatter
  static TextInputFormatter get digitsOnly => FilteringTextInputFormatter.digitsOnly;

  // Decimal (double) formatter
  static TextInputFormatter get decimal => FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'));

  // Pakistan phone number formatter (format input as 03xx-xxxxxxx or +92 3xx-xxxxxxx)
  static TextInputFormatter get pakistanPhone {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.length > oldValue.text.length) {
        if (text.length == 4 && !text.startsWith('+92')) {
          return TextEditingValue(
            text: '$text-',
            selection: const TextSelection.collapsed(offset: 5),
          );
        }
      }
      return newValue;
    });
  }

  /// Formats monetary amount as Pakistani Rupees (PKR) e.g. "Rs. 25,000"
  static String formatPkr(num amount) {
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Formats monetary amount compactly e.g. "Rs. 2.5K" or "Rs. 1.2M"
  static String formatPkrCompact(num amount) {
    if (amount >= 1000000) {
      return 'Rs. ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs. ${amount.toInt()}';
  }

  /// Formats date cleanly for Pakistani locale
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Formats relative time (e.g. "2h ago", "Just now")
  static String formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }
}
