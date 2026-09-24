/// Phase 6E.3 — Result Contract V2 + Call #4/#6 regressions (no provider calls).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_prose_quality.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_quality_validator.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_bounds.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_error.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_result_assessor.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import 'phase6d_test_support.dart';
import 'phase6e3_enrich_support.dart';

void main() {
  test('result bounds are contract v2', () {
    expect(NarrativeTarotResultBounds.contractVersion, 2);
  });

  test('historical v1 result rejected by v2 parser', () {
    final request = buildFromCorpusId('single_open_fool_en');
    final v1 = validResultMap(request)..['contractVersion'] = 1;
    expect(
      () => NarrativeTarotResultParser.parse(v1),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.version,
        ),
      ),
    );
  });

  test('Call #6 v1 memoryIndex rejected; combined memoryIndices pass', () {
    final root = jsonDecode(
      File(
        'test/fixtures/tarot_narrative_provider_shadow_results_6e2.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final call6 = (root['calls'] as List).cast<Map>().firstWhere(
      (c) => c['callNumber'] == 6,
    );
    final raw = Map<String, dynamic>.from(call6['structuredResult'] as Map);
    expect(
      () => NarrativeTarotResultParser.parse(raw),
      throwsA(isA<NarrativeTarotResultException>()),
    );

    final request = enrichedProviderQaRequest();
    expect(request.memory.included, isTrue);
    expect(request.memory.entries.length, greaterThanOrEqualTo(2));
    final ok = validResultMap(request);
    ok['memoryInsights'] = [
      {
        'memoryIndices': [0, 1],
        'text': longProse(50),
      },
    ];
    final parsed = NarrativeTarotResultParser.parse(ok);
    expect(parsed.memoryInsights.single.memoryIndices, [0, 1]);
    NarrativeTarotQualityValidator.validate(request: request, result: parsed);

    final reuse = validResultMap(request);
    reuse['memoryInsights'] = [
      {
        'memoryIndices': [0, 1],
        'text': longProse(50),
      },
      {
        'memoryIndices': [0],
        'text': longProse(50),
      },
    ];
    expect(
      () => NarrativeTarotQualityValidator.validate(
        request: request,
        result: NarrativeTarotResultParser.parse(reuse),
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.memoryEvidence,
        ),
      ),
    );
  });

  test('Call #4 deterministic future FAIL; conditional PASS', () {
    final root = jsonDecode(
      File(
        'test/fixtures/tarot_narrative_provider_shadow_results_6e2.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final call4 = (root['calls'] as List).cast<Map>().firstWhere(
      (c) => c['callNumber'] == 4,
    );
    final structured =
        Map<String, dynamic>.from(call4['structuredResult'] as Map);
    final synthesis = structured['synthesis'] as String;
    final relTexts = (structured['relationshipInsights'] as List)
        .map((e) => (e as Map)['text'] as String)
        .join('\n');
    final hit = NarrativeTarotProseQuality.firstDeterministicFutureHit(
      '$synthesis\n$relTexts',
      languageCode: 'en',
    );
    expect(hit, isNotNull);

    final request = buildFromCorpusId('three_contrast_exemplar_en');
    final map = validResultMap(request);
    map['synthesis'] =
        'This season may point toward balance through honest assessment.';
    map['relationshipInsights'] = [
      {
        'leftCardId': request.relationships.first.leftCardId,
        'rightCardId': request.relationships.first.rightCardId,
        'kind': request.relationships.first.kind.name,
        'text':
            'The contrast may invite resolving present discord toward fairer outcomes.',
      },
    ];
    final parsed = NarrativeTarotResultParser.parse(map);
    NarrativeTarotProseQuality.validate(parsed);

    final bad = Map<String, dynamic>.from(map);
    bad['synthesis'] =
        'The future promises a return to balance through honest assessment.';
    expect(
      () => NarrativeTarotProseQuality.validate(
        NarrativeTarotResultParser.parse(bad),
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.deterministicFuture,
        ),
      ),
    );
  });

  test('enricher rich history yields authoritative displayName', () {
    final enriched = enrichedProviderQaRequest();
    final input = NarrativeTarotPromptSerializer.serialize(enriched);
    expect(input.cards.first.displayName, isNot('major_00'));
    expect(input.cards.first.displayName.trim(), isNotEmpty);
    expect(enriched.memory.entries.length, greaterThanOrEqualTo(2));
  });

  test('offline launch corpus 24/24 still assesses PASS under v2', () {
    final corpus = jsonDecode(
      File('test/fixtures/tarot_narrative_evidence_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scenarios = (corpus['scenarios'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((s) {
          final input = Map<String, dynamic>.from(s['input'] as Map);
          final t = input['spreadType'] as String;
          return t == 'single' || t == 'threeCard' || t == 'fiveCard';
        })
        .toList();
    expect(scenarios.length, 24);
    final at = DateTime.utc(2026, 9, 24, 20);
    for (final scenario in scenarios) {
      final req = buildFromCorpusId(scenario['id'] as String);
      final assessment = NarrativeTarotShadowResultAssessor.assess(
        request: req,
        rawResult: validResultMap(req),
        requestId: 'v2_${scenario['id']}',
        sessionId: req.sessionId,
        generatedAt: at,
      );
      expect(
        assessment.status,
        NarrativeTarotShadowAssessStatus.pass,
        reason: '${scenario['id']}',
      );
    }
  });
}
