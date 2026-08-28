/// Chamber transition personalities stay distinct and within soft motion bounds.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/navigation/immersive/chamber_transition_personality.dart';
import 'package:oracly_new/core/navigation/immersive/immersive_transition.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation_scope.dart';

void main() {
  test('feature personalities stay ceremonial-to-quiet without hard cuts', () {
    final tarot = ChamberTransitionTokens.of(ChamberTransitionPersonality.tarot);
    final or = ChamberTransitionTokens.of(
      ChamberTransitionPersonality.orPresence,
    );
    final coffee =
        ChamberTransitionTokens.of(ChamberTransitionPersonality.coffee);
    final astrology =
        ChamberTransitionTokens.of(ChamberTransitionPersonality.astrology);
    final soul =
        ChamberTransitionTokens.of(ChamberTransitionPersonality.soulMate);

    expect(tarot.enter.inMilliseconds, greaterThan(or.enter.inMilliseconds));
    expect(or.mode, ImmersiveTransitionMode.fade);
    expect(tarot.mode, ImmersiveTransitionMode.depth);
    expect(soul.mode, ImmersiveTransitionMode.light);
    expect(coffee.scaleBegin, lessThan(1));
    expect(astrology.translatePx, greaterThan(coffee.translatePx));
    expect(OraclyTab.coffee.chamberPersonality,
        ChamberTransitionPersonality.orPresence);
    expect(OraclyTab.astrology.chamberPersonality,
        ChamberTransitionPersonality.coffee);
    expect(OraclyTab.starMap.chamberPersonality,
        ChamberTransitionPersonality.chamber);
  });
}
