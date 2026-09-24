/// Phase 6E.6 — client assessor enrichment + replay for Manifest V2 results.
/// Does not claim writing quality. Does not call providers.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_prose_quality.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_result_assessor.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import '../narrative_result/phase6e3_enrich_support.dart';

const _resultsPath =
    'test/fixtures/tarot_narrative_provider_shadow_results_6e6_v2.json';
const _qaRunHead = '8a33915e0462438f21c3b74c0d6fd7f787c78730';

const _leakNeedles = [
  'sessionId',
  'readingId',
  'ownerId',
  'evidenceId',
  'sourceId',
  'supportingReadingIds',
  'rel_',
  'rec_card_',
  'rec_theme_',
  'mem_',
];

TarotNarrativeRequest _requestFor(Map<String, dynamic> call) {
  final id = call['manifestId'] as String;
  if (id == 'psm_v2_06_enriched_multi_memory_en') {
    return enrichedProviderQaRequest();
  }
  const map = {
    'psm_v2_01_single_open_en': 'single_open_fool_en',
    'psm_v2_02_single_guidance_tr_reversed': 'single_guidance_cups05r_tr',
    'psm_v2_03_single_relationship_ru': 'single_relationship_swords09r_ru',
    'psm_v2_04_three_contrast_en': 'three_contrast_exemplar_en',
    'psm_v2_05_five_conflict_ru': 'five_conflict_exemplar_ru',
  };
  return buildFromCorpusId(map[id]!);
}

Set<String> _tokens(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9а-яёçğıöşü\s]', caseSensitive: false), ' ')
    .split(RegExp(r'\s+'))
    .where((t) => t.length > 2)
    .toSet();

double _overlap(String a, String b) {
  final ta = _tokens(a);
  final tb = _tokens(b);
  if (ta.isEmpty || tb.isEmpty) return 0;
  final inter = ta.intersection(tb).length;
  return inter / (ta.length < tb.length ? ta.length : tb.length);
}

String _repetitionNote(Map<String, dynamic> s) {
  final pairs = <String, double>{
    'summary_synthesis': _overlap('${s['summary']}', '${s['synthesis']}'),
    'synthesis_advice': _overlap('${s['synthesis']}', '${s['advice']}'),
    'advice_closing': _overlap('${s['advice']}', '${s['closingMessage']}'),
    'summary_closing': _overlap('${s['summary']}', '${s['closingMessage']}'),
  };
  final max = pairs.values.fold<double>(0, (m, v) => v > m ? v : m);
  if (max >= 0.55) return 'repetitive';
  if (max >= 0.35) return 'mildly repetitive';
  return 'distinct';
}

bool _scanLeak(String text) {
  for (final n in _leakNeedles) {
    if (n == 'mem_') {
      if (RegExp(r'\bmem_').hasMatch(text)) return true;
    } else if (text.contains(n)) {
      return true;
    }
  }
  return false;
}

String _visibleProse(Map<String, dynamic> s) {
  final buf = StringBuffer()
    ..writeln(s['summary'])
    ..writeln(s['synthesis'])
    ..writeln(s['advice'])
    ..writeln(s['closingMessage']);
  for (final key in [
    'cardReadings',
    'relationshipInsights',
    'recurringCardInsights',
    'recurringThemeInsights',
    'memoryInsights',
    'lifeAreas',
  ]) {
    for (final item in (s[key] as List? ?? const [])) {
      buf.writeln((item as Map)['text']);
    }
  }
  return buf.toString();
}

Map<String, Object?> _qualityObservations(
  Map<String, dynamic> s,
  String language,
) {
  final prose = _visibleProse(s);
  final futureHit = NarrativeTarotProseQuality.firstDeterministicFutureHit(
    prose,
    languageCode: language,
  );
  final mindReading = RegExp(
    r"partner (feels|thinks|wants|intends)|your partner is |"
    r'партн[её]р (чувствует|думает|хочет)|партнёр точно',
    caseSensitive: false,
  ).hasMatch(prose);
  final objectiveRel = RegExp(
    r'your relationship is |the relationship is |'
    r'ваши отношения (есть|являются)|отношения определённо',
    caseSensitive: false,
  ).hasMatch(prose);
  return {
    'deterministicFutureFound': futureHit != null,
    'deterministicFuturePattern': futureHit,
    'mindReadingClaimFound': mindReading,
    'objectiveRelationshipClaimFound': objectiveRel,
  };
}

void main() {
  test('6E.6 enrich client assessment fields on captured results', () {
    final before = File(_resultsPath).readAsStringSync();
    final root = jsonDecode(before) as Map<String, dynamic>;
    expect(root['qaRunHead'], _qaRunHead);
    expect(root['manifestVersion'], 2);
    expect(root['resultContractVersion'], 2);
    expect(root['usedCalls'], 6);
    expect(root['autoRetries'], 0);

    final calls = (root['calls'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(calls.length, 6);

    // Idempotent: only enrich once when client fields are absent.
    final needsEnrich = calls.any((c) => !c.containsKey('clientParsePass'));
    final at = DateTime.utc(2026, 9, 24, 19);
    var clientParse = 0;
    var narrativeQ = 0;
    var aiQ = 0;
    var leaks = 0;

    for (final call in calls) {
      if (!needsEnrich) {
        if (call['clientParsePass'] == true) clientParse++;
        if (call['narrativeQualityPass'] == true) narrativeQ++;
        if (call['aiOutputQualityPass'] == true) aiQ++;
        if (call['internalIdLeak'] == true) leaks++;
        continue;
      }
      final raw = call['structuredResult'];
      if (raw is! Map) {
        call['clientParsePass'] = false;
        call['narrativeQualityPass'] = false;
        call['aiOutputQualityPass'] = false;
        call['assessStatus'] = 'transport_or_backend_failure';
        call['internalIdLeak'] = false;
        call['repetitionObservation'] = 'n/a';
        call['memoryProvenanceNotes'] = 'n/a — no structured result';
        continue;
      }
      final map = Map<String, dynamic>.from(raw);
      expect(map['contractVersion'], 2);
      final req = _requestFor(call);
      final assessment = NarrativeTarotShadowResultAssessor.assess(
        request: req,
        rawResult: map,
        requestId: 'qa6e6_${call['callNumber']}',
        sessionId: req.sessionId,
        generatedAt: at,
      );
      final parseOk =
          assessment.status != NarrativeTarotShadowAssessStatus.parseFailure;
      final narrOk = assessment.status !=
          NarrativeTarotShadowAssessStatus.narrativeEvidenceFailure;
      final aiOk =
          assessment.status == NarrativeTarotShadowAssessStatus.pass;
      call['clientParsePass'] = parseOk;
      call['narrativeQualityPass'] = narrOk && parseOk;
      call['aiOutputQualityPass'] = aiOk;
      call['assessStatus'] = assessment.status.name;
      if (parseOk) clientParse++;
      if (call['narrativeQualityPass'] == true) narrativeQ++;
      if (aiOk) aiQ++;

      final encoded = jsonEncode(map);
      final leak = _scanLeak(encoded);
      call['internalIdLeak'] = leak;
      if (leak) leaks++;
      call['repetitionObservation'] = _repetitionNote(map);
      call['repetitionOverlaps'] = {
        'summary_synthesis': _overlap(
          '${map['summary']}',
          '${map['synthesis']}',
        ),
        'synthesis_advice':
            _overlap('${map['synthesis']}', '${map['advice']}'),
        'advice_closing':
            _overlap('${map['advice']}', '${map['closingMessage']}'),
        'summary_closing':
            _overlap('${map['summary']}', '${map['closingMessage']}'),
      };
      final memInsights = map['memoryInsights'] as List? ?? const [];
      call['memoryProvenanceNotes'] = {
        'insightCount': memInsights.length,
        'indices': [
          for (final m in memInsights) (m as Map)['memoryIndices'],
        ],
        'requestMemoryEntryCount': call['memoryEntryCount'],
        'summariesAdjacent': call['memorySummariesForQa'],
      };
      final observations = _qualityObservations(
        map,
        call['languageCode'] as String? ?? 'en',
      );
      call['deterministicFutureFound'] =
          observations['deterministicFutureFound'];
      call['deterministicFuturePattern'] =
          observations['deterministicFuturePattern'];
      call['mindReadingClaimFound'] = observations['mindReadingClaimFound'];
      call['objectiveRelationshipClaimFound'] =
          observations['objectiveRelationshipClaimFound'];
    }

    if (needsEnrich) {
      root['clientParserPasses'] = clientParse;
      root['narrativeQualityPasses'] = narrativeQ;
      root['aiOutputQualityPasses'] = aiQ;
      root['internalIdLeaksFound'] = leaks > 0;
      root['transportSuccesses'] =
          calls.where((c) => c['transportStatus'] == 'ok').length;
      root['backendStructuredPasses'] =
          calls.where((c) => c['backendValid'] == true).length;
      root['backendQualityRejections'] = calls
          .where((c) => c['backendQualityRejection'] != null)
          .length;
      root['calls'] = calls;
      File(_resultsPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(root),
      );
    } else {
      expect(root['clientParserPasses'], clientParse);
      expect(root.containsKey('transportSuccesses'), isTrue);
    }
  });

  test('6E.6 replay — typed failures preserved; no fabricated results', () {
    final root = jsonDecode(File(_resultsPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(root['qaRunHead'], _qaRunHead);
    expect(root['usedCalls'], 6);
    expect(root['remaining'], 0);
    final calls = root['calls'] as List;
    for (final raw in calls) {
      final c = Map<String, dynamic>.from(raw as Map);
      if (c['backendValid'] != true) {
        expect(c['structuredResult'], isNull);
        expect(c['typedFailure'], isA<Map>());
        expect((c['typedFailure'] as Map)['code'], isNotNull);
      } else {
        expect(c['structuredResult'], isA<Map>());
        expect(
          (c['structuredResult'] as Map)['contractVersion'],
          2,
        );
        expect(c['clientParsePass'], isTrue);
      }
    }
  });
}
