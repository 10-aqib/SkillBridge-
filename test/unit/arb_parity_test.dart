import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every English string has an Urdu translation (and vice versa), and
/// placeholders match, so no screen falls back to a missing key.
void main() {
  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Set<String> messages(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  Set<String> placeholders(String text) =>
      // `{name}` or `{name, plural, …}` — not plural text such as `=0{No jobs}`.
      RegExp(r'\{(\w+)\s*[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

  final en = load('lib/l10n/app_en.arb');
  final ur = load('lib/l10n/app_ur.arb');

  test('en and ur have the same message keys', () {
    expect(messages(en).difference(messages(ur)), isEmpty, reason: 'missing in Urdu');
    expect(messages(ur).difference(messages(en)), isEmpty, reason: 'missing in English');
  });

  test('no empty translations', () {
    for (final k in messages(ur)) {
      expect((ur[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('placeholders match between languages', () {
    for (final k in messages(en)) {
      expect(placeholders(ur[k] as String? ?? ''), placeholders(en[k] as String), reason: k);
    }
  });
}
