/// The 16 Oct 2026 provider reading fails voice. A local rewrite is not a pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_validator.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_voice.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_voice_scan.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'corpus/yildizname_captured_chart.dart';
import 'corpus/yildizname_target_portrait_example.dart';

void main() {
  late Map<String, dynamic> capturedMap;
  late YildiznameNarrativeStructuredResult captured;

  setUpAll(() {
    final raw = File(
      'test/features/star_map/narrative/corpus/yildizname_captured_ai_20261016.json',
    ).readAsStringSync();
    capturedMap = jsonDecode(raw) as Map<String, dynamic>;
    captured = YildiznameResultParser.parse(capturedMap);
  });

  test('captured report fails several independent voice signals', () {
    final report = YildiznameQualityVoice.inspect(
      YildiznameNarrativeScope.full,
      captured,
    );
    expect(
      report.findings,
      containsAll(const [
        'length',
        'sectionSprawl',
        'technicalCenter',
        'jargonDensity',
        'hedgeDensity',
        'repetition',
        'abstractPile',
        'reportOpening',
      ]),
      reason: report.toString(),
    );
  });

  test('removing hedge verbs leaves jargon, length, and sprawl', () {
    final result = YildiznameResultParser.parse(
      _mapTexts(capturedMap, _stripHedges),
    );
    final report = YildiznameQualityVoice.inspect(
      YildiznameNarrativeScope.full,
      result,
    );
    expect(report.findings, containsAll(const [
      'jargonDensity',
      'length',
      'sectionSprawl',
    ]), reason: report.toString());
    expect(report.findings, isNot(equals(const ['hedgeDensity'])));
  });

  test('stuffing one everyday noun into the report does not save it', () {
    final stuffed = _mapTexts(capturedMap, (t) => t);
    final summary = stuffed['summary'] as Map<String, dynamic>;
    summary['text'] = '${summary['text']} Bir toplantı, bir mesaj, sabah.';
    final report = YildiznameQualityVoice.inspect(
      YildiznameNarrativeScope.full,
      YildiznameResultParser.parse(stuffed),
    );
    expect(report.findings, containsAll(const [
      'technicalCenter',
      'jargonDensity',
    ]));
  });

  test('full gate rejects the capture at voice, after earlier stages', () {
    expect(
      () => YildiznameQualityValidator.validate(
        request: leoSocialChart(captured.allFactRefs),
        result: captured,
      ),
      throwsA(
        isA<YildiznameResultException>()
            .having((e) => e.kind, 'kind', YildiznameResultErrorKind.prose)
            .having((e) => e.message, 'message', contains('voice:')),
      ),
    );
  });

  test('TARGET EXAMPLE clears structure and is not a live provider pass', () {
    expect(kYildiznameLiveProductQualityVerified, isFalse);
    expect(kYildiznameTargetExampleLabel, 'HEDEF ANLATIM ÖRNEĞİ');
    final example = yildiznameTargetPortraitExample();
    final words = YildiznameVoiceScan.words(example.visibleProse);
    expect(words, inInclusiveRange(400, 550), reason: 'words=$words');
    final report = YildiznameQualityVoice.inspect(
      YildiznameNarrativeScope.full,
      example,
    );
    expect(report.findings, isEmpty, reason: report.toString());
    YildiznameQualityValidator.validate(
      request: leoSocialChart({...captured.allFactRefs, ...example.allFactRefs}),
      result: example,
    );
  });
}

Map<String, dynamic> _mapTexts(
  Map<String, dynamic> source,
  String Function(String) edit,
) {
  final copy = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  final summary = copy['summary'] as Map<String, dynamic>;
  summary['text'] = edit(summary['text'] as String);
  for (final section in copy['sections'] as List) {
    final block = section as Map<String, dynamic>;
    block['text'] = edit(block['text'] as String);
  }
  copy['closingMessage'] = edit(copy['closingMessage'] as String);
  final prompt = copy['reflectionPrompt'];
  if (prompt is String) copy['reflectionPrompt'] = edit(prompt);
  return copy;
}

String _stripHedges(String text) => text.replaceAll(
      RegExp(
        r'olabilir|edebilir|gösterebilir|düşündürüyor|gösteriyor|görünüyor|'
        r'verebilir|isteyebilir|sağlayabilir',
        caseSensitive: false,
      ),
      'durur',
    );
