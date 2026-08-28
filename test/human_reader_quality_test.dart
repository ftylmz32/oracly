/// 20 readings with UI stripped — human, specific, not cookie copy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';

import 'human_reader_quality_samples.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('twenty readings fail the anyone-test and pass the human-test', () {
    final texts = twentyHumanReadings();
    expect(texts, hasLength(20));
    const banned = [
      'öne çıkıyor',
      'dikkat çekiyor',
      'alan açıyor',
      'hareketlilik',
      'ön plana',
      'güzel gelişmeler',
      'duyguda doğrudan ol',
      'öne çıkmak doğru',
      'sabırsızlık yüzeye',
      'zayıflık değil',
      '3 hafta',
      'kesin haber',
    ];
    final openings = <String>{};
    for (var i = 0; i < texts.length; i++) {
      final text = texts[i].toLowerCase();
      for (final phrase in banned) {
        expect(text, isNot(contains(phrase)), reason: 'reading $i: $phrase');
      }
      expect(HumanReader.looksGeneric(texts[i]), isFalse, reason: texts[i]);
      expect(text.split(RegExp(r'[.!?]+')).where((p) => p.trim().isNotEmpty).length, greaterThanOrEqualTo(1));
      openings.add(texts[i].split('.').first);
    }
    expect(openings.length, greaterThan(4));
    expect(someoneTokenHits(texts), greaterThanOrEqualTo(16));
  });
}
