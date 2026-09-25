/// Phase 4 — longitude normalize / sign / degree unit tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';

void main() {
  test('normalize wraps 0 / 359.999 / 360 / negative', () {
    expect(LongitudeMath.normalize(0), 0);
    expect(LongitudeMath.normalize(359.999), closeTo(359.999, 1e-9));
    expect(LongitudeMath.normalize(360), 0);
    expect(LongitudeMath.normalize(-0.001), closeTo(359.999, 1e-9));
  });

  test('sign boundaries at 0 / 30 / 359.999', () {
    expect(LongitudeMath.signOf(0), ZodiacSignId.aries);
    expect(LongitudeMath.signOf(29.999), ZodiacSignId.aries);
    expect(LongitudeMath.signOf(30), ZodiacSignId.taurus);
    expect(LongitudeMath.signOf(359.999), ZodiacSignId.pisces);
  });

  test('degreeWithinSign remainder', () {
    expect(LongitudeMath.degreeWithinSign(0), 0);
    expect(LongitudeMath.degreeWithinSign(30.5), closeTo(0.5, 1e-9));
    expect(LongitudeMath.degreeWithinSign(359.5), closeTo(29.5, 1e-9));
  });
}
