import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/features/tarot/services/ritual_journal_enricher.dart';

void main() {
  test('extractKeywords finds mood words and card themes', () {
    final keywords = RitualJournalEnricher.extractKeywords(
      aiSummary: 'Umut ve huzur seninle. Sezgilerine güven.',
      cardName: 'The Star',
    );
    expect(keywords, contains('Umut'));
    expect(keywords, contains('Huzur'));
    expect(keywords.length, lessThanOrEqualTo(4));
  });

  test('excerpt shortens long interpretation text', () {
    final long = 'A' * 200;
    final excerpt = RitualJournalEnricher.excerpt(long);
    expect(excerpt.length, lessThanOrEqualTo(141));
    expect(excerpt.endsWith('…'), isTrue);
  });

  test('enrich builds journal metadata', () {
    final meta = RitualJournalEnricher.enrich(
      aiSummary: 'Ruhsal bir dönüşüm başlıyor.',
      cardName: 'Death',
    );
    expect(meta.emotionalKeywords, isNotEmpty);
    expect(meta.summaryExcerpt, isNotEmpty);
  });
}
