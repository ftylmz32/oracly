/// EPIC-005 — Rare ambient event painters — lightweight, single-pass.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/oracly_brand_signature.dart';
import 'oracly_living_event.dart';

/// Shooting star — one quiet streak across the upper chamber.
class OraclyShootingStarPainter extends CustomPainter {
  const OraclyShootingStarPainter({
    required this.progress,
    required this.seed,
    required this.intensity,
  });

  final double progress;
  final int seed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final fade = progress < 0.15
        ? progress / 0.15
        : progress > 0.75
            ? (1 - progress) / 0.25
            : 1.0;

    final startX = size.width * (0.12 + (seed % 17) * 0.018);
    final startY = size.height * (0.08 + (seed % 11) * 0.012);
    const travel = 0.38;
    final t = Curves.easeOutCubic.transform(progress);
    final endX = startX + size.width * travel * t;
    final endY = startY + size.height * 0.14 * t;

    final alpha = 0.055 * fade * intensity;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          OraclySignaturePalette.wisdomGold.withValues(alpha: alpha),
          OraclySignaturePalette.wisdomGold.withValues(alpha: alpha * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)))
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

    canvas.drawCircle(
      Offset(endX, endY),
      1.2,
      Paint()
        ..color = OraclySignaturePalette.wisdomGold.withValues(alpha: alpha * 1.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyShootingStarPainter old) =>
      old.progress != progress;
}

/// Distant glow — far observatory light, barely perceptible.
class OraclyDistantGlowPainter extends CustomPainter {
  const OraclyDistantGlowPainter({
    required this.progress,
    required this.seed,
    required this.intensity,
  });

  final double progress;
  final int seed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final breathe = sin(progress * pi);
    final alpha = (0.022 + breathe * 0.018) * intensity;
    final cx = size.width * (0.78 + (seed % 9) * 0.012);
    final cy = size.height * (0.16 + (seed % 7) * 0.01);

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.22,
      Paint()
        ..color = AppColors.purpleLight.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 72),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyDistantGlowPainter old) =>
      old.progress != progress;
}

/// Slowly shifting constellation — three linked points drift over minutes.
class OraclyConstellationDriftPainter extends CustomPainter {
  const OraclyConstellationDriftPainter({
    required this.phase,
    required this.seed,
    required this.intensity,
  });

  final double phase;
  final int seed;
  final double intensity;

  static const _nodes = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = phase * pi * 2;
    final baseX = 0.62 + (seed % 13) * 0.008;
    final baseY = 0.22 + (seed % 9) * 0.01;
    final alpha = 0.028 * intensity;

    final points = <Offset>[];
    for (var i = 0; i < _nodes; i++) {
      final angle = drift + i * 1.4 + seed * 0.03;
      points.add(
        Offset(
          size.width * (baseX + sin(angle + i) * 0.04),
          size.height * (baseY + sin(angle * 0.7 + i * 0.5) * 0.03),
        ),
      );
    }

    final linePaint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: alpha * 0.6)
      ..strokeWidth = 0.35
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(
        point,
        0.55,
        Paint()..color = AppColors.goldLight.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OraclyConstellationDriftPainter old) =>
      old.phase != phase;
}

/// Golden reflection — quiet specular wash across crystal surfaces.
class OraclyGoldenReflectionPainter extends CustomPainter {
  const OraclyGoldenReflectionPainter({
    required this.progress,
    required this.seed,
    required this.intensity,
  });

  final double progress;
  final int seed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(
      progress < 0.5 ? progress * 2 : (1 - progress) * 2,
    );
    final band = -0.3 + t * 1.2 + (seed % 11) * 0.008;
    final alpha = 0.032 * t * intensity;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(band - 0.35, -0.6),
          end: Alignment(band + 0.35, 1.0),
          colors: [
            Colors.transparent,
            OraclySignaturePalette.wisdomGold.withValues(alpha: alpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyGoldenReflectionPainter old) =>
      old.progress != progress;
}

/// Routes event kind to the correct painter.
class OraclyLivingEventPainter extends CustomPainter {
  const OraclyLivingEventPainter({
    required this.event,
    required this.progress,
    required this.constellationPhase,
  });

  final OraclyLivingEvent event;
  final double progress;
  final double constellationPhase;

  @override
  void paint(Canvas canvas, Size size) {
    switch (event.kind) {
      case OraclyLivingEventKind.shootingStar:
        OraclyShootingStarPainter(
          progress: progress,
          seed: event.seed,
          intensity: event.intensity,
        ).paint(canvas, size);
      case OraclyLivingEventKind.distantGlow:
        OraclyDistantGlowPainter(
          progress: progress,
          seed: event.seed,
          intensity: event.intensity,
        ).paint(canvas, size);
      case OraclyLivingEventKind.shiftingConstellation:
        OraclyConstellationDriftPainter(
          phase: constellationPhase,
          seed: event.seed,
          intensity: event.intensity,
        ).paint(canvas, size);
      case OraclyLivingEventKind.goldenReflection:
        OraclyGoldenReflectionPainter(
          progress: progress,
          seed: event.seed,
          intensity: event.intensity,
        ).paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant OraclyLivingEventPainter old) =>
      old.progress != progress || old.constellationPhase != constellationPhase;
}
