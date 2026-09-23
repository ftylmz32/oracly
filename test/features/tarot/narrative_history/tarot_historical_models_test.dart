import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

void main() {
  group('TarotHistorical models', () {
    test('defensive immutable cards / readings', () {
      final cards = [
        const TarotHistoricalCardOccurrence(
          canonicalCardId: 'major_00',
          isReversed: false,
        ),
      ];
      final record = TarotHistoricalReadingRecord(
        readingId: 'r1',
        occurredAt: DateTime.utc(2026, 1, 1),
        spreadId: 'single',
        topicId: 'ilişki',
        cards: cards,
      );
      final snap = TarotHistoricalSnapshot(tarotReadings: [record]);

      expect(() => record.cards.add(cards.first), throwsUnsupportedError);
      expect(() => snap.tarotReadings.add(record), throwsUnsupportedError);
      expect(record.topicId, 'ilişki');
      expect(record.cards.single.orientationKnown, isTrue);
    });

    test('unknown orientation sentinel', () {
      const occ = TarotHistoricalCardOccurrence(
        canonicalCardId: 'major_00',
        isReversed: false,
        orientationKnown: false,
      );
      expect(occ.orientationKnown, isFalse);
      // isReversed=false is inert — not factual upright.
      expect(occ.isReversed, isFalse);
    });
  });
}
