/// Regression: IEEE float must not feed Curve.transform outside [0,1].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/motion/tarot_cinematic_motion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_intro_phase.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_animations.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_timeline.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_selection/sacred_moment.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/shuffle/shuffle_timeline.dart';

void main() {
  const samples = <double>[
    -0.0000000000000002,
    0.0,
    0.16,
    0.52,
    0.78,
    0.82,
    0.9999999999999998,
    1.0,
    1.0000000000000002,
    (1.0 - 0.82) / 0.18,
    0.32 / 0.32,
  ];

  test('SacredMoment.progress stays Curve-safe at exact 1.0', () {
    expect(() => SacredMoment.progress(1.0), returnsNormally);
    expect(() => SacredMoment.progress(1.0000000000000002), returnsNormally);
    for (var i = 0; i <= 1000; i++) {
      expect(() => SacredMoment.progress(i / 1000), returnsNormally);
    }
  });

  test('TarotCinematicMotion.unit clamps IEEE overshoot', () {
    expect(TarotCinematicMotion.unit((1.0 - 0.82) / 0.18), 1.0);
    expect(
      () => TarotCinematicMotion.curve(
        Curves.easeOutCubic,
        (1.0 - 0.82) / 0.18,
      ),
      returnsNormally,
    );
  });

  test('reveal / shuffle / reading timelines stay Curve-safe at endpoints', () {
    for (final t in samples) {
      expect(() => RevealTimeline.darken(t), returnsNormally);
      expect(() => RevealTimeline.flipRotation(t), returnsNormally);
      expect(() => RevealTimeline.anticipationStillness(t), returnsNormally);
      expect(() => RevealTimeline.ambientDeepen(t), returnsNormally);
      expect(() => RevealTimeline.orbFocus(t), returnsNormally);
      expect(() => RevealTimeline.cameraZoom(t), returnsNormally);
      expect(() => RevealTimeline.floatUp(t), returnsNormally);
      expect(() => RevealTimeline.frontArtOpacity(t), returnsNormally);
      expect(() => RevealTimeline.buttonOpacity(t), returnsNormally);
      expect(() => RevealTimeline.fogRichness(t), returnsNormally);
      expect(() => RevealTimeline.glowBehind(t), returnsNormally);
      expect(() => ShuffleTimeline.deckLift(t), returnsNormally);
      expect(() => ShuffleTimeline.fogIntensity(t), returnsNormally);
      expect(() => ShuffleTimeline.messageOpacity(t), returnsNormally);
      expect(() => ShuffleTimeline.settleScale(t), returnsNormally);
      expect(() => ReadingIntroTimeline.introOpacity(t), returnsNormally);
      expect(() => readingPremiumFooterProgress(t), returnsNormally);
      expect(() => readingPremiumSectionProgress(0, t), returnsNormally);
      expect(() => SacredMoment.chromeFade(t), returnsNormally);
      expect(() => SacredMoment.orbGather(t), returnsNormally);
      expect(() => SacredMoment.revealHandoff(t), returnsNormally);
    }
  });
}
