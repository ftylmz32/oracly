import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CosmicParticleLayer extends StatefulWidget {
  const CosmicParticleLayer({super.key});

  @override
  State<CosmicParticleLayer> createState() => _CosmicParticleLayerState();
}

class _CosmicParticleLayerState extends State<CosmicParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.t);

  final double t;
  final _random = Random(7);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 32; i++) {
      final seed = i * 13.7;
      final x = (seed * 47 % size.width + t * 12) % size.width;
      final y = (seed * 29 % size.height + t * 7) % size.height;
      final alpha = 0.04 + (_random.nextDouble() * 0.08);

      canvas.drawCircle(
        Offset(x, y),
        0.8 + (i % 2) * 0.4,
        Paint()
          ..color = (i.isEven ? AppColors.primaryLight : AppColors.goldLight)
              .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
