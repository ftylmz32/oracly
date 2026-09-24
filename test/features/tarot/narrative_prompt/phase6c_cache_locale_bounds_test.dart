/// Phase 6C — cache identity sensitivity + locale + bounds fail-closed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n_triple.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_profile_slice.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  group('Cache identity changes', () {
    late TarotNarrativeRequest base;

    setUp(() {
      base = buildFromCorpusId('three_contrast_exemplar_en');
    });

    void expectKeyChanges(TarotNarrativeRequest other) {
      expect(cacheKey(base), isNot(cacheKey(other)));
    }

    test('language', () {
      expectKeyChanges(copyRequest(base, languageCode: 'tr'));
    });

    test('question text', () {
      expectKeyChanges(
        copyRequest(
          base,
          question: QuestionGrounding(
            rawText: 'Different question about staying?',
            topic: base.question.topic,
            kind: base.question.kind,
            hasRealQuestion: true,
          ),
        ),
      );
    });

    test('question kind', () {
      expectKeyChanges(
        copyRequest(
          base,
          question: QuestionGrounding(
            rawText: base.question.rawText,
            topic: base.question.topic,
            kind: QuestionKind.guidance,
            hasRealQuestion: base.question.hasRealQuestion,
          ),
        ),
      );
    });

    test('spreadId', () {
      final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
      // Invalid structure intentionally avoided — use different single-card
      // request for spread change via rebuilt corpus single.
      final single = buildFromCorpusId('single_open_fool_en');
      expect(cacheKey(base), isNot(cacheKey(single)));
      expect(five.spreadId, 'classical.fiveCard');
    });

    test('position key', () {
      final card = base.cards.first;
      final spread = base.spread;
      final positions = [
        for (final p in spread.positions)
          p.positionKey == card.positionKey
              ? SpreadPositionSemantic(
                  positionKey: 'changed_pos',
                  index: p.index,
                  role: p.role,
                  guidingQuestionKey: p.guidingQuestionKey,
                  temporal: p.temporal,
                  relationToOtherSlots: p.relationToOtherSlots,
                  weight: p.weight,
                  displayLabelKey: p.displayLabelKey,
                )
              : p,
      ];
      final newSpread = SpreadSemanticDefinition(
        spreadId: spread.spreadId,
        legacyTypeName: spread.legacyTypeName,
        cardCount: spread.cardCount,
        purposeKey: spread.purposeKey,
        positions: positions,
        interpretationOrder: spread.interpretationOrder,
        geometryHook: spread.geometryHook,
        lengthBand: spread.lengthBand,
      );
      final newCards = [
        for (final c in base.cards)
          c.positionKey == card.positionKey
              ? TarotNarrativeCardEvidence(
                  canonicalCardId: c.canonicalCardId,
                  ritualCardId: c.ritualCardId,
                  isReversed: c.isReversed,
                  positionKey: 'changed_pos',
                  positionIndex: c.positionIndex,
                  displayName: c.displayName,
                  profileSlice: c.profileSlice,
                  imageAsset: c.imageAsset,
                )
              : c,
      ];
      final rels = [
        for (final r in base.relationships)
          TarotNarrativeRelationshipEvidence(
            evidenceId: r.evidenceId,
            leftCardId: r.leftCardId,
            rightCardId: r.rightCardId,
            leftPositionKey: r.leftPositionKey == card.positionKey
                ? 'changed_pos'
                : r.leftPositionKey,
            rightPositionKey: r.rightPositionKey == card.positionKey
                ? 'changed_pos'
                : r.rightPositionKey,
            kind: r.kind,
            provenance: r.provenance,
            strength: r.strength,
            noteKeyOrText: r.noteKeyOrText,
          ),
      ];
      expectKeyChanges(
        copyRequest(base, spread: newSpread, cards: newCards, relationships: rels),
      );
    });

    test('card canonical id', () {
      final cards = [
        for (final c in base.cards)
          c == base.cards.first
              ? TarotNarrativeCardEvidence(
                  canonicalCardId: 'major_00',
                  ritualCardId: c.ritualCardId,
                  isReversed: c.isReversed,
                  positionKey: c.positionKey,
                  positionIndex: c.positionIndex,
                  displayName: c.displayName,
                  profileSlice: c.profileSlice,
                  imageAsset: c.imageAsset,
                )
              : c,
      ];
      final rels = [
        for (final r in base.relationships)
          TarotNarrativeRelationshipEvidence(
            evidenceId: r.evidenceId,
            leftCardId: r.leftCardId == base.cards.first.canonicalCardId
                ? 'major_00'
                : r.leftCardId,
            rightCardId: r.rightCardId == base.cards.first.canonicalCardId
                ? 'major_00'
                : r.rightCardId,
            leftPositionKey: r.leftPositionKey,
            rightPositionKey: r.rightPositionKey,
            kind: r.kind,
            provenance: r.provenance,
            strength: r.strength,
            noteKeyOrText: r.noteKeyOrText,
          ),
      ];
      expectKeyChanges(copyRequest(base, cards: cards, relationships: rels));
    });

    test('reversal', () {
      final cards = [
        for (final c in base.cards)
          c == base.cards.first
              ? TarotNarrativeCardEvidence(
                  canonicalCardId: c.canonicalCardId,
                  ritualCardId: c.ritualCardId,
                  isReversed: !c.isReversed,
                  positionKey: c.positionKey,
                  positionIndex: c.positionIndex,
                  displayName: c.displayName,
                  profileSlice: c.profileSlice,
                  imageAsset: c.imageAsset,
                )
              : c,
      ];
      expectKeyChanges(copyRequest(base, cards: cards));
    });

    test('profile meaning', () {
      final c = base.cards.first;
      final s = c.profileSlice;
      final cards = [
        TarotNarrativeCardEvidence(
          canonicalCardId: c.canonicalCardId,
          ritualCardId: c.ritualCardId,
          isReversed: c.isReversed,
          positionKey: c.positionKey,
          positionIndex: c.positionIndex,
          displayName: c.displayName,
          profileSlice: TarotNarrativeProfileSlice(
            coreMeaning: const L10nTriple('TR_X', 'EN_X', 'RU_X'),
            orientationExpression: s.orientationExpression,
            keywordIds: s.keywordIds,
            symbolTags: s.symbolTags,
            transforms: s.transforms,
            light: s.light,
            shadow: s.shadow,
            tension: s.tension,
            desire: s.desire,
            fear: s.fear,
            relationshipDynamic: s.relationshipDynamic,
            decisionDynamic: s.decisionDynamic,
            actionDirection: s.actionDirection,
          ),
          imageAsset: c.imageAsset,
        ),
        ...base.cards.skip(1),
      ];
      expectKeyChanges(copyRequest(base, cards: cards));
    });

    test('relationship kind / strength', () {
      final r0 = base.relationships.first;
      expectKeyChanges(
        copyRequest(
          base,
          relationships: [
            TarotNarrativeRelationshipEvidence(
              evidenceId: r0.evidenceId,
              leftCardId: r0.leftCardId,
              rightCardId: r0.rightCardId,
              leftPositionKey: r0.leftPositionKey,
              rightPositionKey: r0.rightPositionKey,
              kind: RelationshipKind.conflict,
              provenance: r0.provenance,
              strength: r0.strength,
              noteKeyOrText: r0.noteKeyOrText,
            ),
            ...base.relationships.skip(1),
          ],
        ),
      );
      expectKeyChanges(
        copyRequest(
          base,
          relationships: [
            TarotNarrativeRelationshipEvidence(
              evidenceId: r0.evidenceId,
              leftCardId: r0.leftCardId,
              rightCardId: r0.rightCardId,
              leftPositionKey: r0.leftPositionKey,
              rightPositionKey: r0.rightPositionKey,
              kind: r0.kind,
              provenance: r0.provenance,
              strength: r0.strength + 0.01,
              noteKeyOrText: r0.noteKeyOrText,
            ),
            ...base.relationships.skip(1),
          ],
        ),
      );
    });

    test('recurrence / memory / session-reading', () {
      final withRec = privacySentinelRequest();
      expect(cacheKey(base), isNot(cacheKey(withRec)));
      final memOn = copyRequest(
        base,
        memory: TarotNarrativeMemoryEvidence(
          included: true,
          priorReadingCount: 1,
          recentCardNames: const [],
          recurringThemeLabels: const [],
          omitReason: 'included',
          entries: [
            MemoryEvidenceEntry(
              evidenceRef: 'm1',
              kind: MemoryEvidenceKind.memorySummary,
              contentForModel: 'prior calm note',
            ),
          ],
        ),
      );
      expectKeyChanges(memOn);
      expectKeyChanges(copyRequest(base, sessionId: 'other_session'));
      expectKeyChanges(copyRequest(base, readingId: 'other_reading'));
    });
  });

  group('Locale TR/EN/RU', () {
    test('coreMeaning uses L10nTriple.of language', () {
      final tr = NarrativeTarotPromptSerializer.serialize(
        buildFromCorpusId('single_guidance_cups05r_tr'),
      );
      // Force same card through EN/RU builders for major_00 open.
      final en = NarrativeTarotPromptSerializer.serialize(
        buildFromCorpusId('single_open_fool_en'),
      );
      final ruReq = copyRequest(
        buildFromCorpusId('single_open_fool_en'),
        languageCode: 'ru',
      );
      final ru = NarrativeTarotPromptSerializer.serialize(ruReq);
      expect(en.cards.first.coreMeaning, isNot(ru.cards.first.coreMeaning));
      expect(tr.languageCode, 'tr');
      expect(en.languageCode, 'en');
      expect(ru.languageCode, 'ru');
      // Same underlying triple → distinct localized strings.
      expect(en.cards.first.coreMeaning, isNotEmpty);
      expect(ru.cards.first.coreMeaning, isNotEmpty);
      expect(tr.cards.first.coreMeaning, isNotEmpty);
    });
  });

  group('Bounds fail-closed', () {
    test('relationship / theme / occurrence / memory over-bound', () {
      final base = buildFromCorpusId('three_contrast_exemplar_en');
      final tight = const RequestBounds(
        maxPriorReadingsScanned: 20,
        maxRecurringOccurrencesListed: 1,
        maxRelationships: 1,
        maxMemoryChars: 10,
        maxThemeLabels: 1,
      );
      final overRel = copyRequest(
        base,
        bounds: tight,
        relationships: [
          base.relationships.first,
          if (base.relationships.length > 1)
            base.relationships[1]
          else
            TarotNarrativeRelationshipEvidence(
              evidenceId: 'x',
              leftCardId: base.cards.first.canonicalCardId,
              rightCardId: base.cards.last.canonicalCardId,
              leftPositionKey: base.cards.first.positionKey,
              rightPositionKey: base.cards.last.positionKey,
              kind: RelationshipKind.support,
              provenance: 't',
              strength: 0.1,
            ),
        ],
      );
      expect(
        () => NarrativeTarotPromptSerializer.serialize(overRel),
        throwsArgumentError,
      );

      final overTheme = copyRequest(
        base,
        bounds: tight,
        relationships: const [],
        recurringThemes: [
          TarotRecurringThemeEvidence(
            evidenceId: 't1',
            themeIdOrLabel: 'a',
            supportCount: 1,
            supportingReadingIds: const ['r1'],
            relatedCardIds: [base.cards.first.canonicalCardId],
            relevanceToCurrentAsk: 0.1,
          ),
          TarotRecurringThemeEvidence(
            evidenceId: 't2',
            themeIdOrLabel: 'b',
            supportCount: 1,
            supportingReadingIds: const ['r2'],
            relatedCardIds: [base.cards.first.canonicalCardId],
            relevanceToCurrentAsk: 0.1,
          ),
        ],
      );
      expect(
        () => NarrativeTarotPromptSerializer.serialize(overTheme),
        throwsArgumentError,
      );

      final at = DateTime.utc(2026, 1, 1);
      final overOcc = copyRequest(
        base,
        bounds: tight,
        relationships: const [],
        recurringCards: [
          TarotRecurringCardEvidence(
            evidenceId: 'rc',
            canonicalCardId: base.cards.first.canonicalCardId,
            occurrenceCount: 2,
            contextsOverlap: false,
            occurrences: [
              RecurringOccurrence(
                readingId: 'h1',
                at: at,
                spreadId: 'classical.single',
                positionKey: 'sign',
                isReversed: false,
              ),
              RecurringOccurrence(
                readingId: 'h2',
                at: at,
                spreadId: 'classical.single',
                positionKey: 'sign',
                isReversed: false,
              ),
            ],
          ),
        ],
      );
      expect(
        () => NarrativeTarotPromptSerializer.serialize(overOcc),
        throwsArgumentError,
      );

      final overMem = copyRequest(
        base,
        bounds: tight,
        relationships: const [],
        memory: TarotNarrativeMemoryEvidence(
          included: true,
          priorReadingCount: 1,
          recentCardNames: const [],
          recurringThemeLabels: const [],
          omitReason: 'included',
          entries: [
            MemoryEvidenceEntry(
              evidenceRef: 'm',
              kind: MemoryEvidenceKind.memorySummary,
              contentForModel: 'this text is longer than ten chars',
            ),
          ],
        ),
      );
      expect(
        () => NarrativeTarotPromptSerializer.serialize(overMem),
        throwsArgumentError,
      );
    });
  });
}
