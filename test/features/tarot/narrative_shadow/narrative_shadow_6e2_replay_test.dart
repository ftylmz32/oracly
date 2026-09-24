/// Phase 6E.2 historical evidence integrity under Result Contract V2.
/// Does NOT rewrite the immutable 6E.2 fixture. Does NOT claim writing quality.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_prose_quality.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_error.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';

const _resultsPath =
    'test/fixtures/tarot_narrative_provider_shadow_results_6e2.json';

void main() {
  test('historical 6E.2 v1 results rejected by v2 parser; Call #4 prophecy FAIL', () {
    final before = File(_resultsPath).readAsStringSync();
    final root = jsonDecode(before) as Map<String, dynamic>;
    expect(root['used'], 6);
    expect(root['qaRunHead'], '3987f7a7851ba24b27ab58b36d3c0f2c3f04025b');
    final calls = (root['calls'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(calls.length, 6);

    for (final call in calls) {
      final raw = Map<String, dynamic>.from(call['structuredResult'] as Map);
      expect(raw['contractVersion'], 1);
      expect(
        () => NarrativeTarotResultParser.parse(raw),
        throwsA(
          isA<NarrativeTarotResultException>().having(
            (e) => e.kind,
            'kind',
            NarrativeTarotResultErrorKind.version,
          ),
        ),
        reason: '${call['manifestId']}',
      );
    }

    final call4 = calls.firstWhere((c) => c['callNumber'] == 4);
    final s = Map<String, dynamic>.from(call4['structuredResult'] as Map);
    final prose = StringBuffer()
      ..writeln(s['synthesis'])
      ..writeln(
        (s['relationshipInsights'] as List)
            .map((e) => (e as Map)['text'])
            .join('\n'),
      );
    expect(
      NarrativeTarotProseQuality.firstDeterministicFutureHit(
        prose.toString(),
        languageCode: 'en',
      ),
      isNotNull,
    );

    final call6 = calls.firstWhere((c) => c['callNumber'] == 6);
    final mem = (call6['structuredResult'] as Map)['memoryInsights'] as List;
    expect((mem.first as Map).containsKey('memoryIndex'), isTrue);
    expect((mem.first as Map).containsKey('memoryIndices'), isFalse);

    // Fixture bytes unchanged after test.
    expect(File(_resultsPath).readAsStringSync(), before);
  });
}
