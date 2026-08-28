/// EPIC-026 — Reusable CustomPainters for cinematic lighting layers.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'cinematic_lighting_tokens.dart';

/// Seeded stable random for performance — no per-frame allocation.
class _LightSeed {
  _LightSeed(this.seed);

  final int seed;

  double unit(int i) {
    final n = math.sin((seed + i) * 12.9898) * 43758.5453;
    return n - n.floor();
  }
}

/// Layer 1 — deep ambient darkness base gradient.
class AmbientDarknessPainter extends CustomPainter {
  const AmbientDarknessPainter({required this.preset});

  final CinematicLightingPreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.backgroundSecondary,
            const Color(0xFF06040E),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant AmbientDarknessPainter old) =>
      old.preset != preset;
}

/// Layer 2 — large drifting radial nebula washes.
class NebulaRadialPainter extends CustomPainter {
  const NebulaRadialPainter({
    required this.preset,
    required this.phase,
  });

  final CinematicLightingPreset preset;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final primary = CinematicLightingTokens.nebulaPrimary(preset);
    final secondary = CinematicLightingTokens.nebulaSecondary(preset);
    final intensity = CinematicLightingTokens.nebulaIntensity(preset);
    final driftX = math.sin(phase * math.pi * 2) * size.width * 0.02;
    final driftY = math.cos(phase * math.pi * 2 + 0.5) * size.height * 0.015;

    _drawWash(
      canvas,
      size,
      Offset(size.width * 0.55 + driftX, size.height * 0.22 + driftY),
      size.shortestSide * 0.85,
      [
        primary.withValues(alpha: intensity),
        secondary.withValues(alpha: intensity * 0.35),
        AppColors.transparent,
      ],
    );

    _drawWash(
      canvas,
      size,
      Offset(size.width * 0.18 - driftX * 0.5, size.height * 0.68 + driftY),
      size.shortestSide * 0.65,
      [
        secondary.withValues(alpha: intensity * 0.45),
        AppColors.transparent,
      ],
    );

    _drawWash(
      canvas,
      size,
      Offset(size.width * 0.82, size.height * 0.48 - driftY),
      size.shortestSide * 0.42,
      [
        AppColors.gold.withValues(alpha: intensity * 0.22),
        AppColors.transparent,
      ],
    );
  }

  void _drawWash(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    List<Color> colors,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: _stopsFor(colors.length),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  List<double> _stopsFor(int count) => switch (count) {
        2 => const [0.0, 1.0],
        3 => const [0.0, 0.45, 1.0],
        _ => const [0.0, 0.35, 0.7, 1.0],
      };

  @override
  bool shouldRepaint(covariant NebulaRadialPainter old) =>
      old.phase != phase || old.preset != preset;
}

/// Moving light fog — soft purple haze.
class LightFogPainter extends CustomPainter {
  const LightFogPainter({required this.phase, required this.preset});

  final double phase;
  final CinematicLightingPreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    final color = CinematicLightingTokens.nebulaPrimary(preset);
    final y = size.height * (0.35 + math.sin(phase * math.pi * 2) * 0.06);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, y / size.height * 2 - 1),
          radius: 1.1,
          colors: [
            color.withValues(alpha: CinematicLightingTokens.fogStrength),
            AppColors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant LightFogPainter old) =>
      old.phase != phase || old.preset != preset;
}

/// Very subtle film grain noise.
class SubtleNoisePainter extends CustomPainter {
  const SubtleNoisePainter({required this.seed, required this.phase});

  final int seed;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = _LightSeed(seed);
    final paint = Paint();
    const step = 6.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        final i = (x + y).toInt();
        final alpha = CinematicLightingTokens.noiseStrength *
            (0.4 + rng.unit(i) * 0.6) *
            (0.85 + math.sin(phase * math.pi * 2 + i * 0.02) * 0.15);
        paint.color = AppColors.textPrimary.withValues(alpha: alpha);
        canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleNoisePainter old) =>
      old.phase != phase;
}

/// Almost invisible distant stars.
class DistantStarsPainter extends CustomPainter {
  const DistantStarsPainter({
    required this.preset,
    required this.phase,
    this.seed = 42,
  });

  final CinematicLightingPreset preset;
  final double phase;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = _LightSeed(seed);
    final count = CinematicLightingTokens.starCount(preset);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final x = rng.unit(i) * size.width;
      final y = rng.unit(i + 3) * size.height * 0.85;
      final twinkle = 0.5 + math.sin(phase * math.pi * 2 + i * 0.55) * 0.3;
      final alpha = CinematicLightingTokens.starMaxAlpha *
          twinkle *
          (0.35 + rng.unit(i + 7) * 0.65);
      paint.color = (rng.unit(i + 11) > 0.7
              ? AppColors.goldLight
              : AppColors.textPrimary)
          .withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(x, y),
        0.5 + rng.unit(i + 5) * 0.9,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DistantStarsPainter old) =>
      old.phase != phase || old.preset != preset;
}

/// Layer 5 — soft glowing dust (never bright dots).
class SoftParticleLightPainter extends CustomPainter {
  const SoftParticleLightPainter({
    required this.preset,
    required this.phase,
    this.seed = 17,
  });

  final CinematicLightingPreset preset;
  final double phase;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = _LightSeed(seed);
    final count = CinematicLightingTokens.particleCount(preset);
    final primary = CinematicLightingTokens.nebulaPrimary(preset);
    const gold = AppColors.goldLight;

    for (var i = 0; i < count; i++) {
      final bx = rng.unit(i) * size.width;
      final by = rng.unit(i + 2) * size.height;
      final drift = math.sin(phase * math.pi * 2 + i * 0.65) * 10;
      final pos = Offset(bx + drift, by + drift * 0.35);
      final alpha = CinematicLightingTokens.particleMaxAlpha *
          (0.5 + rng.unit(i + 4) * 0.5);
      final radius = 1.4 + rng.unit(i + 8) * 2.2;
      final color = i.isEven ? gold : primary;

      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SoftParticleLightPainter old) =>
      old.phase != phase || old.preset != preset;
}

/// Cinematic edge vignette — corners naturally darken.
class CinematicVignettePainter extends CustomPainter {
  const CinematicVignettePainter({
    this.strength = CinematicLightingTokens.vignetteStrength,
  });

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.05,
          colors: [
            AppColors.transparent,
            AppColors.black.withValues(alpha: strength * 0.35),
            AppColors.black.withValues(alpha: strength * 0.65),
          ],
          stops: const [0.45, 0.82, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CinematicVignettePainter old) =>
      old.strength != strength;
}

/// Gold specular highlight wash — layer 4 accent.
class GoldHighlightPainter extends CustomPainter {
  const GoldHighlightPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(phase * math.pi * 2) * 0.04;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0.15 + drift, -0.55 + drift * 0.5),
          radius: 0.75,
          colors: [
            AppColors.goldLight.withValues(
              alpha: CinematicLightingTokens.goldHighlightStrength,
            ),
            AppColors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant GoldHighlightPainter old) =>
      old.phase != phase;
}

/// Card surface lighting overlay — top highlight, inner light, reflection.
class CardSurfaceLightingPainter extends CustomPainter {
  const CardSurfaceLightingPainter({
    required this.phase,
    this.pressed = false,
  });

  final double phase;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide;
    final innerAlpha = pressed ? 0.16 : 0.11;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.38),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.goldLight.withValues(alpha: 0.10 + phase * 0.02),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.38)),
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.28),
      r * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.glowGold.withValues(alpha: innerAlpha),
            AppColors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.5, size.height * 0.28),
            radius: r * 0.65,
          ),
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.transparent,
            AppColors.black.withValues(alpha: 0.18),
          ],
        ).createShader(
          Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        ),
    );

    final reflectX = size.width * (0.22 + math.sin(phase * math.pi * 2) * 0.04);
    canvas.drawRect(
      Rect.fromLTWH(reflectX, 0, size.width * 0.08, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.transparent,
            AppColors.textPrimary.withValues(alpha: 0.04),
            AppColors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(reflectX, 0, size.width * 0.08, size.height),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CardSurfaceLightingPainter old) =>
      old.phase != phase || old.pressed != pressed;
}
