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
  int? narrativeTarotVersion,
}) {
  return TarotNarrativeRequest(
    narrativeTarotVersion:
        narrativeTarotVersion ?? r.narrativeTarotVersion,
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

SpreadSemanticDefinition withInterpretationOrder(
  SpreadSemanticDefinition s,
  List<int> order,
) {
  return SpreadSemanticDefinition(
    spreadId: s.spreadId,
    legacyTypeName: s.legacyTypeName,
    cardCount: s.cardCount,
    purposeKey: s.purposeKey,
    positions: s.positions,
    interpretationOrder: order,
    geometryHook: s.geometryHook,
    lengthBand: s.lengthBand,
  );
}
