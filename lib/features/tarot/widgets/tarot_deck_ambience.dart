/// OR-1021 — Cinematic magical aura around the tarot deck hero.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Volumetric fog, aura, dust, and slow energy — deck focal effects.
class TarotDeckAmbience extends StatefulWidget {
  const TarotDeckAmbience({
    super.key,
    required this.child,
    this.width = 300,
    this.height = 220,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  State<TarotDeckAmbience> createState() => _TarotDeckAmbienceState();
}

class _TarotDeckAmbienceState extends State<TarotDeckAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final t = _motion.value;
        final breath = 0.5 + sin(t * pi * 2) * 0.5;
        final energy = t * pi * 2;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _FogBlob(
                offset: Offset(-48 + sin(t * pi * 2) * 10, 18),
                size: 248 + breath * 20,
                color: AppColors.purpleDark.withValues(alpha: 0.26 + breath * 0.07),
              ),
              _FogBlob(
                offset: Offset(42 + cos(t * pi * 2 + 0.9) * 12, 42),
                size: 196 + breath * 16,
                color: AppColors.purple.withValues(alpha: 0.20 + breath * 0.06),
              ),
              _FogBlob(
                offset: Offset(-12 + sin(t * pi * 2 + 1.6) * 8, 68),
                size: 272 + breath * 24,
                color: AppColors.purpleGlow.withValues(alpha: 0.12 + breath * 0.05),
              ),
              _FogBlob(
                offset: Offset(8 + cos(t * pi * 2 + 2.1) * 6, 88),
                size: 180 + breath * 14,
                color: AppColors.gold.withValues(alpha: 0.05 + breath * 0.025),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _DeckAuraPainter(
                    intensity: 0.58 + breath * 0.28,
                    energy: energy,
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _DeckConstellationPainter(phase: t),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _DeckGoldParticlesPainter(phase: energy),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _MagicalDustPainter(phase: energy * 0.7),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _FogBlob extends StatelessWidget {
  const _FogBlob({
    required this.offset,
    required this.size,
    required this.color,
  });

  final Offset offset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.translate(
          offset: offset,
          child: Center(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 58, sigmaY: 58),
              child: Container(
                width: size,
                height: size * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckAuraPainter extends CustomPainter {
  const _DeckAuraPainter({required this.intensity, required this.energy});

  final double intensity;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.56);
    final radius = size.width * 0.40;

    canvas.drawCircle(
      center,
      radius * 1.18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleGlow.withValues(alpha: 0.24 * intensity),
            AppColors.purpleDark.withValues(alpha: 0.14 * intensity),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.18)),
    );

    canvas.drawCircle(
      center,
      radius * 1.02,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.12 * intensity),
            AppColors.purpleGlow.withValues(alpha: 0.16 * intensity),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.02)),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.gold.withValues(alpha: 0.16 * intensity);
    canvas.drawCircle(center, radius, ringPaint);

    ringPaint
      ..strokeWidth = 0.55
      ..color = AppColors.purpleLight.withValues(alpha: 0.14 * intensity);
    canvas.drawCircle(center, radius * 0.84, ringPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.goldLight.withValues(alpha: 0.10 * intensity);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.94),
      energy * 0.4,
      pi * 0.55,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.88),
      energy * 0.4 + pi,
      pi * 0.42,
      false,
      arcPaint..color = AppColors.purpleLight.withValues(alpha: 0.08 * intensity),
    );
  }

  @override
  bool shouldRepaint(covariant _DeckAuraPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.energy != energy;
  }
}

class _DeckConstellationPainter extends CustomPainter {
  const _DeckConstellationPainter({required this.phase});

  final double phase;

  static const _nodes = <(double x, double y)>[
    (-0.38, -0.12),
    (-0.28, -0.04),
    (-0.18, -0.16),
    (0.34, -0.10),
    (0.24, 0.02),
    (0.38, -0.18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.50;
    final tw = 0.5 + sin(phase * pi * 2) * 0.3;
    final line = Paint()
      ..strokeWidth = 0.4
      ..color = AppColors.purpleLight.withValues(alpha: 0.07 * tw);

    for (var i = 0; i < _nodes.length; i++) {
      final (nx, ny) = _nodes[i];
      final p = Offset(cx + nx * size.width * 0.44, cy + ny * size.height * 0.36);
      canvas.drawCircle(
        p,
        0.8,
        Paint()..color = AppColors.white.withValues(alpha: 0.14 * tw),
      );
      if (i > 0 && i != 3) {
        final (pnx, pny) = _nodes[i - 1];
        canvas.drawLine(
          Offset(cx + pnx * size.width * 0.44, cy + pny * size.height * 0.36),
          p,
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DeckConstellationPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _DeckGoldParticlesPainter extends CustomPainter {
  const _DeckGoldParticlesPainter({required this.phase});

  final double phase;

  static const _particles = <(double x, double y, double r, double speed)>[
    (-0.36, -0.06, 1.3, 0.65),
    (-0.24, 0.14, 1.0, 0.95),
    (-0.10, -0.20, 1.1, 0.85),
    (0.04, 0.06, 1.2, 1.15),
    (0.16, -0.12, 0.9, 0.75),
    (0.28, 0.12, 1.0, 1.05),
    (0.36, -0.04, 0.8, 1.1),
    (-0.32, 0.22, 0.95, 0.55),
    (0.22, 0.24, 0.85, 0.9),
    (-0.12, -0.28, 1.15, 1.05),
    (0.10, -0.30, 0.95, 0.7),
    (-0.38, -0.20, 0.75, 1.0),
    (0.40, 0.18, 0.7, 0.8),
    (-0.20, -0.08, 1.0, 1.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.50;

    for (var i = 0; i < _particles.length; i++) {
      final (nx, ny, r, speed) = _particles[i];
      final drift = sin(phase * speed + i) * 5;
      final lift = cos(phase * speed * 0.75 + i * 0.55) * 4;
      final twinkle = 0.4 + sin(phase * 1.2 + i * 0.85) * 0.35;

      canvas.drawCircle(
        Offset(cx + nx * size.width * 0.44 + drift, cy + ny * size.height * 0.38 + lift),
        r,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.24 * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DeckGoldParticlesPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _MagicalDustPainter extends CustomPainter {
  const _MagicalDustPainter({required this.phase});

  final double phase;

  static const _dust = <(double x, double y, double s)>[
    (-0.30, 0.08, 0.5),
    (-0.14, -0.22, 0.4),
    (0.08, 0.18, 0.45),
    (0.20, -0.20, 0.35),
    (0.32, 0.06, 0.5),
    (-0.22, -0.14, 0.4),
    (0.14, -0.08, 0.35),
    (-0.08, 0.20, 0.45),
    (0.26, -0.14, 0.4),
    (-0.34, 0.16, 0.35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    for (var i = 0; i < _dust.length; i++) {
      final (nx, ny, s) = _dust[i];
      final drift = sin(phase + i * 1.1) * 3;
      final alpha = 0.12 + sin(phase * 0.9 + i) * 0.06;
      canvas.drawCircle(
        Offset(cx + nx * size.width * 0.46 + drift, cy + ny * size.height * 0.40),
        s,
        Paint()..color = AppColors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MagicalDustPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
