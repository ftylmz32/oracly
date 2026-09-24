/// Phase 6C.1/6C.2 — privacy sentinel + Signature Crossroads test requests.
library;

import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projector.dart';

import 'narrative_prompt_test_support.dart';

TarotNarrativeRequest privacySentinelRequest() {
  final base = buildFromCorpusId('three_contrast_exemplar_en');
  final card = base.cards.first;
  final rel = base.relationships.first;
  final at = DateTime.utc(2026, 8, 1, 10);
  return copyRequest(
    base,
    sessionId: 'scope_session_6c',
    readingId: 'scope_reading_6c',
    memory: TarotNarrativeMemoryEvidence(
      included: true,
      priorReadingCount: 1,
      recentCardNames: const ['SECRET_HINT_SHOULD_NOT_AUTHORIZE'],
      recurringThemeLabels: const ['SECRET_THEME_HINT'],
      omitReason: 'included',
      entries: [
        MemoryEvidenceEntry(
          evidenceRef: 'SECRET_EVIDENCE_6C',
          kind: MemoryEvidenceKind.memorySummary,
          contentForModel: 'A calm prior reflection about thresholds.',
          sourceType: 'coffee',
          sourceId: 'SECRET_SOURCE_6C',
          occurredAt: at,
          confidence: 0.7,
          epistemic: MemoryEvidenceEpistemic.interpretation,
        ),
      ],
    ),
    recurringCards: [
      TarotRecurringCardEvidence(
        evidenceId: 'rec_card_01',
        canonicalCardId: card.canonicalCardId,
        occurrenceCount: 1,
        contextsOverlap: true,
        overlapSummaryKey: 'overlap.threshold',
        occurrences: [
          RecurringOccurrence(
            readingId: 'SECRET_READING_ID_6C',
            at: at,
            spreadId: 'classical.threeCard',
            positionKey: card.positionKey,
            isReversed: false,
            orientationKnown: true,
            intentionSummary: 'prior threshold visit',
          ),
        ],
      ),
    ],
    recurringThemes: [
      TarotRecurringThemeEvidence(
        evidenceId: 'rec_theme_01',
        themeIdOrLabel: 'threshold',
        supportCount: 2,
        supportingReadingIds: const ['SECRET_READING_ID_6C'],
        relatedCardIds: [card.canonicalCardId],
        relevanceToCurrentAsk: 0.55,
      ),
    ],
    relationships: [
      TarotNarrativeRelationshipEvidence(
        evidenceId: 'rel_01',
        leftCardId: rel.leftCardId,
        rightCardId: rel.rightCardId,
        leftPositionKey: rel.leftPositionKey,
        rightPositionKey: rel.rightPositionKey,
        kind: rel.kind,
        provenance: 'SECRET_OWNER_6C',
        strength: rel.strength,
        noteKeyOrText: 'SECRET_INTERNAL_RELATION_NOTE_6C1',
      ),
      ...base.relationships.skip(1),
    ],
  );
}

/// TEST-ONLY: valid five-card Crossroads projected semantics.
/// Does NOT imply builder support or live Crossroads Narrative.
/// languageCode and displayName/profile slices are consistently EN.
TarotNarrativeRequest signatureManualRequest() {
  const lang = 'en';
  final projected =
      SignatureSpreadProjector.project(kSignatureCrossroads).projected;
  final five = buildFromCorpusId('five_support_exemplar_en');
  final cards = <TarotNarrativeCardEvidence>[];
  for (var i = 0; i < projected.positions.length; i++) {
    final pos = projected.positions[i];
    final src = five.cards[i];
    final deck = OraclyTarotDeck.byId(src.canonicalCardId);
    if (deck == null) {
      throw StateError('missing deck card ${src.canonicalCardId}');
    }
    cards.add(
      TarotNarrativeCardEvidence(
        canonicalCardId: src.canonicalCardId,
        ritualCardId: src.ritualCardId,
        isReversed: src.isReversed,
        positionKey: pos.positionKey,
        positionIndex: pos.index,
        displayName: deck.name.of(lang),
        profileSlice: src.profileSlice,
        imageAsset: src.imageAsset,
      ),
    );
  }
  return TarotNarrativeRequest(
    narrativeTarotVersion: TarotNarrativeRequest.currentNarrativeVersion,
    languageCode: lang,
    sessionId: 'sig_session',
    readingId: 'sig_reading',
    question: const QuestionGrounding(
      rawText: null,
      topic: null,
      kind: QuestionKind.open,
      hasRealQuestion: false,
    ),
    spread: projected,
    cards: cards,
    relationships: const [],
    memory: TarotNarrativeMemoryEvidence.empty,
    recurringCards: const [],
    recurringThemes: const [],
    bounds: RequestBounds.defaults,
  );
}
