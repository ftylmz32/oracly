/// Phase E1 — Coffee/Palm grounding + Soulmate parser + error code mapping.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/models/soul_mate_ai_portrait.dart';
import 'package:oracly_new/features/ai/production/openai/palm_vision_parser.dart';
import 'package:oracly_new/features/ai/production/transport/ai_error_mapper.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_parser.dart';

void main() {
  test('coffee parser requires grounded visualObservation', () {
    final ok = CoffeeReadingParser.parse(
      jsonEncode({
        'gorselTespit': 'Dipte ince izler, duvarda bir küme.',
        'genelYorum': 'Sakin duruluş; izler birlikte yumuşak okunuyor.',
        'sonuc': 'Yavaş ol.',
      }),
      id: 'e1c',
      createdAt: DateTime(2026, 9, 2),
    );
    expect(ok, isNotNull);
    expect(ok!.visualObservation, contains('Dipte'));

    expect(
      CoffeeReadingParser.parse(
        jsonEncode({
          'genelYorum': 'Sakin bir fincan.',
          'sonuc': 'Yavaş ol.',
        }),
        id: 'e1c-bad',
        createdAt: DateTime(2026, 9, 2),
      ),
      isNull,
    );

    expect(
      CoffeeReadingParser.parse(
        jsonEncode({
          'usable': false,
          'gorselTespit': 'Dipte ince izler, duvarda bir küme.',
          'genelYorum': 'Sakin duruluş; izler birlikte yumuşak okunuyor.',
          'sonuc': 'Yavaş ol.',
        }),
        id: 'e1c-unusable',
        createdAt: DateTime(2026, 9, 2),
      ),
      isNull,
    );
  });

  test('palm parser requires grounded visualObservation', () {
    final ok = PalmVisionParser.fromMap({
      'gorselTespit': 'Açık avuç; ana çizgiler net görünüyor.',
      'genelYapi': 'Avuç açık ve sakin bir ritim taşıyor.',
      'sonuc': 'Sembolik bir yansıma.',
    });
    expect(ok, isNotNull);

    expect(
      PalmVisionParser.fromMap({
        'genelYapi': 'Avuç açık ve sakin bir ritim taşıyor.',
        'sonuc': 'Sembolik bir yansıma.',
      }),
      isNull,
    );
  });

  test('soulmate portrait rejects malformed base64 and accepts PNG', () {
    expect(SoulMateAiPortrait.tryFromBase64('not-base64!!!'), isNull);
    expect(SoulMateAiPortrait.tryFromBase64(''), isNull);
    const tinyPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final portrait = SoulMateAiPortrait.tryFromBase64(tinyPng);
    expect(portrait, isNotNull);
    expect(portrait!.mimeType, 'image/png');
  });

  test('error mapper covers E1 typed codes', () {
    expect(
      AiErrorMapper.fromCode('invalid_image').kind,
      AiFailureKind.invalidResponse,
    );
    expect(
      AiErrorMapper.fromCode('unsupported_image_type').kind,
      AiFailureKind.invalidResponse,
    );
    expect(
      AiErrorMapper.fromCode('image_too_large').kind,
      AiFailureKind.invalidResponse,
    );
    expect(
      AiErrorMapper.fromCode('app_check_required').kind,
      AiFailureKind.appCheck,
    );
    expect(
      AiErrorMapper.fromCode('authentication_required').kind,
      AiFailureKind.unauthorized,
    );
    expect(
      AiErrorMapper.fromCode('provider_timeout').kind,
      AiFailureKind.timeout,
    );
    expect(
      AiErrorMapper.fromCode('moderation_blocked').kind,
      AiFailureKind.invalidResponse,
    );
    expect(
      AiErrorMapper.fromCode('image_analysis_unavailable').kind,
      AiFailureKind.imageAnalysisUnavailable,
    );
  });
}