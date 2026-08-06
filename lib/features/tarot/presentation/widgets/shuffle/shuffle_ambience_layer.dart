/// OR-1030 — Magical fog, orbiting particles, and glow pulse.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'shuffle_timeline.dart';

class ShuffleAmbienceLayer extends StatelessWidget {
  const ShuffleAmbienceLayer({
    super.key,
    required this.progress,
    required this.size,
  });

  final double progress;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final fog = ShuffleTimeline.fogIntensity(progress);
    final glow = ShuffleTimeline.glowPulse(progress);
    final orbit = ShuffleTimeline.particleOrbit(progress);

    if (fog <= 0.01) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _FogBlob(
                offset: Offset(sin(progress * pi * 2) * 12, 20),
                size: 260 + glow * 30,
                color: AppColors.purpleDark.withValues(alpha: 0.28 * fog),
              ),
              _FogBlob(
                offset: Offset(cos(progress * pi * 2 + 1) * 16, 40),
                size: 220 + glow * 24,
                color: AppColors.purple.withValues(alpha: 0.22 * fog),
              ),
              CustomPaint(
                size: size,
                painter: _ShuffleGlowPainter(intensity: glow),
              ),
              CustomPaint(
                size: size,
                painter: _OrbitingParticlesPainter(
                  angle: orbit,
                  intensity: fog,
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Transform.translate(
      offset: offset,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 62, sigmaY: 62),
        child: Container(
          width: size,
          height: size * 0.7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _ShuffleGlowPainter extends CustomPainter {
  const _ShuffleGlowPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleGlow.withValues(alpha: 0.28 * intensity),
            AppColors.goldLight.withValues(alpha: 0.10 * intensity),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _ShuffleGlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

class _OrbitingParticlesPainter extends CustomPainter {
  const _OrbitingParticlesPainter({
    required this.angle,
    required this.intensity,
  });

  final double angle;
  final double intensity;

  static const _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rx = size.width * 0.38;
    final ry = size.height * 0.28;

    for (var i = 0; i < _count; i++) {
      final a = angle + (i / _count) * pi * 2;
      final twinkle = 0.5 + sin(a * 2 + i) * 0.35;
      final p = Offset(
        center.dx + cos(a) * rx,
        center.dy + sin(a) * ry,
      );
      canvas.drawCircle(
        p,
        1.0 + (i.isEven ? 0.3 : 0.0),
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.28 * intensity * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingParticlesPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.intensity != intensity;
  }
}
