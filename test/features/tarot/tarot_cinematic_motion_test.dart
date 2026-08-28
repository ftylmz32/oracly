/// Cinematic tarot motion language — timing, physics, reduced motion.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/motion/tarot_cinematic_motion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_animations.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_timeline.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/shuffle/shuffle_timeline.dart';

void main() {
  test('ritual durations stay in the cinematic bands', () {
    expect(TarotCinematicMotion.micro.inMilliseconds, inInclusiveRange(120, 180));
    expect(
      TarotCinematicMotion.interaction.inMilliseconds,
      inInclusiveRange(200, 350),
    );
    expect(
      TarotCinematicMotion.cardMove.inMilliseconds,
      inInclusiveRange(350, 700),
    );
    expect(
      TarotCinematicMotion.shuffle.inMilliseconds,
      inInclusiveRange(900, 1400),
    );
    expect(
      TarotCinematicMotion.flip.inMilliseconds,
      inInclusiveRange(650, 900),
    );
    expect(
      TarotCinematicMotion.backNav.inMilliseconds,
      inInclusiveRange(200, 300),
    );
  });

  test('shuffle envelope lifts, interleaves, then settles without a zero scale', () {
    expect(ShuffleTimeline.deckLift(0.12), lessThan(0));
    expect(ShuffleTimeline.separation(0.20), greaterThan(0.05));
    expect(ShuffleTimeline.shuffleEnvelope(0.42), greaterThan(0.4));
    expect(ShuffleTimeline.trail(0.40), greaterThan(0.2));
    expect(ShuffleTimeline.settleScale(0), 1);
    expect(ShuffleTimeline.settleScale(1), closeTo(1, 0.02));
    expect(ShuffleTimeline.cameraZoom(0.5), lessThan(1.04));
  });

  test('flip is a Y-axis turn with depth at 90 degrees, not a scaleX squash', () {
    expect(RevealTimeline.flipRotation(RevealTimeline.flipStart), 0);
    expect(RevealTimeline.flipRotation(1), closeTo(pi, 0.02));
    final mid = (RevealTimeline.flipStart + RevealTimeline.flipEnd) / 2;
    expect(RevealTimeline.flipRotation(mid), closeTo(pi / 2, 0.2));
    expect(RevealTimeline.flipDepth(mid), greaterThan(10));
    expect(RevealTimeline.flipDepth(RevealTimeline.flipStart), closeTo(0, 0.2));
    expect(RevealTimeline.totalDuration, TarotCinematicMotion.majorReveal);
  });

  test('reading copy arrives as title, narrative, then guidance', () {
    expect(readingPremiumHeaderProgress(0.14), closeTo(1, 0.02));
    expect(readingPremiumSectionProgress(0, 0.10), 0);
    expect(readingPremiumSectionProgress(0, 0.40), greaterThan(0.8));
    expect(readingPremiumGuidanceProgress(0.50), 0);
    expect(readingPremiumGuidanceProgress(0.90), closeTo(1, 0.02));
    expect(readingStoryArrive(0, 0.20), greaterThan(readingStoryArrive(1, 0.20)));
    expect(readingStorySettle(0, 1, 3), 1);
  });

  test('overshoot never collapses the first frame', () {
    expect(TarotCinematicMotion.overshoot(0), 0);
    expect(TarotCinematicMotion.overshoot(1), closeTo(1, 0.02));
    expect(TarotCinematicMotion.overshoot(0.59), greaterThan(1));
  });

  testWidgets('reduced motion skips the chamber entrance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(
                TarotCinematicMotion.of(
                  context,
                  TarotCinematicMotion.shuffle,
                ),
                Duration.zero,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}
