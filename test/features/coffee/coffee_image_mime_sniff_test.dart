/// Coffee image mime sniff — avoid HEIC/mislabeled empty responses.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/ai/production/transport/ai_error_mapper.dart';
import 'package:oracly_new/features/ai/production/transport/coffee_image_limits.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';

void main() {
  test('sniffs jpeg magic over wrong claimed mime', () {
    final bytes = <int>[0xff, 0xd8, 0xff, ...List.filled(9000, 1)];
    expect(
      CoffeeImageLimits.resolveMime(
        bytes: bytes,
        claimedMime: 'image/heic',
      ),
      'image/jpeg',
    );
    expect(
      CoffeeImageLimits.validate(bytes: bytes, mimeType: 'image/heic'),
      isNull,
    );
  });

  test('rejects heic with honest image copy, not empty OR message', () {
    final bytes = <int>[
      0x00,
      0x00,
      0x00,
      0x18,
      ...'ftyp'.codeUnits,
      ...'heic'.codeUnits,
      ...List.filled(9000, 0),
    ];
    final failure = CoffeeImageLimits.validate(
      bytes: bytes,
      mimeType: 'image/jpeg',
    );
    expect(failure, isNotNull);
    expect(failure!.userMessage, CoffeeCopy.imageUnclear);
    expect(failure.userMessage, isNot(ResilienceCopy.aiEmptyResponse));
  });

  test('invalid_request maps to image copy not empty OR', () {
    final failure = AiErrorMapper.fromCode('invalid_request');
    expect(failure.userMessage, CoffeeCopy.imageUnclear);
  });
}
