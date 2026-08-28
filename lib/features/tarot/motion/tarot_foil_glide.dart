/// Candlelight across gold foil — never a laser.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TarotFoilGlide extends StatelessWidget {
  const TarotFoilGlide({
    super.key,
    required this.progress,
    this.lightBiasX = 0,
  });

  final double progress;
  final double lightBiasX;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.02 || t >= 0.98) return const SizedBox.shrink();
    final x = -1.15 + t * 2.3 + lightBiasX * 0.35;
    return IgnorePointer(
      child: Opacity(
        opacity: (0.18 - (t - 0.5).abs() * 0.24).clamp(0.0, 0.14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 0.22, -0.8),
              end: Alignment(x + 0.22, 0.8),
              colors: [
                AppColors.transparent,
                AppColors.goldLight.withValues(alpha: 0.18),
                AppColors.white.withValues(alpha: 0.06),
                AppColors.transparent,
              ],
              stops: const [0.0, 0.42, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
