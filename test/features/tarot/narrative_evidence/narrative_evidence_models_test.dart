import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_00.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_profile_slice.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';

void main() {
  group('RequestBounds', () {
    test('exact defaults 20 / 5 / 12 / 800 / 4; no 90-day field', () {
      const b = RequestBounds.defaults;
      expect(b.maxPriorReadingsScanned, 20);
      expect(b.maxRecurringOccurrencesListed, 5);
      expect(b.maxRelationships, 12);
      expect(b.maxMemoryChars, 800);
      expect(b.maxThemeLabels, 4);
    });
  });

  group('Empty memory / recurrence firewall', () {
    test('empty memory shell', () {
      const m = TarotNarrativeMemoryEvidence.empty;
      expect(m.included, isFalse);
      expect(m.omitReason, 'empty');
      expect(m.entries, isEmpty);
      expect(m.priorReadingCount, 0);
      expect(m.recentCardNames, isEmpty);
      expect(m.recurringThemeLabels, isEmpty);
    });
  });

  group('TarotNarrativeRequest safe empty components', () {
    test('request with empty relationships / memory / recurrence', () {
      final question = NarrativeQuestionGrounding.from(
        rawQuestion: 'Should I leave this job?',
      );
      final spread = ClassicalSpreadSemantics.byLegacyTypeName('single');
      final slice = TarotNarrativeProfileSlice.fromProfile(
        kNarrativeMajor00,
        isReversed: false,
        questionKind: question.kind,
      );
      final card = TarotNarrativeCardEvidence(
        canonicalCardId: kNarrativeMajor00.canonicalCardId,
        ritualCardId: 0,
        isReversed: false,
        positionKey: 'sign',
        positionIndex: 0,
        displayName: 'The Fool',
        profileSlice: slice,
        imageAsset: 'assets/test.png',
      );

      final request = TarotNarrativeRequest(
        narrativeTarotVersion: TarotNarrativeRequest.currentNarrativeVersion,
        languageCode: 'en',
        sessionId: 's1',
        readingId: 'r1',
        question: question,
        spread: spread,
        cards: [card],
        relationships: const [],
        memory: TarotNarrativeMemoryEvidence.empty,
        recurringCards: const [],
        recurringThemes: const [],
        bounds: RequestBounds.defaults,
      );

      expect(request.narrativeTarotVersion, 2);
      expect(request.relationships, isEmpty);
      expect(request.memory.included, isFalse);
      expect(request.recurringCards, isEmpty);
      expect(request.recurringThemes, isEmpty);
      expect(request.cards.single.ritualCardId, 0);
    });
  });
}
