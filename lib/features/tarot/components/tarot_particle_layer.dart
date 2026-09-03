/// OR-1000 — Floating particle field for tarot screens.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../theme/tarot_tokens.dart';
import '../presentation/painters/tarot_particle_painter.dart';

/// Animated mystical dust — isolated repaint boundary for 60fps.
class TarotParticleLayer extends StatefulWidget {
  const TarotParticleLayer({super.key});

  @override
  State<TarotParticleLayer> createState() => _TarotParticleLayerState();
}

class _TarotParticleLayerState extends State<TarotParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: TarotTokens.ambientLoop,
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            return CustomPaint(
              painter: TarotParticlePainter(phase: _drift.value * pi * 2),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

/// Soft radial glow wash behind ritual focal points.
class TarotGlowLayer extends StatelessWidget {
  const TarotGlowLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TarotGlowPainter(
            accent: AppColors.purpleGlow.withValues(alpha: 0.22),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
