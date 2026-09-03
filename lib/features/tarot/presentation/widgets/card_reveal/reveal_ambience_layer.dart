/// OR-1050 — Volumetric reveal ambience — fog, particles, bloom.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class RevealAmbienceLayer extends StatelessWidget {
  const RevealAmbienceLayer({
    super.key,
    required this.progress,
    required this.fogIntensity,
    required this.particleSpeed,
    required this.glowIntensity,
    required this.particlePhase,
    this.stillness = 0,
    this.orbFocus = 0,
  });

  final double progress;
  final double fogIntensity;
  final double particleSpeed;
  final double glowIntensity;
  final double particlePhase;
  final double stillness;
  final double orbFocus;

  @override
  Widget build(BuildContext context) {
    if (fogIntensity <= 0.01 && glowIntensity <= 0.01) {
      return const SizedBox.shrink();
    }

    final driftScale = lerpDouble(1.0, 0.38, stillness.clamp(0.0, 1.0))!;
    final fogMotion = progress * pi * 2 * driftScale;
    final particleMotion = particlePhase * particleSpeed * driftScale;
    final fogAlpha = fogIntensity * lerpDouble(1.0, 0.72, stillness)!;
    final focusRadius = 280 + orbFocus * 24;
    final particleAlpha = fogAlpha * lerpDouble(1.0, 0.62, stillness)!;

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(
                sin(fogMotion) * 14 * driftScale,
                16 + cos(fogMotion + 0.8) * 10 * driftScale,
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 68, sigmaY: 68),
                child: Container(
                  width: focusRadius + fogAlpha * 28,
                  height: 200 + fogAlpha * 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purpleDark.withValues(
                      alpha: 0.28 * fogAlpha,
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(cos(fogMotion + 1.2) * 10 * driftScale, 32),
              child: Opacity(
                opacity: lerpDouble(1.0, 0.55, stillness.clamp(0.0, 1.0))!,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
                  child: Container(
                    width: 240 + fogAlpha * 20,
                    height: 160 + fogAlpha * 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purpleGlow.withValues(
                        alpha: 0.12 * fogAlpha,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(360, 320),
              painter: _RevealBloomPainter(
                intensity: glowIntensity,
                focus: orbFocus,
              ),
            ),
            CustomPaint(
              size: const Size(360, 320),
              painter: _RevealParticlesPainter(
                phase: particleMotion,
                intensity: particleAlpha,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealBloomPainter extends CustomPainter {
  const _RevealBloomPainter({required this.intensity, this.focus = 0});

  final double intensity;
  final double focus;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = size.width * lerpDouble(0.42, 0.34, focus.clamp(0.0, 1.0))!;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleGlow.withValues(
              alpha: 0.14 * intensity + focus * 0.05,
            ),
            AppColors.goldLight.withValues(
              alpha: 0.10 * intensity + focus * 0.05,
            ),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _RevealBloomPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.focus != focus;
  }
}

class _RevealParticlesPainter extends CustomPainter {
  const _RevealParticlesPainter({required this.phase, required this.intensity});

  final double phase;
  final double intensity;

  static const _pts = <(double x, double y, double r)>[
    (-0.36, -0.10, 0.9),
    (-0.18, 0.10, 0.85),
    (0.08, -0.16, 0.95),
    (0.28, 0.06, 0.8),
    (-0.24, 0.18, 0.75),
    (0.20, 0.20, 0.7),
    (0.38, -0.12, 0.8),
    (-0.08, -0.24, 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.44;
    for (var i = 0; i < _pts.length; i++) {
      final (nx, ny, r) = _pts[i];
      final orbit = phase + i * 0.52;
      final drift = sin(orbit) * 4;
      final lift = cos(orbit * 0.85) * 3;
      final tw = 0.45 + sin(orbit * 1.4) * 0.28;
      canvas.drawCircle(
        Offset(
          cx + nx * size.width * 0.44 + drift,
          cy + ny * size.height * 0.36 + lift,
        ),
        r,
        Paint()
          ..color = AppColors.goldLight.withValues(
            alpha: 0.12 * intensity * tw,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevealParticlesPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.intensity != intensity;
  }
}
