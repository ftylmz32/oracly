/// Phase 6E.2 — client assessor + replay against captured provider results.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_result_assessor.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';

const _resultsPath =
    'test/fixtures/tarot_narrative_provider_shadow_results_6e2.json';
const _manifestPath =
    'test/fixtures/tarot_narrative_provider_shadow_manifest_v1.json';

const _idLeakNeedles = [
  'rel_',
  'rec_card_',
  'rec_theme_',
  'mem_',
];

TarotNarrativeRequest requestFor(Map<String, dynamic> entry) {
  final evidenceId = entry['evidenceScenarioId'] as String?;
  final promptId = entry['promptFixtureScenarioId'] as String?;
  if (evidenceId != null) return buildFromCorpusId(evidenceId);
  if (promptId != null) return enrichedForSerialize();
  throw StateError('no request source');
}

String visibleText(Map<String, dynamic> result) {
  final buf = StringBuffer();
  void add(Object? v) {
    if (v is String) buf.writeln(v);
  }

  add(result['summary']);
  add(result['synthesis']);
  add(result['advice']);
  add(result['reflectionPrompt']);
  add(result['dailyFocus']);
  add(result['closingMessage']);
  for (final key in [
    'cardReadings',
    'relationshipInsights',
    'recurringCardInsights',
    'recurringThemeInsights',
    'memoryInsights',
    'lifeAreas',
  ]) {
    final list = result[key];
    if (list is! List) continue;
    for (final item in list) {
      if (item is Map) add(item['text']);
    }
  }
  return buf.toString();
}

void main() {
  test('6E.2 client assess + enrich results fixture', () {
    final manifest =
        jsonDecode(File(_manifestPath).readAsStringSync()) as Map;
    final entries = (manifest['entries'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final root = jsonDecode(File(_resultsPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(root['precallValidation'], 'PASS');
    expect(root['used'], 6);
    final calls = (root['calls'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(calls.length, 6);

    final at = DateTime.utc(2026, 9, 24, 18);
    var parsePass = 0;
    var narrativePass = 0;
    var aiPass = 0;
    var leaks = 0;

    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final entry = entries[i];
      expect(call['manifestId'], entry['manifestId']);
      final req = requestFor(entry);
      // Internal ids for leak scan (must not appear in visible prose).
      final secretIds = <String>{
        req.sessionId,
        req.readingId,
        for (final r in req.relationships) r.evidenceId,
        for (final r in req.recurringCards) r.evidenceId,
        for (final t in req.recurringThemes) t.evidenceId,
      }..removeWhere((s) => s.isEmpty);

      final backendValid = call['backendValid'] == true;
      final raw = call['structuredResult'];
      if (!backendValid || raw is! Map) {
        call['clientParsePass'] = false;
        call['narrativeQualityPass'] = false;
        call['aiOutputQualityPass'] = false;
        call['assessStatus'] = 'skipped_no_structured';
        call['internalIdLeak'] = false;
        continue;
      }
      final resultMap = Map<String, dynamic>.from(raw);
      final assessment = NarrativeTarotShadowResultAssessor.assess(
        request: req,
        rawResult: resultMap,
        requestId: 'qa6e2_${call['manifestId']}',
        sessionId: req.sessionId,
        generatedAt: at,
      );
      final parseOk =
          assessment.status != NarrativeTarotShadowAssessStatus.parseFailure;
      final narrativeOk = assessment.status !=
              NarrativeTarotShadowAssessStatus.parseFailure &&
          assessment.status !=
              NarrativeTarotShadowAssessStatus.narrativeEvidenceFailure;
      final aiOk = assessment.isPass;
      if (parseOk) parsePass++;
      if (narrativeOk) narrativePass++;
      if (aiOk) aiPass++;

      final text = visibleText(resultMap);
      var leak = false;
      for (final id in secretIds) {
        if (text.contains(id)) leak = true;
      }
      for (final n in _idLeakNeedles) {
        if (n == 'mem_') {
          if (RegExp(r'\bmem_').hasMatch(text)) leak = true;
        } else if (text.contains(n)) {
          leak = true;
        }
      }
      if (leak) leaks++;

      call['clientParsePass'] = parseOk;
      call['narrativeQualityPass'] = narrativeOk;
      call['aiOutputQualityPass'] = aiOk;
      call['assessStatus'] = assessment.status.name;
      call['internalIdLeak'] = leak;
      call['languageCodeExact'] =
          resultMap['languageCode'] == entry['languageCode'];
    }

    root['clientParserPasses'] = parsePass;
    root['narrativeQualityPasses'] = narrativePass;
    root['aiOutputQualityPasses'] = aiPass;
    root['internalIdLeaksFound'] = leaks > 0;
    root['calls'] = calls;

    File(_resultsPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(root),
    );

    // Replay gate: every backend-valid call must at least parse.
    expect(parsePass, 6);
    expect(leaks, 0);
  });
}
