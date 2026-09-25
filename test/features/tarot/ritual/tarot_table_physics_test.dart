/// Single-table drag physics and continuity tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_resolver.dart';
import 'package:oracly_new/features/tarot/ritual/gestures/ritual_draw_gesture.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_actor.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_math.dart';

void main() {
  test('commit threshold remains ~96px', () {
    expect(RitualDrawThreshold.commitPx, 96);
  });

  test('top card lift and tilt constants are restrained', () {
    expect(CardFlightActorState.liftPx, inInclusiveRange(6, 10));
    expect(CardFlightActorState.maxTiltRad, lessThan(0.2));
    expect(CardFlightMath.liftPx, CardFlightActorState.liftPx);
  });

  test('3-card geometry keys are past-present-future', () {
    final spec =
        TarotSpreadGeometryResolver.resolve(TarotSpreadType.threeCard);
    expect(
      spec.slots.map((s) => s.positionKey).toList(),
      ['past', 'present', 'future'],
    );
  });
}
