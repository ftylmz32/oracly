/// Phase 4E.1a — H19 exact-tie representative determinism red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import '../tarot_history_test_support.dart';

void main() {
  final now = nowFixed;
  final at = now.subtract(const Duration(days: 2));

  List<TarotHistoricalReadingRecord> eligible(
    List<TarotHistoricalReadingRecord> readings,
  ) {
    return TarotHistoricalEligibility.eligibleTarotReadings(
      readings: readings,
      currentReadingId: 'cur_r',
      currentSessionId: 'cur_s',
      currentOwnerId: null,
      now: now,
      bounds: RequestBounds.defaults,
    );
  }

  List<List<T>> permutations<T>(List<T> items) {
    if (items.length <= 1) return [List<T>.from(items)];
    final out = <List<T>>[];
    for (var i = 0; i < items.length; i++) {
      final rest = [...items]..removeAt(i);
      for (final p in permutations(rest)) {
        out.add([items[i], ...p]);
      }
    }
    return out;
  }

  group('H19 exact-tie representative determinism', () {
    test('same time+readingId, different sessionId — all perms identical', () {
      final a = histReading(
        readingId: 'same_r',
        sessionId: 'sess_a',
        at: at,
        intentionSummary: 'payload-a',
      );
      final b = histReading(
        readingId: 'same_r',
        sessionId: 'sess_b',
        at: at,
        intentionSummary: 'payload-b',
      );
      // sessionId ASC → sess_a wins.
      for (final perm in permutations([a, b])) {
        final out = eligible(perm);
        expect(out, hasLength(1));
        expect(out.single.sessionId, 'sess_a');
        expect(out.single.intentionSummary, 'payload-a');
      }
    });

    test('same time+reading+session, different payload — all perms identical', () {
      final low = histReading(
        readingId: 'same_r',
        sessionId: 'same_s',
        at: at,
        spreadId: 'celtic',
        intentionSummary: 'aaa',
      );
      final high = histReading(
        readingId: 'same_r',
        sessionId: 'same_s',
        at: at,
        spreadId: 'three',
        intentionSummary: 'zzz',
      );
      // spreadId ASC → celtic before three.
      for (final perm in permutations([low, high])) {
        final out = eligible(perm);
        expect(out, hasLength(1));
        expect(out.single.spreadId, 'celtic');
        expect(out.single.intentionSummary, 'aaa');
      }
    });

    test('card-payload tie selects deterministic representative', () {
      final lowCard = histReading(
        readingId: 'same_r',
        sessionId: 'same_s',
        at: at,
        cardId: major00,
      );
      final highCard = histReading(
        readingId: 'same_r',
        sessionId: 'same_s',
        at: at,
        cardId: major06,
      );
      for (final perm in permutations([highCard, lowCard])) {
        final out = eligible(perm);
        expect(out.single.cards.single.canonicalCardId, major00);
      }
    });

    test('text-payload tie selects deterministic representative', () {
      final a = histReading(
        readingId: 'same_r',
        sessionId: 'same_s',
        at: at,
        topicId: 'career',
        intentionSummary: 'alpha',
        interpretationSummary: 'first',
        questionKind: QuestionKind.guidance,
      );
      final b = histReading(
        readingId: 'same_r',
        sessionId: 'same_s',
        at: at,
        topicId: 'love',
        intentionSummary: 'beta',
        interpretationSummary: 'second',
        questionKind: QuestionKind.relationship,
      );
      for (final perm in permutations([b, a])) {
        final out = eligible(perm);
        expect(out.single.topicId, 'career');
        expect(out.single.intentionSummary, 'alpha');
      }
    });

    test('fully identical duplicates collapse; no order dependence', () {
      final a = histReading(
        readingId: 'dup',
        sessionId: 's',
        at: at,
        intentionSummary: 'same',
      );
      final b = histReading(
        readingId: 'dup',
        sessionId: 's',
        at: at,
        intentionSummary: 'same',
      );
      for (final perm in permutations([a, b])) {
        final out = eligible(perm);
        expect(out, hasLength(1));
        expect(out.single.intentionSummary, 'same');
      }
    });

    test('downstream counts and evidence IDs stable across perms', () {
      final rows = [
        histReading(
          readingId: 'same_r',
          sessionId: 'sess_z',
          at: at,
          cardId: major00,
          intentionSummary: 'z',
        ),
        histReading(
          readingId: 'same_r',
          sessionId: 'sess_a',
          at: at,
          cardId: major00,
          intentionSummary: 'a',
        ),
      ];
      ({
        int prior,
        String cards,
        int memPrior,
        String evidenceIds,
      })
      snapshot(List<TarotHistoricalReadingRecord> input) {
        final history = TarotHistoricalSnapshot(tarotReadings: input);
        final card = TarotCardRecurrenceEngine.build(
          base: baseRequest(),
          history: history,
          currentOwnerId: null,
          now: now,
        );
        final en = TarotNarrativeRequestEnricher.enrich(
          base: baseRequest(),
          history: history,
          currentOwnerId: null,
          privacyBlocked: false,
          now: now,
        );
        return (
          prior: card.eligiblePriorReadingCount,
          cards: card.recurringCards
              .map((e) => '${e.canonicalCardId}:${e.occurrenceCount}')
              .join(','),
          memPrior: en.memory.priorReadingCount,
          evidenceIds: en.recurringCards.map((e) => e.evidenceId).join(','),
        );
      }

      final expected = snapshot(rows);
      expect(expected.prior, 1);
      expect(expected.memPrior, 1);
      expect(expected.cards, contains(':1'));
      for (final perm in permutations(rows)) {
        expect(snapshot(perm), expected);
      }
    });
  });
}
