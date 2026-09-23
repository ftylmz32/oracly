/// Phase 4D — TarotNarrativeRequestEnricher unit tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import 'tarot_history_test_support.dart';
import 'tarot_narrative_request_enricher_fixtures.dart';

void main() {
  final now = nowFixed;

  group('TarotNarrativeRequestEnricher', () {
    test('normal composition fills Phase 4 fields only', () {
      final base = baseRequest();
      final history = enricherRichHistory(base, now);
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: history,
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(identical(out.question, base.question), isTrue);
      expect(identical(out.spread, base.spread), isTrue);
      expect(identical(out.cards, base.cards), isTrue);
      expect(identical(out.relationships, base.relationships), isTrue);
      expect(identical(out.bounds, base.bounds), isTrue);
      expect(out.narrativeTarotVersion, base.narrativeTarotVersion);
      expect(out.languageCode, base.languageCode);
      expect(out.sessionId, base.sessionId);
      expect(out.readingId, base.readingId);
      expect(out.recurringCards, isNotEmpty);
      expect(out.recurringThemes, isNotEmpty);
      expect(out.memory.included, isTrue);
      expect(out.memory.omitReason, 'included');
      expect(out.memory.priorReadingCount, 2);
      expect(out.memory.recentCardNames, isEmpty);
      expect(out.memory.recurringThemeLabels, isEmpty);
    });

    test('privacy short-circuit wipes history engines', () {
      final base = baseRequest();
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: enricherRichHistory(base, now),
        currentOwnerId: null,
        privacyBlocked: true,
        now: now,
      );
      expect(out.memory.omitReason, 'privacy');
      expect(out.memory.included, isFalse);
      expect(out.memory.priorReadingCount, 0);
      expect(out.memory.entries, isEmpty);
      expect(out.recurringCards, isEmpty);
      expect(out.recurringThemes, isEmpty);
      expect(identical(out.cards, base.cards), isTrue);
    });

    test('empty history → no_history + empty recurrence', () {
      final base = baseRequest();
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: TarotHistoricalSnapshot(tarotReadings: const []),
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(out.memory.omitReason, 'no_history');
      expect(out.memory.priorReadingCount, 0);
      expect(out.recurringCards, isEmpty);
      expect(out.recurringThemes, isEmpty);
    });

    test('priorReadingCount handoff equals eligible Tarot scan', () {
      final base = baseRequest();
      final history = TarotHistoricalSnapshot(
        tarotReadings: [
          for (var i = 1; i <= 3; i++)
            histReading(
              readingId: 'h$i',
              at: now.subtract(Duration(days: i)),
              cardId: major01,
            ),
        ],
      );
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: history,
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(out.memory.priorReadingCount, 3);
      expect(out.recurringCards, isEmpty);
      expect(out.memory.omitReason, 'empty');
    });
  });
}
