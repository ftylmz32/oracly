/// Phase 6E — same-spread-alone + wrong-owner history firewalls.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_classical_shadow.dart';

import '../narrative_history/tarot_history_test_support.dart';
import 'narrative_shadow_test_support.dart';

void main() {
  final now = nowFixed;

  test('same-spread-alone does not authorize recurrence', () {
    final result = NarrativeTarotClassicalShadow.evaluate(
      session: relationshipSingleSession(),
      readingId: 'read_same_spread',
      languageCode: 'en',
      history: TarotHistoricalSnapshot(
        tarotReadings: [
          histReading(
            readingId: 'h_same',
            at: now.subtract(const Duration(days: 2)),
            spreadId: 'classical.single',
            cardId: 'major_21',
            questionKind: QuestionKind.relationship,
          ),
        ],
      ),
      now: now,
    );
    expect(result.isPass, isTrue);
    expect(result.finalNarrativeRequest!.recurringCards, isEmpty);
  });

  test('wrong-owner history does not enrich', () {
    final result = NarrativeTarotClassicalShadow.evaluate(
      session: relationshipSingleSession(),
      readingId: 'read_owner',
      languageCode: 'en',
      currentOwnerId: 'owner_self',
      history: TarotHistoricalSnapshot(
        tarotReadings: [
          histReading(
            readingId: 'h_o1',
            at: now.subtract(const Duration(days: 2)),
            cardId: major00,
            ownerId: 'owner_other',
            questionKind: QuestionKind.relationship,
            intentionSummary: 'relationship loyalty partner stay',
          ),
          histReading(
            readingId: 'h_o2',
            at: now.subtract(const Duration(days: 3)),
            cardId: major00,
            ownerId: 'owner_other',
            questionKind: QuestionKind.relationship,
            intentionSummary: 'relationship loyalty partner stay',
          ),
        ],
      ),
      now: now,
    );
    expect(result.isPass, isTrue);
    expect(result.finalNarrativeRequest!.recurringCards, isEmpty);
  });
}
