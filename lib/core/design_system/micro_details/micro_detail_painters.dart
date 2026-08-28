/// EPIC-027 — CustomPainters for card, button, and divider micro effects.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'micro_detail_tokens.dart';

/// Slow light sweep across premium card surface (12–20 s).
class CardMicroSweepPainter extends CustomPainter {
  const CardMicroSweepPainter({
    required this.sweepPhase,
    this.intensity = MicroDetailTokens.cardSweepIntensity,
  });

  final double sweepPhase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sweepPhase * 2 - 1;
    final sweepX = t * (size.width + size.width * 0.4);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            AppColors.goldLight.withValues(alpha: intensity * 0.4),
            AppColors.textPrimary.withValues(alpha: intensity * 0.15),
            Colors.transparent,
          ],
          stops: const [0.38, 0.48, 0.52, 0.62],
        ).createShader(
          Rect.fromLTWH(
            sweepX - size.width * 0.25,
            0,
            size.width * 0.5,
            size.height,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CardMicroSweepPainter old) =>
      old.sweepPhase != sweepPhase;
}

/// Tiny drifting specular highlight on card glass.
class CardMovingHighlightPainter extends CustomPainter {
  const CardMovingHighlightPainter({
    required this.phase,
    this.intensity = MicroDetailTokens.cardHighlightIntensity,
  });

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (0.25 + math.sin(phase * math.pi * 2) * 0.18);
    final y = size.height * (0.18 + math.cos(phase * math.pi * 2 * 0.7) * 0.08);
    canvas.drawCircle(
      Offset(x, y),
      size.shortestSide * 0.12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: intensity),
            AppColors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(x, y), radius: size.shortestSide * 0.14),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CardMovingHighlightPainter old) =>
      old.phase != phase;
}

/// Primary button highlight sweep.
class ButtonHighlightSweepPainter extends CustomPainter {
  const ButtonHighlightSweepPainter({
    required this.sweepPhase,
    this.intensity = MicroDetailTokens.buttonSweepIntensity,
  });

  final double sweepPhase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = sweepPhase * 2 - 1;
    final x = t * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.height * 0.35),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.textPrimary.withValues(alpha: intensity),
            Colors.transparent,
          ],
          stops: const [0.42, 0.5, 0.58],
        ).createShader(
          Rect.fromLTWH(x - size.width * 0.2, 0, size.width * 0.4, size.height),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant ButtonHighlightSweepPainter old) =>
      old.sweepPhase != sweepPhase;
}

/// Soft glow divider with transparent gradient endings.
class MicroDividerGlowPainter extends CustomPainter {
  const MicroDividerGlowPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = size.width / 2;
    final pulse = 0.85 + math.sin(phase * math.pi * 2) * 0.15;

    final leftShader = LinearGradient(
      colors: [
        Colors.transparent,
        AppColors.gold.withValues(alpha: 0.08 * pulse),
        AppColors.goldLight.withValues(alpha: 0.22 * pulse),
      ],
    ).createShader(Rect.fromLTWH(0, 0, cx - 18, size.height));

    final rightShader = LinearGradient(
      colors: [
        AppColors.goldLight.withValues(alpha: 0.22 * pulse),
        AppColors.gold.withValues(alpha: 0.08 * pulse),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(cx + 18, 0, cx - 18, size.height));

    canvas.drawLine(
      Offset(0, cy),
      Offset(cx - 18, cy),
      Paint()
        ..strokeWidth = 0.6
        ..shader = leftShader,
    );
    canvas.drawLine(
      Offset(cx + 18, cy),
      Offset(size.width, cy),
      Paint()
        ..strokeWidth = 0.6
        ..shader = rightShader,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      2.2,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.35 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant MicroDividerGlowPainter old) =>
      old.phase != phase;
}

/// Barely visible particles for empty regions.
class MicroEmptyParticlePainter extends CustomPainter {
  const MicroEmptyParticlePainter({
    required this.phase,
    this.seed = 99,
    this.density = 18,
  });

  final double phase;
  final int seed;
  final int density;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < density; i++) {
      final u = _unit(seed + i);
      final x = u * size.width;
      final y = _unit(seed + i + 5) * size.height;
      final drift = math.sin(phase * math.pi * 2 + i * 0.6) * 5;
      canvas.drawCircle(
        Offset(x + drift, y),
        0.8 + _unit(i + 3) * 1.4,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.03 + _unit(i + 7) * 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  double _unit(int i) {
    final n = math.sin(i * 12.9898) * 43758.5453;
    return n - n.floor();
  }

  @override
  bool shouldRepaint(covariant MicroEmptyParticlePainter old) =>
      old.phase != phase;
}

/// Icon container inner reflection arc.
class IconReflectionPainter extends CustomPainter {
  const IconReflectionPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.92),
      -math.pi * 0.82 + math.sin(phase * math.pi * 2) * 0.05,
      math.pi * 0.38,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = AppColors.goldLight.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant IconReflectionPainter old) =>
      old.phase != phase;
}

/// Computes breathing box shadows for cards.
List<BoxShadow> breathingCardShadows({
  required List<BoxShadow> base,
  required double breathPhase,
  bool pressed = false,
}) {
  final scale = pressed ? 0.88 : 1.0;
  final blurDelta = math.sin(breathPhase * math.pi * 2) *
      MicroDetailTokens.shadowBreathBlur *
      scale;
  final offsetDelta = math.sin(breathPhase * math.pi * 2 + 0.4) *
      MicroDetailTokens.shadowBreathOffset *
      scale;

  return base
      .map(
        (s) => BoxShadow(
          color: s.color,
          blurRadius: s.blurRadius + blurDelta,
          spreadRadius: s.spreadRadius,
          offset: Offset(s.offset.dx, s.offset.dy + offsetDelta),
        ),
      )
      .toList();
}
