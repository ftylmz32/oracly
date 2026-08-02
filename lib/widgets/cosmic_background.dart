import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import 'cosmic_particle_layer.dart';

class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.child,
    this.showParticles = false,
    this.showHeroGlow = false,
  });

  final Widget child;
  final bool showParticles;
  final bool showHeroGlow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.background,
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(
              size: 320,
              color: AppColors.accent.withValues(alpha: .18),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: _GlowOrb(
              size: 340,
              color: AppColors.primary.withValues(alpha: .14),
            ),
          ),
          Positioned(
            top: 220,
            right: 60,
            child: _GlowOrb(
              size: 180,
              color: AppColors.cyan.withValues(alpha: .08),
            ),
          ),
          if (showHeroGlow)
            Positioned(
              top: 88,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: _GlowOrb(
                    size: 280,
                    color: AppColors.gold.withValues(alpha: .1),
                  ),
                ),
              ),
            ),
          CustomPaint(
            painter: StarPainter(),
            size: Size.infinite,
          ),
          if (showParticles)
            const Positioned.fill(
              child: IgnorePointer(
                child: CosmicParticleLayer(),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 90,
        sigmaY: 90,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final softStar = Paint()
      ..color = Colors.white.withValues(alpha: .45);
    final goldStar = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: .85);

    for (int i = 0; i < 160; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.5,
        softStar,
      );
    }

    for (int i = 0; i < 25; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        2,
        goldStar,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
