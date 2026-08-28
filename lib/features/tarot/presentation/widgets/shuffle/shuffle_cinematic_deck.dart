/// Cinematic stacked deck — overhand ritual, optional cut.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'shuffle_cinematic_packet.dart';
import 'shuffle_timeline.dart';

class ShuffleCinematicDeck extends StatelessWidget {
  const ShuffleCinematicDeck({
    super.key,
    required this.progress,
    this.cutProgress = 0,
    this.cardCount = 8,
    this.cardWidth = 78,
    this.cardHeight = 128,
  });

  final double progress;
  final double cutProgress;
  final int cardCount;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final zoom = ShuffleTimeline.cameraZoom(progress);
    final panY = ShuffleTimeline.cameraPanY(progress);
    final lift = ShuffleTimeline.deckLift(progress);
    final spread = ShuffleTimeline.separation(progress);
    final shuffleEnv = ShuffleTimeline.shuffleEnvelope(progress);
    final shuffleT = ShuffleTimeline.shufflePhase(progress);
    final glow = ShuffleTimeline.glowPulse(progress);
    final settle = ShuffleTimeline.settleScale(progress);

    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, panY + lift),
        child: Transform.scale(
          scale: zoom * settle,
          child: SizedBox(
            width: 300,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _DeckBaseGlow(intensity: 0.28 + glow * 0.38),
                for (var i = 0; i < cardCount; i++)
                  ShuffleCinematicPacket(
                    index: i,
                    total: cardCount,
                    spread: spread,
                    shuffleEnv: shuffleEnv,
                    shuffleT: shuffleT,
                    cutProgress: cutProgress,
                    trail: ShuffleTimeline.trail(progress),
                    width: cardWidth,
                    height: cardHeight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckBaseGlow extends StatelessWidget {
  const _DeckBaseGlow({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 188,
        height: 86,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.20 * intensity),
              blurRadius: 44,
              spreadRadius: 6,
            ),
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.16 * intensity),
              blurRadius: 26,
            ),
          ],
        ),
      ),
    );
  }
}
