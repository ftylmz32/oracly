/// In-fan pick flip — 3D turn after extract, before reveal handoff.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../motion/tarot_cinematic_motion.dart';
import '../card_reveal/card_reveal_spread.dart';
import '../card_reveal/reveal_flip_card.dart';
import '../card_reveal/reveal_timeline.dart';

class CardSelectionPickFlip extends StatelessWidget {
  const CardSelectionPickFlip({
    super.key,
    required this.data,
    required this.progress,
  });

  final RevealCardData data;

  /// 0 = face-down at rest · 1 = fully revealed.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final raw = progress.clamp(0.0, 1.0);
    final t = RevealTimeline.flipProgress(raw);
    final flip = t * pi;
    final scale = 1.0 + TarotCinematicMotion.overshoot(t, amount: 0.028) * 0.08;
    return Transform.scale(
      scale: scale,
      child: RevealFlipCard(
        data: data,
        flipRotation: flip,
        tilt3D: 0.07 * (1 - t) + 0.02 * (1 - (2 * t - 1).abs()),
        perspectiveTiltY: 0.05 * (0.5 - t).abs(),
        borderEnergy: RevealTimeline.borderEnergy(
          RevealTimeline.flipStart +
              t * (RevealTimeline.flipEnd - RevealTimeline.flipStart),
        ),
        landScale: 1,
        shadowDepth: 0.48 + t * 0.42,
        goldOpacity: t > 0.5 ? (t - 0.5) * 2 : 0,
        artOpacity: t > 0.52 ? ((t - 0.52) / 0.48).clamp(0.0, 1.0) : 0,
        particlePhase: t * pi,
        width: 92,
        height: 148,
      ),
    );
  }
}
