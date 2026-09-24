/// Phase 6D — parser/quality red-team + enriched binding.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_quality_validator.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_error.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_structured_result.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import 'phase6d_test_support.dart';

void main() {
  test('parser rejects unknown keys and wrong version', () {
    final request = buildFromCorpusId('single_open_fool_en');
    final map = validResultMap(request);
    map['extra'] = 'nope';
    expect(
      () => NarrativeTarotResultParser.parse(map),
      throwsA(isA<NarrativeTarotResultException>()),
    );
    final map2 = validResultMap(request)..['contractVersion'] = 2;
    expect(
      () => NarrativeTarotResultParser.parse(map2),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.version,
        ),
      ),
    );
  });

  test('quality rejects wrong card / locale / leak', () {
    final request = buildFromCorpusId('three_contrast_exemplar_en');
    final ok = NarrativeTarotResultParser.parse(validResultMap(request));

    expect(
      () => NarrativeTarotQualityValidator.validate(
        request: request,
        result: copyResult(ok, languageCode: 'tr'),
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.locale,
        ),
      ),
    );

    final badCard = copyResult(
      ok,
      cardReadings: [
        for (final c in ok.cardReadings)
          NarrativeTarotCardReading(
            cardId: c.cardId,
            positionKey: 'wrong',
            text: c.text,
          ),
      ],
    );
    expect(
      () => NarrativeTarotQualityValidator.validate(
        request: request,
        result: badCard,
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.cardCoverage,
        ),
      ),
    );

    final leaked = copyResult(ok, summary: '${ok.summary} ${request.sessionId}');
    expect(
      () => NarrativeTarotQualityValidator.validate(
        request: request,
        result: leaked,
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.privateIdentifier,
        ),
      ),
    );

    final tokenLeak = copyResult(ok, summary: '${ok.summary} rel_01');
    expect(
      () => NarrativeTarotQualityValidator.validate(
        request: request,
        result: tokenLeak,
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.privateIdentifier,
        ),
      ),
    );
  });

  test('enriched history binding + mutation fail', () {
    final request = enrichedForSerialize();
    expect(request.recurringCards, isNotEmpty);
    expect(request.memory.included, isTrue);
    final map = validResultMap(request);
    final parsed = NarrativeTarotResultParser.parse(map);
    NarrativeTarotQualityValidator.validate(request: request, result: parsed);

    final fakeRec = copyResult(
      parsed,
      recurringCardInsights: [
        NarrativeTarotRecurringCardInsight(
          cardId: 'major_99',
          text: longProse(50),
        ),
      ],
    );
    expect(
      () => NarrativeTarotQualityValidator.validate(
        request: request,
        result: fakeRec,
      ),
      throwsA(
        isA<NarrativeTarotResultException>().having(
          (e) => e.kind,
          'kind',
          NarrativeTarotResultErrorKind.recurrenceEvidence,
        ),
      ),
    );
  });
}
