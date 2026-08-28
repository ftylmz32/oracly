/// Single-table drag physics and continuity tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/ritual/gestures/ritual_draw_gesture.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_actor.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_math.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';

void main() {
  test('commit threshold remains ~96px', () {
    expect(RitualDrawThreshold.commitPx, 96);
  });

  test('top card lift and tilt constants are restrained', () {
    expect(CardFlightActorState.liftPx, inInclusiveRange(6, 10));
    expect(CardFlightActorState.maxTiltRad, lessThan(0.2));
    expect(CardFlightMath.liftPx, CardFlightActorState.liftPx);
  });

  test('3-card slot labels order is past-present-future', () {
    expect(RitualSpreadSlots.labels3, ['GEÇMİŞ', 'ŞİMDİ', 'GELECEK']);
  });
}
