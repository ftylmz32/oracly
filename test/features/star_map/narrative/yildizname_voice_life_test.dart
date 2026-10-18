/// Regressions for invented routines and novelistic voice.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_voice.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

void main() {
  test('a repeated "aynı" catalogue is an invented routine', () {
    const original =
        'Sabah aynı fincanı, aynı masayı, aynı sözü ararsın.';
    const swapped =
        'Akşam aynı bardağı, aynı sandalyeyi, aynı cümleyi beklersin olabilir.';
    expect(_findings(original), contains('inventedRoutine'));
    expect(_findings(swapped), contains('inventedRoutine'));
  });

  test('a clocked habit stays invented when the object changes', () {
    final report = _findings(
      'Her sabah aynı defteri açarsın ve buna güven duyarsın.',
    );
    expect(report, contains('inventedRoutine'));
  });

  test('a hypothetical plan change is not an invented routine', () {
    expect(
      _findings('Bir plan son anda değiştiğinde bu sana canlı gelebilir.'),
      isNot(contains('inventedRoutine')),
    );
  });

  test('a novel opening stays literary when the nouns change', () {
    const original =
        'Seni bir odaya aldıklarında, ilk fark edilen şey fikrin değil, '
        'odanın ısınması olur.';
    const swapped =
        'Seni bir masaya oturttuklarında, göze çarpan şey sözün değil, '
        'masanın yumuşaması olur.';
    expect(_findings(original), contains('literaryVoice'));
    expect(_findings(swapped), contains('literaryVoice'));
  });

  test('a direct tendency is neither invented nor literary', () {
    final plain = _findings(
      'İnsanlarla bir araya geldiğinde kendini göstermek senin için '
      'önemli bir tema. Ama görünür olmakla anlaşıldığını hissetmek '
      'aynı şey değil.',
    );
    expect(plain, isNot(contains('inventedRoutine')));
    expect(plain, isNot(contains('literaryVoice')));
    expect(
      _findings(
        'Bir şeyin sağlam ilerlemesi senin için önemli olabilir.',
      ),
      isEmpty,
    );
  });
}

List<String> _findings(String summary) {
  final result = YildiznameNarrativeStructuredResult(
    contractVersion: kYildiznameResultContractVersion,
    languageCode: 'tr',
    scope: YildiznameNarrativeScope.full,
    summary: YildiznameNarrativeBlock(
      text: summary,
      factRefs: const ['placement.sun'],
      themeRefs: const [],
    ),
    sections: [
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.coreIdentity,
        text: 'Kısa bir ikinci cümle burada ayrı bir anlam taşır.',
        factRefs: const ['placement.sun'],
        themeRefs: const [],
      ),
    ],
    reflectionPrompt: null,
    closingMessage: 'Kapanış sade kalsın.',
  );
  return YildiznameQualityVoice.inspect(
    YildiznameNarrativeScope.full,
    result,
  ).findings;
}
