/// OR-1030 — Cinematic animated deck for the shuffle ritual.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'shuffle_card_face.dart';
import 'shuffle_timeline.dart';

class ShuffleCinematicDeck extends StatelessWidget {
  const ShuffleCinematicDeck({
    super.key,
    required this.progress,
    this.cardCount = 9,
    this.cardWidth = 72,
    this.cardHeight = 118,
  });

  final double progress;
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

    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, panY + lift),
        child: Transform.scale(
          scale: zoom,
          child: SizedBox(
            width: 300,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _DeckBaseGlow(intensity: 0.35 + glow * 0.45),
                for (var i = 0; i < cardCount; i++)
                  _AnimatedCard(
                    index: i,
                    total: cardCount,
                    spread: spread,
                    shuffleEnv: shuffleEnv,
                    shuffleT: shuffleT,
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
        width: 200,
        height: 90,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.24 * intensity),
              blurRadius: 52,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.22 * intensity),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.index,
    required this.total,
    required this.spread,
    required this.shuffleEnv,
    required this.shuffleT,
    required this.width,
    required this.height,
  });

  final int index;
  final int total;
  final double spread;
  final double shuffleEnv;
  final double shuffleT;
  final double width;
  final double height;

  Offset _restOffset() {
    final mid = (total - 1) / 2;
    final t = mid == 0 ? 0.0 : (index - mid) / mid;
    return Offset(t * 4, -index * 1.4);
  }

  Offset _spreadOffset() {
    final mid = (total - 1) / 2;
    final t = mid == 0 ? 0.0 : (index - mid) / mid;
    final angle = t * 0.42;
    final radius = 38 + index * 2.5;
    return Offset(
      sin(angle) * radius * spread,
      -cos(angle.abs()) * 18 * spread - index * 2.0 * spread,
    );
  }

  Offset _shuffleOffset() {
    if (shuffleEnv <= 0) return Offset.zero;
    return Offset(
      sin((index + 1) * 1.35 + shuffleT * pi * 4) * 22 * shuffleEnv,
      cos((index + 1) * 1.05 + shuffleT * pi * 3.5) * 16 * shuffleEnv,
    );
  }

  double _rotation() {
    final mid = (total - 1) / 2;
    final t = mid == 0 ? 0.0 : (index - mid) / mid;
    final base = t * 0.12 * spread;
    final shuffle = sin(shuffleT * pi * 2 + index * 0.85) * 0.14 * shuffleEnv;
    return base + shuffle;
  }

  @override
  Widget build(BuildContext context) {
    final rest = _restOffset();
    final spreadOff = _spreadOffset();
    final shuffleOff = _shuffleOffset();
    final dx = rest.dx + spreadOff.dx + shuffleOff.dx;
    final dy = rest.dy + spreadOff.dy + shuffleOff.dy;
    final depth = index / total;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..rotateZ(_rotation()),
      child: ShuffleCardFace(
        width: width,
        height: height,
        elevation: 0.38 + depth * 0.52,
        lightBiasX: (dx / 120).clamp(-0.15, 0.15),
        lightBiasY: (dy / 80).clamp(-0.12, 0.12),
      ),
    );
  }
}
