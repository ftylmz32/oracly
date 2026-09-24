/// Phase 6C — privacy red-team + immutability + truth firewalls.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_cache_identity.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_special_requests.dart';
import 'narrative_prompt_test_support.dart';

void main() {
  group('Privacy red-team', () {
    test('sentinels absent from model + cache key', () {
      final request = privacySentinelRequest();
      final encoded = encodeModel(request);
      final key = cacheKey(request);
      const secrets = [
        'SECRET_OWNER_6C',
        'SECRET_SOURCE_6C',
        'SECRET_READING_ID_6C',
        'SECRET_EVIDENCE_6C',
        'rel_01',
        'rec_card_01',
        'rec_theme_01',
        'SECRET_HINT_SHOULD_NOT_AUTHORIZE',
        'SECRET_THEME_HINT',
        'SECRET_INTERNAL_RELATION_NOTE_6C1',
      ];
      for (final s in secrets) {
        expect(encoded.contains(s), isFalse, reason: s);
        expect(key.contains(s), isFalse, reason: 'key:$s');
      }
      expect(encoded.contains('scope_session_6c'), isFalse);
      expect(encoded.contains('scope_reading_6c'), isFalse);
      expect(key.startsWith(NarrativeTarotCacheIdentity.keyPrefix), isTrue);
      expect(key.contains('scope_session'), isFalse);
      expect(key.contains('scope_reading'), isFalse);
    });

    test('internal metadata-only change keeps model + cache', () {
      final a = privacySentinelRequest();
      final b = copyRequest(
        a,
        relationships: [
          for (final r in a.relationships)
            TarotNarrativeRelationshipEvidence(
              evidenceId: 'CHANGED_REL_ID',
              leftCardId: r.leftCardId,
              rightCardId: r.rightCardId,
              leftPositionKey: r.leftPositionKey,
              rightPositionKey: r.rightPositionKey,
              kind: r.kind,
              provenance: 'CHANGED_PROVENANCE',
              strength: r.strength,
              noteKeyOrText: r.noteKeyOrText,
            ),
        ],
        recurringCards: [
          for (final rc in a.recurringCards)
            TarotRecurringCardEvidence(
              evidenceId: 'CHANGED_REC_CARD',
              canonicalCardId: rc.canonicalCardId,
              occurrenceCount: rc.occurrenceCount,
              contextsOverlap: rc.contextsOverlap,
              overlapSummaryKey: rc.overlapSummaryKey,
              occurrences: [
                for (final o in rc.occurrences)
                  RecurringOccurrence(
                    readingId: 'CHANGED_READING',
                    at: o.at,
                    spreadId: o.spreadId,
                    positionKey: o.positionKey,
                    isReversed: o.isReversed,
                    orientationKnown: o.orientationKnown,
                    intentionSummary: o.intentionSummary,
                  ),
              ],
            ),
        ],
        recurringThemes: [
          for (final t in a.recurringThemes)
            TarotRecurringThemeEvidence(
              evidenceId: 'CHANGED_THEME',
              themeIdOrLabel: t.themeIdOrLabel,
              supportCount: t.supportCount,
              supportingReadingIds: const ['CHANGED_SUPPORT'],
              relatedCardIds: t.relatedCardIds,
              relevanceToCurrentAsk: t.relevanceToCurrentAsk,
            ),
        ],
        memory: TarotNarrativeMemoryEvidence(
          included: true,
          priorReadingCount: a.memory.priorReadingCount,
          recentCardNames: a.memory.recentCardNames,
          recurringThemeLabels: a.memory.recurringThemeLabels,
          omitReason: a.memory.omitReason,
          entries: [
            for (final e in a.memory.entries)
              MemoryEvidenceEntry(
                evidenceRef: 'CHANGED_REF',
                kind: e.kind,
                contentForModel: e.contentForModel,
                sourceType: e.sourceType,
                sourceId: 'CHANGED_SOURCE',
                occurredAt: e.occurredAt,
                confidence: e.confidence,
                epistemic: e.epistemic,
              ),
          ],
        ),
      );
      expect(encodeModel(a), encodeModel(b));
      expect(cacheKey(a), cacheKey(b));
    });
  });

  group('Immutability', () {
    test('DTO lists reject mutation', () {
      final input = NarrativeTarotPromptSerializer.serialize(
        buildFromCorpusId('three_contrast_exemplar_en'),
      );
      expect(() => input.cards.add(input.cards.first), throwsUnsupportedError);
      expect(
        () => input.spread.positions.add(input.spread.positions.first),
        throwsUnsupportedError,
      );
      expect(
        () => input.relationships.add(input.relationships.first),
        throwsUnsupportedError,
      );
      final enriched = NarrativeTarotPromptSerializer.serialize(
        enrichedForSerialize(),
      );
      expect(
        () => enriched.recurringCards.first.occurrences
            .add(enriched.recurringCards.first.occurrences.first),
        throwsUnsupportedError,
      );
      expect(
        () => enriched.memory.entries.add(enriched.memory.entries.first),
        throwsUnsupportedError,
      );
    });
  });

  group('Truth firewalls', () {
    test('empty recurrence stays empty despite hints', () {
      final base = buildFromCorpusId('single_open_fool_en');
      final withHints = copyRequest(
        base,
        memory: const TarotNarrativeMemoryEvidence(
          included: false,
          priorReadingCount: 3,
          recentCardNames: ['major_00', 'major_01'],
          recurringThemeLabels: ['threshold'],
          omitReason: 'empty',
          entries: [],
        ),
      );
      final input = NarrativeTarotPromptSerializer.serialize(withHints);
      expect(input.recurringCards, isEmpty);
      expect(input.recurringThemes, isEmpty);
    });

    test('null question not invented', () {
      final r = NarrativeEvidenceBuilder.build(singleTrOpenInput());
      final q = NarrativeTarotPromptSerializer.serialize(r).question;
      expect(q.text, isNull);
      expect(q.hasRealQuestion, isFalse);
      expect(q.kind, 'open');
    });

    test('unknown orientation stays null not upright', () {
      final base = privacySentinelRequest();
      final rc = base.recurringCards.first;
      final unknown = copyRequest(
        base,
        recurringCards: [
          TarotRecurringCardEvidence(
            evidenceId: rc.evidenceId,
            canonicalCardId: rc.canonicalCardId,
            occurrenceCount: 1,
            contextsOverlap: rc.contextsOverlap,
            overlapSummaryKey: rc.overlapSummaryKey,
            occurrences: [
              RecurringOccurrence(
                readingId: 'hid',
                at: rc.occurrences.first.at,
                spreadId: rc.occurrences.first.spreadId,
                positionKey: rc.occurrences.first.positionKey,
                isReversed: false,
                orientationKnown: false,
              ),
            ],
          ),
        ],
      );
      final occ = NarrativeTarotPromptSerializer.serialize(unknown)
          .recurringCards
          .first
          .occurrences
          .first;
      expect(occ.orientationKnown, isFalse);
      expect(occ.isReversed, isNull);
    });
  });
}
