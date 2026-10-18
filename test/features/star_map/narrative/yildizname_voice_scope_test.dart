/// Voice length by scope, and the existing short corpus stays valid.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_voice.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

import 'corpus/narrative_result_corpus.dart';

void main() {
  test('legacy, reduced, and full corpus fixtures stay under the voice gate', () {
    for (final map in [
      NarrativeResultCorpus.legacyTr(),
      NarrativeResultCorpus.reducedEn(),
      NarrativeResultCorpus.fullEn(),
      NarrativeResultCorpus.fullTr(),
      NarrativeResultCorpus.fullRu(),
    ]) {
      final result = YildiznameResultParser.parse(map);
      final report = YildiznameQualityVoice.inspect(result.scope, result);
      expect(report.findings, isEmpty, reason: '${result.languageCode} $report');
    }
  });

  test('a short legacy or reduced portrait passes; padding fails length', () {
    expect(_findings(YildiznameNarrativeScope.legacy, 80), isEmpty);
    expect(
      _findings(YildiznameNarrativeScope.legacy, 300),
      contains('length'),
    );
    expect(_findings(YildiznameNarrativeScope.reduced, 140), isEmpty);
    expect(
      _findings(YildiznameNarrativeScope.reduced, 420),
      contains('length'),
    );
    expect(
      _findings(YildiznameNarrativeScope.full, 200),
      isEmpty,
    );
  });
}

List<String> _findings(YildiznameNarrativeScope scope, int words) {
  const bank = [
    'sakin',
    'nehir',
    'masa',
    'pencere',
    'ekmek',
    'kitap',
    'yolcu',
    'lamba',
    'bardak',
    'perde',
  ];
  final text = List.generate(words, (i) => '${bank[i % bank.length]}$i').join(' ');
  final result = YildiznameNarrativeStructuredResult(
    contractVersion: kYildiznameResultContractVersion,
    languageCode: 'tr',
    scope: scope,
    summary: YildiznameNarrativeBlock(
      text: text,
      factRefs: const ['placement.sun'],
      themeRefs: const [],
    ),
    sections: [
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.coreIdentity,
        text: 'Kısa bir ikinci paragraf, dolguyu bölüm sayısına yaymamak için.',
        factRefs: const ['placement.sun'],
        themeRefs: const [],
      ),
    ],
    reflectionPrompt: null,
    closingMessage: 'Kapanış burada kalsın ve dolguya karışmasın.',
  );
  return YildiznameQualityVoice.inspect(scope, result).findings;
}
