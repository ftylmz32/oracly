/// Brief focus toward the pile before OR draws — OR chooses, user witnesses.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../motion/tarot_cinematic_motion.dart';
import '../deck/physical_deck_stack.dart';

class OrDrawFocus extends StatelessWidget {
  const OrDrawFocus({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = TarotCinematicMotion.weight.transform(progress.clamp(0.0, 1.0));
    if (t <= 0.01) return const SizedBox.shrink();
    final lift = t < 0.55 ? t / 0.55 : 1.0;
    final draw = t < 0.55 ? 0.0 : (t - 0.55) / 0.45;
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28 * t),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OrDrawGoldHaze(progress: t),
            Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, -8 * draw),
                child: Transform.scale(
                  scale: 1 + lift * 0.04 - draw * 0.02,
                  child: Center(
                    child: PhysicalDeckStack(
                      width: 104,
                      height: 168,
                      layers: 7,
                      opacity: 0.94,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrDrawGoldHaze extends StatelessWidget {
  const OrDrawGoldHaze({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.02) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.78,
            colors: [
              AppColors.gold.withValues(alpha: 0.055 * t),
              AppColors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
