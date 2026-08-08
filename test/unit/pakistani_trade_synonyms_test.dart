import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/utils/pakistani_trade_synonyms.dart';

void main() {
  group('PakistaniTradeSynonyms', () {
    test('matches Roman Urdu keywords to official categories', () {
      expect(
        PakistaniTradeSynonyms.matchCategory('bijli ki taar kharab hai'),
        equals('Electrician'),
      );
      expect(
        PakistaniTradeSynonyms.matchCategory('nalka leak ho raha hai'),
        equals('Plumber'),
      );
      expect(
        PakistaniTradeSynonyms.matchCategory('ac cooling nahi kar raha'),
        equals('AC Technician'),
      );
      expect(
        PakistaniTradeSynonyms.matchCategory('lakri ka darwaza toot gaya'),
        equals('Carpenter'),
      );
      expect(
        PakistaniTradeSynonyms.matchCategory('kamre me rang karna hai'),
        equals('Painter'),
      );
    });

    test('suggests fair Pakistani market PKR budget ranges', () {
      final range = PakistaniTradeSynonyms.suggestBudgetRange('Electrician');
      expect(range.minPkr, equals(1500));
      expect(range.maxPkr, equals(4000));
    });
  });
}
