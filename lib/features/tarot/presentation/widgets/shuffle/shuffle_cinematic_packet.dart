/// One card in the ritual stack — rest, overhand, optional cut.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

import 'shuffle_card_face.dart';
import 'shuffle_cut_motion.dart';

class ShuffleCinematicPacket extends StatelessWidget {
  const ShuffleCinematicPacket({
    super.key,
    required this.index,
    required this.total,
    required this.spread,
    required this.shuffleEnv,
    required this.shuffleT,
    required this.cutProgress,
    required this.trail,
    required this.width,
    required this.height,
  });

  final int index;
  final int total;
  final double spread;
  final double shuffleEnv;
  final double shuffleT;
  final double cutProgress;
  final double trail;
  final double width;
  final double height;

  Offset _restOffset() {
    return Offset((index % 2) * 0.6, -index * 1.55);
  }

  /// Deterministic interleave — packets slide past, then return.
  Offset _shuffleOffset() {
    if (shuffleEnv <= 0) return Offset.zero;
    final lane = index.isEven ? 1.0 : -1.0;
    final delay = (index % 4) * 0.11;
    final local = ((shuffleT + delay) % 1.0).clamp(0.0, 1.0);
    final arc = sin(local * pi) * shuffleEnv;
    return Offset(lane * 34 * arc, -12 * arc);
  }

  double _rotation() {
    final lane = index.isEven ? 0.055 : -0.05;
    final interleave = sin(shuffleT * pi) * lane * shuffleEnv;
    final cut = ShuffleCutMotion.packetTilt(index, total, cutProgress);
    return interleave + cut + spread * 0.03 * (index - total / 2);
  }

  @override
  Widget build(BuildContext context) {
    final rest = _restOffset();
    final shuffleOff = _shuffleOffset();
    final cutOff = ShuffleCutMotion.packetOffset(
      index: index,
      total: total,
      t: cutProgress,
    );
    final dx = rest.dx + shuffleOff.dx + cutOff.dx;
    final dy = rest.dy + shuffleOff.dy + cutOff.dy;
    final depth = index / total;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..rotateZ(_rotation()),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShuffleCardFace(
            width: width,
            height: height,
            elevation: 0.34 + depth * 0.48,
            lightBiasX: (dx / 120).clamp(-0.15, 0.15),
            lightBiasY: (dy / 80).clamp(-0.12, 0.12),
          ),
          if (trail > 0.04)
            IgnorePointer(
              child: Opacity(
                opacity: trail * 0.42,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.55 * trail),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldGlow.withValues(alpha: 0.18 * trail),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
