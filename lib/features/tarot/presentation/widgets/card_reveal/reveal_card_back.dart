/// OR-1050+ — Premium mystical tarot card back for cinematic reveal.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../theme/tarot_tokens.dart';

class RevealPremiumCardBack extends StatelessWidget {
  const RevealPremiumCardBack({
    super.key,
    required this.width,
    required this.height,
    this.elevation = 0.85,
    this.particlePhase = 0,
  });

  final double width;
  final double height;
  final double elevation;
  final double particlePhase;

  @override
  Widget build(BuildContext context) {
    final edge = 1.4 + elevation * 1.6;
    final radius = TarotTokens.cardCornerRadius;
    final innerRadius = radius - 1;
    final clipRadius = radius - 1.5;
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5 + elevation * 0.18),
              blurRadius: 10 + elevation * 14,
              offset: Offset(0, 4 + elevation * 6),
            ),
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.16 + elevation * 0.08),
              blurRadius: 14,
              spreadRadius: 0,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gold.withValues(alpha: 0.32),
              const Color(0xFF9A7420).withValues(alpha: 0.65),
              const Color(0xFF5C4510).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(innerRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1040),
                  Color(0xFF0C0820),
                  Color(0xFF060410),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(clipRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: RevealCardBackPainter(phase: particlePhase),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: edge,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.goldLight.withValues(alpha: 0.28),
                            AppColors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cached celestial back art — repaints only when [phase] changes.
class RevealCardBackPainter extends CustomPainter {
  RevealCardBackPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = AppColors.gold;
    final goldSoft = AppColors.goldLight;
    final purple = AppColors.purpleLight;
    final c = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    _ornamentalBorder(canvas, size, gold);

    canvas.drawCircle(
      c,
      w * 0.30,
      Paint()..color = purple.withValues(alpha: 0.08),
    );

    _constellation(canvas, c, w, goldSoft);
    _celestialGeometry(canvas, c, w, gold);
    _moonPhases(canvas, c, w, h, goldSoft);

    _centerEmblem(canvas, c, w, gold, goldSoft);

    _backParticles(canvas, size, phase);
  }

  void _ornamentalBorder(Canvas canvas, Size size, Color gold) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      const Radius.circular(6),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(4),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = gold.withValues(alpha: 0.55);
    canvas.drawRRect(outer, stroke);
    canvas.drawRRect(inner, stroke..strokeWidth = 0.7..color = gold.withValues(alpha: 0.35));

    for (var i = 0; i < 4; i++) {
      final corner = [
        const Offset(10, 10),
        Offset(size.width - 10, 10),
        Offset(size.width - 10, size.height - 10),
        Offset(10, size.height - 10),
      ][i];
      canvas.drawCircle(corner, 2.2, Paint()..color = gold.withValues(alpha: 0.7));
    }
  }

  void _celestialGeometry(Canvas canvas, Offset c, double w, Color gold) {
    for (var ring = 1; ring <= 3; ring++) {
      canvas.drawCircle(
        c,
        w * 0.10 * ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = gold.withValues(alpha: 0.18 + ring * 0.06),
      );
    }
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.cos(a) * w * 0.11, math.sin(a) * w * 0.11),
        c + Offset(math.cos(a) * w * 0.27, math.sin(a) * w * 0.27),
        Paint()
          ..color = gold.withValues(alpha: 0.22)
          ..strokeWidth = 0.45,
      );
    }
  }

  void _constellation(Canvas canvas, Offset c, double w, Color color) {
    const nodes = [
      (-0.18, -0.22),
      (-0.08, -0.14),
      (0.04, -0.18),
      (0.14, -0.10),
      (0.22, -0.20),
    ];
    final pts = nodes
        .map((n) => c + Offset(n.$1 * w, n.$2 * w))
        .toList();
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(
        pts[i],
        pts[i + 1],
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 0.5,
      );
    }
    for (final p in pts) {
      canvas.drawCircle(p, 1.2, Paint()..color = color.withValues(alpha: 0.55));
    }
  }

  void _moonPhases(Canvas canvas, Offset c, double w, double h, Color color) {
    final left = c + Offset(-w * 0.22, -h * 0.06);
    final right = c + Offset(w * 0.22, -h * 0.06);
    _drawCrescent(canvas, left, w * 0.06, color.withValues(alpha: 0.5));
    canvas.drawCircle(right, w * 0.045, Paint()..color = color.withValues(alpha: 0.35));
    canvas.drawCircle(
      right,
      w * 0.045,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = color.withValues(alpha: 0.55),
    );
  }

  void _drawCrescent(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      0.6,
      math.pi * 1.3,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  void _centerEmblem(Canvas canvas, Offset c, double w, Color gold, Color soft) {
    canvas.drawCircle(c, w * 0.11, Paint()..color = soft.withValues(alpha: 0.12));
    canvas.drawCircle(
      c,
      w * 0.11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withValues(alpha: 0.65),
    );
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + phase * 0.02;
      canvas.drawLine(
        c + Offset(math.cos(a) * w * 0.04, math.sin(a) * w * 0.04),
        c + Offset(math.cos(a) * w * 0.09, math.sin(a) * w * 0.09),
        Paint()..color = soft.withValues(alpha: 0.75)..strokeWidth = 1.2,
      );
    }
    canvas.drawCircle(c, 2.5, Paint()..color = soft.withValues(alpha: 0.95));
  }

  void _backParticles(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 14; i++) {
      final seed = i * 17 + 3;
      final bx = _pseudo(seed) * size.width;
      final by = _pseudo(seed + 7) * size.height;
      final tw = 0.15 + _pseudo(seed + 13) * 0.35;
      final drift = math.sin(phase + i) * 1.5;
      canvas.drawCircle(
        Offset(bx + drift, by),
        0.6 + tw,
        Paint()..color = AppColors.goldLight.withValues(alpha: tw * 0.45),
      );
    }
  }

  double _pseudo(int seed) {
    final x = math.sin(seed * 12.9898) * 43758.5453;
    return x - x.floor();
  }

  @override
  bool shouldRepaint(covariant RevealCardBackPainter old) => old.phase != phase;
}
