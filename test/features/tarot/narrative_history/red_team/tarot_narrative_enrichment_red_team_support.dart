/// Shared helpers for Phase 4D enrichment red-team tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import '../../narrative_evidence/narrative_evidence_test_support.dart';
import '../tarot_history_test_support.dart';
import '../tarot_narrative_history_corpus_support.dart';

void assertThemeEchoNoHistory(DateTime now) {
  final base = TarotNarrativeRequest(
    narrativeTarotVersion: 2,
    languageCode: 'en',
    sessionId: 's',
    readingId: 'r',
    question: NarrativeQuestionGrounding.from(rawQuestion: 'Should I stay?'),
    spread: ClassicalSpreadSemantics.byLegacyTypeName('single'),
    cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
    relationships: const [
      TarotNarrativeRelationshipEvidence(
        evidenceId: 'rel_01',
        leftCardId: 'major_06',
        rightCardId: 'major_00',
        leftPositionKey: 'sign',
        rightPositionKey: 'sign',
        kind: RelationshipKind.themeRepetition,
        provenance: 'test',
        strength: 0.9,
      ),
    ],
    memory: TarotNarrativeMemoryEvidence.empty,
    recurringCards: const [],
    recurringThemes: const [],
    bounds: RequestBounds.defaults,
  );
  final out = TarotNarrativeRequestEnricher.enrich(
    base: base,
    history: TarotHistoricalSnapshot(tarotReadings: const []),
    currentOwnerId: null,
    privacyBlocked: false,
    now: now,
  );
  expect(out.recurringThemes, isEmpty);
}

void assertMutationRejected(DateTime now) {
  final s = loadHistoryEnrichmentCorpus();
  final scenario = (s['scenarios'] as List).cast<Map>().firstWhere(
    (x) => x['id'] == 'p4d_reorder_idempotent',
  );
  final phase3 = loadEvidenceCorpus();
  final p3 = (phase3['scenarios'] as List).cast<Map>().firstWhere(
    (x) => x['id'] == scenario['baseScenarioId'],
  );
  final out = TarotNarrativeRequestEnricher.enrich(
    base: buildBaseFromPhase3(Map<String, dynamic>.from(p3)),
    history: snapshotFromJson(scenario['history'] as Map<String, dynamic>),
    currentOwnerId: null,
    privacyBlocked: false,
    now: now,
  );
  expect(
    () => out.recurringCards.add(out.recurringCards.first),
    throwsUnsupportedError,
  );
  expect(
    () => out.recurringThemes.add(out.recurringThemes.first),
    throwsUnsupportedError,
  );
  expect(
    () => out.memory.entries.add(out.memory.entries.first),
    throwsUnsupportedError,
  );
}
