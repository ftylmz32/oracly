/// Phase 6E.3 — provider shadow manifest v2 validation (no provider calls).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import '../narrative_result/phase6e3_enrich_support.dart';

void main() {
  test('manifest v2 coverage + enriched harness displayName', () {
    final root = jsonDecode(
      File(
        'test/fixtures/tarot_narrative_provider_shadow_manifest_v2.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(root['version'], 2);
    expect(root['entryCount'], 6);
    expect(root['resultContractVersion'], 2);
    expect(root['providerSchemaName'], 'oracly_tarot_narrative_v2');
    expect(root['realProviderCallsInPhase6E3'], 0);
    expect(root['maxProviderCallsPerAuthorizedRun'], 6);

    final entries = (root['entries'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(entries.length, 6);

    final langs = {for (final e in entries) e['languageCode']};
    final spreads = {for (final e in entries) e['spreadType']};
    expect(langs, containsAll(['en', 'tr', 'ru']));
    expect(spreads, containsAll(['single', 'threeCard', 'fiveCard']));

    final enrichedEntry = entries.firstWhere(
      (e) => e['manifestId'] == 'psm_v2_06_enriched_multi_memory_en',
    );
    expect(enrichedEntry['buildMode'], 'phase4_enricher_rich_history');
    expect(enrichedEntry['harness'], 'enrichedProviderQaRequest');
    expect(enrichedEntry['baseEvidenceScenarioId'], 'single_open_fool_en');

    final req = enrichedProviderQaRequest();
    final input = NarrativeTarotPromptSerializer.serialize(req);
    expect(input.cards.first.displayName, isNot('major_00'));
    expect(req.memory.included, isTrue);
    expect(req.memory.entries.length, greaterThanOrEqualTo(2));
    expect(req.recurringCards, isNotEmpty);

    final v1 = File(
      'test/fixtures/tarot_narrative_provider_shadow_manifest_v1.json',
    );
    expect(v1.existsSync(), isTrue);
    final v1Root = jsonDecode(v1.readAsStringSync()) as Map<String, dynamic>;
    expect(v1Root['version'], 1);
    expect(v1Root['entryCount'], 6);
  });
}
