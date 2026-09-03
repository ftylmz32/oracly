/// Reveal hero — resting deck plus the rising, turning card.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../deck/physical_deck_stack.dart';
import 'card_reveal_spread.dart';
import 'reveal_ambience_layer.dart';
import 'reveal_flip_card.dart';
import 'reveal_timeline.dart';

class CardRevealHero extends StatelessWidget {
  const CardRevealHero({super.key, required this.progress, required this.data});

  final double progress;
  final RevealCardData data;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    final floatY = RevealTimeline.floatUp(t) + RevealTimeline.floatIdle(t);
    return SizedBox(
      width: 360,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RevealAmbienceLayer(
              progress: t,
              fogIntensity: RevealTimeline.fogRichness(t),
              particleSpeed: RevealTimeline.particleSpeed(t),
              glowIntensity: RevealTimeline.glowBehind(t),
              particlePhase: t * pi * 2 * RevealTimeline.particleDrift(t),
              stillness: RevealTimeline.anticipationStillness(t),
              orbFocus: RevealTimeline.orbFocus(t),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, RevealTimeline.deckRestY),
            child: PhysicalDeckStack(
              width: 168,
              height: 268,
              opacity: RevealTimeline.originDeckOpacity(t),
            ),
          ),
          Transform.translate(
            offset: Offset(0, floatY),
            child: RevealFlipCard(
              data: data,
              flipRotation: RevealTimeline.flipRotation(t),
              tilt3D: RevealTimeline.tilt3D(t),
              perspectiveTiltY: RevealTimeline.perspectiveTiltY(t),
              borderEnergy: RevealTimeline.borderEnergy(t),
              landScale: RevealTimeline.landScale(t),
              shadowDepth: RevealTimeline.shadowDepth(t),
              goldOpacity: RevealTimeline.frontGoldOpacity(t),
              artOpacity: RevealTimeline.frontArtOpacity(t),
              particlePhase: t * pi * 2 * RevealTimeline.particleDrift(t),
            ),
          ),
        ],
      ),
    );
  }
}
