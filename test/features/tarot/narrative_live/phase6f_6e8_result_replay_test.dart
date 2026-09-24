/// Phase 6F — replay the frozen 6E.8 Sol results through the live client
/// chain: parser → quality validator → InterpretationResult bridge.
/// The fixture is read-only. REAL PROVIDER CALLS = 0.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_quality_validator.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_bridge.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import '../narrative_result/phase6e3_enrich_support.dart';
import 'phase6f_live_support.dart';

const _corpusByManifest = <String, String>{
  'psm_v2_01_single_open_en': 'single_open_fool_en',
  'psm_v2_02_single_guidance_tr_reversed': 'single_guidance_cups05r_tr',
  'psm_v2_03_single_relationship_ru': 'single_relationship_swords09r_ru',
  'psm_v2_04_three_contrast_en': 'three_contrast_exemplar_en',
  'psm_v2_05_five_conflict_ru': 'five_conflict_exemplar_ru',
};

TarotNarrativeRequest _requestFor(Map<String, dynamic> call) {
  final id = call['manifestId'] as String;
  if (id == 'psm_v2_06_enriched_multi_memory_en') {
    return enrichedProviderQaRequest();
  }
  return buildFromCorpusId(_corpusByManifest[id]!);
}

final _at = DateTime.utc(2026, 9, 24, 19);

void main() {
  test('fixture is frozen Manifest V2 evidence with six used calls', () {
    final root = loadSolResults();
    expect(root['manifestVersion'], 2);
    expect(root['resultContractVersion'], 2);
    expect(root['usedCalls'], 6);
    expect(root['remaining'], 0);
    expect(root['autoRetries'], 0);
    expect(root['liveCacheWrites'], 0);
    expect(solCalls(), hasLength(6));
  });

  test('replay never rewrites the immutable fixture', () {
    final before = File(solResultsPath).readAsStringSync();
    for (final call in solCalls()) {
      final raw = call['structuredResult'];
      if (raw is! Map) continue;
      NarrativeTarotResultParser.parse(Map<String, dynamic>.from(raw));
    }
    expect(File(solResultsPath).readAsStringSync(), before);
  });

  group('parser → validator → bridge', () {
    for (final call in solCalls()) {
      final manifestId = call['manifestId'] as String;
      final raw = call['structuredResult'];
      if (call['backendValid'] != true || raw is! Map) {
        test('$manifestId — typed failure carries no structured result', () {
          expect(call['structuredResult'], isNull);
          expect((call['typedFailure'] as Map)['code'], isNotNull);
        });
        continue;
      }

      test('$manifestId — parses, validates and bridges', () {
        final request = _requestFor(call);
        final structured = NarrativeTarotResultParser.parse(
          Map<String, dynamic>.from(raw),
        );

        expect(structured.contractVersion, 2);
        expect(structured.languageCode, call['languageCode']);
        expect(structured.languageCode, request.languageCode);
        expect(structured.cardReadings, hasLength(call['cardCount']));

        NarrativeTarotQualityValidator.validate(
          request: request,
          result: structured,
        );

        final bridged = NarrativeTarotResultBridge.toInterpretationResult(
          request: request,
          result: structured,
          requestId: 'phase6f_replay_${call['callNumber']}',
          sessionId: request.sessionId,
          generatedAt: _at,
        );

        expect(bridged.summary, structured.summary);
        expect(bridged.advice, structured.advice);
        expect(bridged.luckyEnergy, structured.synthesis);
        expect(bridged.closingMessage, structured.closingMessage);
        expect(bridged.generatedAt, _at);
        expect(bridged.health.trim(), isNotEmpty);
        for (final reading in structured.cardReadings) {
          expect(bridged.health, contains(reading.text));
        }
      });
    }
  });

  test('case 6 memory insight stays bound to memoryIndices [0, 1]', () {
    final call = solCalls().firstWhere(
      (c) => c['manifestId'] == 'psm_v2_06_enriched_multi_memory_en',
    );
    final request = enrichedProviderQaRequest();
    expect(request.memory.included, isTrue);
    expect(request.memory.entries.length, greaterThanOrEqualTo(2));

    final structured = NarrativeTarotResultParser.parse(
      Map<String, dynamic>.from(call['structuredResult'] as Map),
    );
    expect(structured.memoryInsights, hasLength(1));
    expect(structured.memoryInsights.single.memoryIndices, [0, 1]);

    NarrativeTarotQualityValidator.validate(
      request: request,
      result: structured,
    );

    final bridged = NarrativeTarotResultBridge.toInterpretationResult(
      request: request,
      result: structured,
      requestId: 'phase6f_replay_memory',
      sessionId: request.sessionId,
      generatedAt: _at,
    );
    expect(bridged.summary, isNotEmpty);
    expect(bridged.sessionId, request.sessionId);
  });
}
