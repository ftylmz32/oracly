/// Phase 4D red-team — enrichment integrity hardening.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_enrichment_validation.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import '../../narrative_evidence/narrative_evidence_test_support.dart';
import '../tarot_history_test_support.dart';
import '../tarot_narrative_history_corpus_support.dart';
import 'tarot_narrative_enrichment_red_team_support.dart';

void main() {
  final now = nowFixed;
  final scenarios = (loadHistoryEnrichmentCorpus()['scenarios'] as List)
      .cast<Map<String, dynamic>>();

  test('privacy wipe clears stale enriched fields', () {
    final history = TarotHistoricalSnapshot(
      tarotReadings: [
        histReading(
          readingId: 'h1',
          at: now.subtract(const Duration(days: 2)),
          cardId: major00,
        ),
        histReading(
          readingId: 'h2',
          at: now.subtract(const Duration(days: 3)),
          cardId: major00,
        ),
      ],
      connectedMemories: [
        connectedMemory(
          sourceId: 'c1',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: now.subtract(const Duration(days: 1)),
        ),
        connectedMemory(
          sourceId: 'd1',
          sourceType: TarotConnectedMemorySourceType.dream,
          at: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
    final enriched = TarotNarrativeRequestEnricher.enrich(
      base: baseRequest(),
      history: history,
      currentOwnerId: null,
      privacyBlocked: false,
      now: now,
    );
    final wiped = TarotNarrativeRequestEnricher.enrich(
      base: enriched,
      history: history,
      currentOwnerId: null,
      privacyBlocked: true,
      now: now,
    );
    expect(wiped.recurringCards, isEmpty);
    expect(wiped.recurringThemes, isEmpty);
    expect(wiped.memory.entries, isEmpty);
    expect(wiped.memory.omitReason, 'privacy');
  });

  test('owner id never appears in phase4 projection JSON', () {
    for (final s in scenarios) {
      final blob = jsonEncode(s['expected']);
      expect(blob.contains('owner_a'), isFalse);
      expect(blob.contains('owner_b'), isFalse);
    }
  });

  test('namespace uniqueness on corpus engine output', () {
    for (final s in scenarios.where((x) => x['privacyBlocked'] != true)) {
      final p3 = (loadEvidenceCorpus()['scenarios'] as List)
          .cast<Map>()
          .firstWhere((x) => x['id'] == s['baseScenarioId']);
      final out = TarotNarrativeRequestEnricher.enrich(
        base: buildBaseFromPhase3(Map<String, dynamic>.from(p3)),
        history: snapshotFromJson(s['history'] as Map<String, dynamic>),
        currentOwnerId: s['currentOwnerId'] as String?,
        privacyBlocked: false,
        now: now,
      );
      final ids = <String>{
        ...out.relationships.map((e) => e.evidenceId),
        ...out.memory.entries.map((e) => e.evidenceRef),
        ...out.recurringCards.map((e) => e.evidenceId),
        ...out.recurringThemes.map((e) => e.evidenceId),
      };
      final expected =
          out.relationships.length +
          out.memory.entries.length +
          out.recurringCards.length +
          out.recurringThemes.length;
      expect(ids.length, expected);
      TarotNarrativeEnrichmentValidation.validate(
        request: out,
        history: snapshotFromJson(s['history'] as Map<String, dynamic>),
        currentOwnerId: s['currentOwnerId'] as String?,
        now: now,
      );
    }
  });

  test('themeRepetition alone with empty history → no recurringThemes', () {
    assertThemeEchoNoHistory(now);
  });

  test('result collections reject mutation', () {
    assertMutationRejected(now);
  });

  test('enricher source has no DateTime.now', () {
    final src = File(
      'lib/features/tarot/narrative/history/tarot_narrative_request_enricher.dart',
    ).readAsStringSync();
    expect(src.contains('DateTime.now'), isFalse);
  });
}
