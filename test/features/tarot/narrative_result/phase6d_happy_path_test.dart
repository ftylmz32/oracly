/// Phase 6D — wire + happy-path classical/locale fixtures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading/ai_output_quality_tarot.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_quality_validator.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_bridge.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_structured_result.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import 'phase6d_test_support.dart';

void main() {
  test('wire payload exact fields and no private ids', () {
    final request = buildFromCorpusId('three_contrast_exemplar_en');
    final payload = wirePayload(request);
    expect(
      payload.keys.toSet(),
      {'mode', 'contractVersion', 'language', 'narrative'},
    );
    expect(payload['mode'], 'narrative_v2');
    expect(payload['contractVersion'], 1);
    expect(payload['language'], 'en');
    final encoded = payload.toString();
    expect(encoded.contains('sessionId'), isFalse);
    expect(encoded.contains('readingId'), isFalse);
    expect(encoded.contains('evidenceId'), isFalse);
    expect(encoded.contains('ownerId'), isFalse);
    expect(encoded.contains('sourceId'), isFalse);
    expect(encoded.contains('ritualCardId'), isFalse);
    expect(encoded.contains('imageAsset'), isFalse);
  });

  test('classical single/three/five parse + quality + bridge + AiQuality', () {
    final cases = [
      buildFromCorpusId('single_open_fool_en'),
      buildFromCorpusId('three_contrast_exemplar_en'),
      buildFromCorpusId('five_support_exemplar_en'),
    ];
    final at = DateTime.utc(2026, 9, 24, 12);
    for (final request in cases) {
      final parsed = NarrativeTarotResultParser.parse(validResultMap(request));
      NarrativeTarotQualityValidator.validate(
        request: request,
        result: parsed,
      );
      final bridged = NarrativeTarotResultBridge.toInterpretationResult(
        request: request,
        result: parsed,
        requestId: 'req_6d',
        sessionId: 'sess_6d',
        generatedAt: at,
        source: InterpretationSource.ai,
      );
      expect(bridged.rawText, isNull);
      expect(AiOutputQualityTarot.passes(bridged), isTrue);
      expect(
        () => parsed.cardReadings.add(
          const NarrativeTarotCardReading(
            cardId: 'x',
            positionKey: 'y',
            text: 'z',
          ),
        ),
        throwsUnsupportedError,
      );
    }
  });

  test('TR EN RU locale fixtures', () {
    final fixtures = [
      buildFromCorpusId('single_guidance_cups05r_tr'),
      buildFromCorpusId('single_open_fool_en'),
      buildFromCorpusId('single_relationship_swords09r_ru'),
    ];
    for (final req in fixtures) {
      final map = validResultMap(req);
      final parsed = NarrativeTarotResultParser.parse(map);
      expect(parsed.languageCode, req.languageCode);
      NarrativeTarotQualityValidator.validate(request: req, result: parsed);
    }
  });

  test('bridge maps synthesis to luckyEnergy without DateTime.now', () {
    final request = buildFromCorpusId('single_open_fool_en');
    final parsed = NarrativeTarotResultParser.parse(validResultMap(request));
    final at = DateTime.utc(2020, 1, 2, 3, 4, 5);
    final bridged = NarrativeTarotResultBridge.toInterpretationResult(
      request: request,
      result: parsed,
      requestId: 'r',
      sessionId: 's',
      generatedAt: at,
    );
    expect(bridged.generatedAt, at);
    expect(bridged.luckyEnergy, parsed.synthesis);
    expect(bridged.health.contains(request.cards.first.displayName), isTrue);
    expect(bridged.love, isNotEmpty);
    expect(bridged.career, isEmpty);
  });
}
