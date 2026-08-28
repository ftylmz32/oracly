/// Ritual presentation smoke tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/ritual/deck_visual_state.dart';
import 'package:oracly_new/features/tarot/ritual/gestures/ritual_draw_gesture.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/shared/constants/tarot_routes.dart';

void main() {
  test('DeckVisualState is presentation-only copyable', () {
    const a = DeckVisualState(stage: TarotRitualStage.shuffle);
    final b = a.copyWith(shuffleProgress: 0.5, stage: TarotRitualStage.cut);
    expect(b.stage, TarotRitualStage.cut);
    expect(b.shuffleProgress, 0.5);
    expect(a.stage, TarotRitualStage.shuffle);
  });

  test('draw commit threshold is physical pull distance', () {
    expect(RitualDrawThreshold.commitPx, greaterThanOrEqualTo(80));
    expect(RitualDrawThreshold.commitPx, lessThanOrEqualTo(140));
  });

  test('new ritual routes exist', () {
    expect(TarotRoutes.intention, contains('intention'));
    expect(TarotRoutes.spreadSelection, contains('spread'));
  });
}
