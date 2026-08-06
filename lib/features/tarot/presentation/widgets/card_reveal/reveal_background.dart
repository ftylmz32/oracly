/// OR-1050 / OR-432 — Reveal-stage background — persistent chamber, living breath.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../theme/tarot_tokens.dart';

class RevealBackground extends StatefulWidget {
  const RevealBackground({
    super.key,
    required this.darken,
    this.stillness = 0,
    this.ambientDeepen = 0,
  });

  final double darken;
  final double stillness;
  final double ambientDeepen;

  @override
  State<RevealBackground> createState() => _RevealBackgroundState();
}

class _RevealBackgroundState extends State<RevealBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: TarotTokens.ambientLoop,
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final phase = _ambient.value;
        final breath = 0.5 + sin(phase * pi * 2) * 0.5;
        final driftScale = 1 - widget.stillness * 0.55;

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.reveal),
            Positioned(
              top: 100 + sin(phase * pi * 2) * 6 * driftScale,
              right: -60 + cos(phase * pi * 2 * 0.4) * 8 * driftScale,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
                  child: Container(
                    width: 240 + breath * 12,
                    height: 240 + breath * 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purpleDark.withValues(
                        alpha: 0.16 * widget.darken * driftScale,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.38 * widget.darken +
                      widget.stillness * 0.14 +
                      widget.ambientDeepen * 0.08,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      sin(phase * pi * 2 * 0.2) * 0.06,
                      -0.08 + cos(phase * pi * 2 * 0.15) * 0.04,
                    ),
                    radius: 1.05 - widget.stillness * 0.12,
                    colors: [
                      AppColors.transparent,
                      Colors.black.withValues(
                        alpha: 0.55 * widget.darken + widget.stillness * 0.18,
                      ),
                    ],
                    stops: [0.42 - widget.stillness * 0.08, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RevealDriftMotes(
                    phase: phase * pi * 2,
                    intensity: (0.45 + widget.darken * 0.35) * driftScale,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RevealDriftMotes extends CustomPainter {
  const _RevealDriftMotes({
    required this.phase,
    required this.intensity,
  });

  final double phase;
  final double intensity;

  static const _motes = <(double x, double y)>[
    (0.18, 0.22),
    (0.42, 0.14),
    (0.68, 0.28),
    (0.82, 0.48),
    (0.24, 0.62),
    (0.58, 0.74),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _motes.length; i++) {
      final (x, y) = _motes[i];
      final drift = sin(phase + i * 0.9) * 4;
      final lift = cos(phase * 0.85 + i) * 3;
      final tw = 0.4 + sin(phase * 1.2 + i) * 0.25;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y + lift),
        0.9,
        Paint()
          ..color = OraclySignaturePalette.champagne
              .withValues(alpha: 0.14 * intensity * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevealDriftMotes old) =>
      old.phase != phase || old.intensity != intensity;
}
