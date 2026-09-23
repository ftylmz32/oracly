/// Phase 4D — frozen enrichment corpus vs TarotNarrativeRequestEnricher.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import '../narrative_evidence/narrative_evidence_test_support.dart';
import 'tarot_narrative_history_corpus_support.dart';
import 'tarot_narrative_history_enrichment_corpus_meta.dart';

void main() {
  final corpus = loadHistoryEnrichmentCorpus();
  final scenarios = (corpus['scenarios'] as List).cast<Map<String, dynamic>>();
  final phase3ById = {
    for (final s
        in (loadEvidenceCorpus()['scenarios'] as List)
            .cast<Map<String, dynamic>>())
      s['id'] as String: s,
  };
  final now = DateTime.parse(corpus['now'] as String);

  test('meta coverage matrix', () {
    assertEnrichmentCorpusMeta(scenarios);
  });

  test('every scenario matches frozen expected output', () {
    for (final s in scenarios) {
      final base = buildBaseFromPhase3(
        phase3ById[s['baseScenarioId'] as String]!,
        questionRawOverlay: s['questionRawOverlay'] as String?,
      );
      final before = phase3Projection(base);
      final history = snapshotFromJson(s['history'] as Map<String, dynamic>);
      final out = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: history,
        currentOwnerId: s['currentOwnerId'] as String?,
        now: now,
        privacyBlocked: s['privacyBlocked'] as bool? ?? false,
      );
      expect(phase3Projection(out), before);
      expectPhase4Equal(
        s['expected'] as Map<String, dynamic>,
        phase4Projection(out),
      );

      final exp = s['expected'] as Map<String, dynamic>;
      final mem = exp['memory'] as Map;
      if (mem['included'] == true) {
        for (final e in (mem['entries'] as List?) ?? const []) {
          final m = e as Map;
          final epi = (m['epistemic'] as String?) ?? 'interpretation';
          expect(
            (m['contentForModel'] as String).startsWith(
              '[${epi.toUpperCase()}]',
            ),
            isTrue,
          );
        }
      }
      final bounds = base.bounds;
      expect(
        (exp['recurringCards'] as List).length,
        lessThanOrEqualTo(base.cards.length),
      );
      for (final c in exp['recurringCards'] as List) {
        expect(
          (c as Map)['occurrences'].length,
          lessThanOrEqualTo(bounds.maxRecurringOccurrencesListed),
        );
      }
      expect(
        (exp['recurringThemes'] as List).length,
        lessThanOrEqualTo(bounds.maxThemeLabels),
      );
    }
  });

  test('reorder determinism on tagged scenario', () {
    final s = scenarios.firstWhere((x) => x['id'] == 'p4d_reorder_idempotent');
    final base = buildBaseFromPhase3(
      phase3ById[s['baseScenarioId'] as String]!,
    );
    final hist = Map<String, dynamic>.from(s['history'] as Map);
    final rev = Map<String, dynamic>.from(hist);
    rev['tarotReadings'] = (hist['tarotReadings'] as List).reversed.toList();
    rev['connectedMemories'] = (hist['connectedMemories'] as List).reversed
        .toList();
    final a = phase4Projection(
      TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: snapshotFromJson(hist),
        currentOwnerId: null,
        now: now,
      ),
    );
    final b = phase4Projection(
      TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: snapshotFromJson(rev),
        currentOwnerId: null,
        now: now,
      ),
    );
    expect(jsonEncode(a), jsonEncode(b));
  });

  test('idempotence and privacy revocation on tagged scenario', () {
    final s = scenarios.firstWhere((x) => x['id'] == 'p4d_reorder_idempotent');
    final base = buildBaseFromPhase3(
      phase3ById[s['baseScenarioId'] as String]!,
    );
    final history = snapshotFromJson(s['history'] as Map<String, dynamic>);
    final once = TarotNarrativeRequestEnricher.enrich(
      base: base,
      history: history,
      currentOwnerId: null,
      now: now,
    );
    final twice = TarotNarrativeRequestEnricher.enrich(
      base: once,
      history: history,
      currentOwnerId: null,
      now: now,
    );
    expectPhase4Equal(phase4Projection(once), phase4Projection(twice));

    final revoked = TarotNarrativeRequestEnricher.enrich(
      base: twice,
      history: history,
      currentOwnerId: null,
      now: now,
      privacyBlocked: true,
    );
    expect(revoked.memory.omitReason, 'privacy');
    expect(revoked.recurringCards, isEmpty);
    expect(revoked.recurringThemes, isEmpty);
    expect(revoked.memory.entries, isEmpty);
  });
}
