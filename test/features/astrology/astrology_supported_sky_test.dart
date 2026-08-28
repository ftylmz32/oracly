/// Astrology final visual — real data only, text off the instrument.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_supported_sky.dart';

void main() {
  test('supported sky defaults to Sun only — no invented Moon/planets', () {
    const sky = AstrologySupportedSky(sunSignId: 'leo');
    expect(sky.hasMoon, isFalse);
    expect(sky.planetSignIds, isEmpty);
    expect(sky.hasPlanet('mars'), isFalse);
  });

  test('moon and planets appear only when supplied', () {
    const sky = AstrologySupportedSky(
      sunSignId: 'leo',
      moonSignId: 'cancer',
      planetSignIds: {'mars': 'aries'},
    );
    expect(sky.hasMoon, isTrue);
    expect(sky.hasPlanet('mars'), isTrue);
    expect(sky.hasPlanet('venus'), isFalse);
  });
}
