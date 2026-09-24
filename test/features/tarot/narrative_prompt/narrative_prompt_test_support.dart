/// Phase 6C — shared helpers for prompt serializer / cache tests.
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_cache_identity.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_canonical.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import '../narrative_evidence/narrative_evidence_test_support.dart';
import '../narrative_history/tarot_narrative_request_enricher_fixtures.dart';
import '../narrative_history/tarot_history_test_support.dart';

Map<String, dynamic> loadPromptFixture() {
  final file = File('test/fixtures/tarot_narrative_prompt_v1.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

TarotNarrativeRequest buildFromCorpusId(String scenarioId) {
  final corpus = loadEvidenceCorpus();
  final scenarios = corpus['scenarios'] as List<dynamic>;
  final scenario = scenarios.cast<Map<String, dynamic>>().firstWhere(
    (s) => s['id'] == scenarioId,
  );
  return NarrativeEvidenceBuilder.build(inputFromScenario(scenario));
}

TarotNarrativeRequest copyRequest(
  TarotNarrativeRequest r, {
  String? languageCode,
  String? sessionId,
  String? readingId,
  QuestionGrounding? question,
  SpreadSemanticDefinition? spread,
  List<TarotNarrativeCardEvidence>? cards,
  List<TarotNarrativeRelationshipEvidence>? relationships,
  TarotNarrativeMemoryEvidence? memory,
  List<TarotRecurringCardEvidence>? recurringCards,
  List<TarotRecurringThemeEvidence>? recurringThemes,
  RequestBounds? bounds,
}) {
  return TarotNarrativeRequest(
    narrativeTarotVersion: r.narrativeTarotVersion,
    languageCode: languageCode ?? r.languageCode,
    sessionId: sessionId ?? r.sessionId,
    readingId: readingId ?? r.readingId,
    question: question ?? r.question,
    spread: spread ?? r.spread,
    cards: cards ?? r.cards,
    relationships: relationships ?? r.relationships,
    memory: memory ?? r.memory,
    recurringCards: recurringCards ?? r.recurringCards,
    recurringThemes: recurringThemes ?? r.recurringThemes,
    bounds: bounds ?? r.bounds,
  );
}

TarotNarrativeRequest enrichedForSerialize() {
  final base = baseRequest(
    questionRaw: 'Should I stay in this relationship?',
    topic: 'love',
  );
  return TarotNarrativeRequestEnricher.enrich(
    base: base,
    history: enricherRichHistory(base, nowFixed),
    currentOwnerId: null,
    privacyBlocked: false,
    now: nowFixed,
  );
}

TarotNarrativeRequest privacySentinelRequest() {
  final base = buildFromCorpusId('single_open_fool_en');
  final card = base.cards.first;
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
            spreadId: 'classical.single',
            positionKey: 'sign',
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
        leftCardId: card.canonicalCardId,
        rightCardId: card.canonicalCardId,
        leftPositionKey: 'sign',
        rightPositionKey: 'sign',
        kind: RelationshipKind.reinforcement,
        provenance: 'SECRET_OWNER_6C',
        strength: 0.4,
        noteKeyOrText: 'safe model note',
      ),
    ],
  );
}

TarotNarrativeRequest signatureManualRequest() {
  final base = buildFromCorpusId('single_open_fool_en');
  final card = base.cards.first;
  final spread = SpreadSemanticDefinition(
    spreadId: 'signature.crossroads',
    legacyTypeName: 'crossroads',
    cardCount: 1,
    purposeKey: 'purpose.signature.crossroads',
    positions: const [
      SpreadPositionSemantic(
        positionKey: 'question',
        index: 0,
        role: PositionRole.question,
        guidingQuestionKey: 'gq.signature.crossroads.question',
        temporal: TemporalOrientation.present,
        relationToOtherSlots: [],
        weight: 1,
        displayLabelKey: 'label.signature.crossroads.question',
      ),
    ],
    interpretationOrder: const [0],
    geometryHook: NarrativeGeometryHook.singlePoint,
    lengthBand: NarrativeLengthBand.medium,
  );
  return copyRequest(
    base,
    sessionId: 'sig_session',
    readingId: 'sig_reading',
    spread: spread,
    cards: [
      TarotNarrativeCardEvidence(
        canonicalCardId: card.canonicalCardId,
        ritualCardId: card.ritualCardId,
        isReversed: card.isReversed,
        positionKey: 'question',
        positionIndex: 0,
        displayName: card.displayName,
        profileSlice: card.profileSlice,
        imageAsset: card.imageAsset,
      ),
    ],
  );
}

String encodeModel(TarotNarrativeRequest request) {
  final input = NarrativeTarotPromptSerializer.serialize(request);
  return NarrativeTarotPromptCanonical.encode(input);
}

String cacheKey(TarotNarrativeRequest request) {
  return NarrativeTarotCacheIdentity.keyFor(request);
}

NarrativeEvidenceInput singleTrOpenInput() {
  return NarrativeEvidenceInput(
    sessionId: '6c_session_single_tr',
    readingId: '6c_reading_single_tr',
    languageCode: 'tr',
    questionRaw: null,
    intentionTopic: null,
    spreadType: TarotSpreadType.single,
    cards: const [
      NarrativeEvidenceCardInput(
        canonicalCardId: 'major_00',
        ritualCardId: 0,
        isReversed: false,
        positionKey: 'sign',
        positionIndex: 0,
      ),
    ],
  );
}
