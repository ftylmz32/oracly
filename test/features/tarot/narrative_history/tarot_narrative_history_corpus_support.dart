/// Corpus load + snapshot parse helpers (Phase 4D).
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

import '../narrative_evidence/narrative_evidence_test_support.dart';

export 'tarot_narrative_history_corpus_project.dart';

Map<String, dynamic> loadHistoryEnrichmentCorpus() {
  final file = File('test/fixtures/tarot_narrative_history_enrichment_v1.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

TarotNarrativeRequest buildBaseFromPhase3(
  Map<String, dynamic> phase3Scenario, {
  String? questionRawOverlay,
}) {
  final input = inputFromScenario(phase3Scenario);
  if (questionRawOverlay == null) {
    return NarrativeEvidenceBuilder.build(input);
  }
  return NarrativeEvidenceBuilder.build(
    NarrativeEvidenceInput(
      sessionId: input.sessionId,
      readingId: input.readingId,
      languageCode: input.languageCode,
      questionRaw: questionRawOverlay,
      intentionTopic: input.intentionTopic,
      spreadType: input.spreadType,
      cards: input.cards,
    ),
  );
}

TarotHistoricalSnapshot snapshotFromJson(Map<String, dynamic> history) {
  final readings = <TarotHistoricalReadingRecord>[];
  for (final raw in history['tarotReadings'] as List? ?? const []) {
    final m = Map<String, dynamic>.from(raw as Map);
    final cards = <TarotHistoricalCardOccurrence>[];
    for (final c in m['cards'] as List? ?? const []) {
      final cm = Map<String, dynamic>.from(c as Map);
      cards.add(
        TarotHistoricalCardOccurrence(
          canonicalCardId: cm['canonicalCardId'] as String,
          isReversed: cm['isReversed'] as bool? ?? false,
          orientationKnown: cm['orientationKnown'] as bool? ?? true,
          positionKey: cm['positionKey'] as String?,
          positionIndex: cm['positionIndex'] as int?,
        ),
      );
    }
    readings.add(
      TarotHistoricalReadingRecord(
        readingId: m['readingId'] as String,
        sessionId: m['sessionId'] as String?,
        ownerId: m['ownerId'] as String?,
        occurredAt: DateTime.parse(m['occurredAt'] as String),
        spreadId: m['spreadId'] as String? ?? 'single',
        questionKind: m['questionKind'] == null
            ? null
            : QuestionKind.values.byName(m['questionKind'] as String),
        topicId: m['topicId'] as String?,
        intentionSummary: m['intentionSummary'] as String?,
        interpretationSummary: m['interpretationSummary'] as String?,
        cards: cards,
      ),
    );
  }
  final memories = <TarotConnectedMemoryRecord>[];
  for (final raw in history['connectedMemories'] as List? ?? const []) {
    final m = Map<String, dynamic>.from(raw as Map);
    memories.add(
      TarotConnectedMemoryRecord(
        sourceId: m['sourceId'] as String,
        sourceType: TarotConnectedMemorySourceType.values.byName(
          m['sourceType'] as String,
        ),
        occurredAt: DateTime.parse(m['occurredAt'] as String),
        summary: m['summary'] as String,
        themeIds: [
          for (final t in m['themeIds'] as List? ?? const []) t as String,
        ],
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0.8,
        epistemic: MemoryEvidenceEpistemic.values.byName(
          m['epistemic'] as String? ?? 'interpretation',
        ),
      ),
    );
  }
  return TarotHistoricalSnapshot(
    tarotReadings: readings,
    connectedMemories: memories,
  );
}
