import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import 'cosmic_particle_layer.dart';

class CosmicBackground extends StatefulWidget {
  const CosmicBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showHeroGlow = false,
  });

  final Widget child;
  final bool showParticles;
  final bool showHeroGlow;

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) {
          final t = _motion.value;
          final breath = 0.05 + sin(t * pi * 2) * 0.018;
          return Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.background),
                child: SizedBox.expand(),
              ),
              Positioned(
                top: -100 + sin(t * pi * 2) * 5,
                left: -70,
                child: _GlowOrb(360, AppColors.primary.withValues(alpha: breath)),
              ),
              Positioned(
                bottom: -120 + cos(t * pi * 2) * 4,
                right: -80,
                child: _GlowOrb(320, AppColors.primaryLight.withValues(alpha: breath * 0.7)),
              ),
              if (widget.showHeroGlow)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: _GlowOrb(260, AppColors.gold.withValues(alpha: breath * 0.8)),
                    ),
                  ),
                ),
              CustomPaint(painter: _StarField(t), size: Size.infinite),
              if (widget.showParticles)
                const Positioned.fill(
                  child: IgnorePointer(child: CosmicParticleLayer()),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.2,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
                    stops: const [0.55, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _StarField extends CustomPainter {
  _StarField(this.t);

  final double t;

  static final List<_StarSeed> _seeds = _buildSeeds();

  static List<_StarSeed> _buildSeeds() {
    final random = Random(42);
    return List.generate(180, (index) {
      return _StarSeed(
        nx: random.nextDouble(),
        ny: random.nextDouble(),
        radius: random.nextDouble() * 0.6 + 0.15,
        baseAlpha: 0.12 + random.nextDouble() * 0.2,
        phase: index * 0.8,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _seeds) {
      final twinkle = 0.7 + sin(t * pi * 2 + star.phase) * 0.3;
      canvas.drawCircle(
        Offset(star.nx * size.width, star.ny * size.height),
        star.radius,
        Paint()
          ..color = Colors.white.withValues(alpha: star.baseAlpha * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarField old) => old.t != t;
}

class _StarSeed {
  const _StarSeed({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.baseAlpha,
    required this.phase,
  });

  final double nx;
  final double ny;
  final double radius;
  final double baseAlpha;
  final double phase;
}
