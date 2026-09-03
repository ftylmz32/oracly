/// OR-1020 — Deck selection atmospheric background.
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import 'deck_selection_cinematic.dart';

/// Soft purple nebula — quieter particles than Tarot Home.
class DeckSelectionBackground extends StatefulWidget {
  const DeckSelectionBackground({super.key});

  @override
  State<DeckSelectionBackground> createState() => _DeckSelectionBackgroundState();
}

class _DeckSelectionBackgroundState extends State<DeckSelectionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: OraclySignatureMaterials.ambientDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = _drift.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.cosmic),
            _Nebula(top: 60 + sin(t * pi * 2) * 6, left: -70, size: 300, alpha: 0.14),
            _Nebula(top: 220 + sin(t * pi * 2 + 1.2) * 4, right: -90, size: 340, alpha: 0.12),
            _Nebula(bottom: 80, left: 20, size: 260, alpha: 0.07, gold: true),
            CustomPaint(
              painter: DeckSelectionTableGlowPainter(phase: t),
              size: Size.infinite,
            ),
            CustomPaint(painter: _SoftStars(phase: t), size: Size.infinite),
            CustomPaint(painter: _SoftParticles(phase: t), size: Size.infinite),
            CustomPaint(painter: _AmbientDust(phase: t), size: Size.infinite),
          ],
        );
      },
    );
  }
}

class _Nebula extends StatelessWidget {
  const _Nebula({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.alpha,
    this.gold = false,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double alpha;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold
                  ? AppColors.gold.withValues(alpha: alpha)
                  : AppColors.purple.withValues(alpha: alpha),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftStars extends CustomPainter {
  const _SoftStars({required this.phase});

  final double phase;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.12, 0.10, 0.7, 0.28),
    (0.28, 0.06, 0.5, 0.22),
    (0.72, 0.12, 0.8, 0.26),
    (0.88, 0.20, 0.5, 0.20),
    (0.18, 0.38, 0.6, 0.24),
    (0.52, 0.32, 0.5, 0.22),
    (0.82, 0.48, 0.7, 0.25),
    (0.36, 0.62, 0.5, 0.21),
    (0.64, 0.72, 0.6, 0.23),
    (0.14, 0.82, 0.5, 0.20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final (x, y, r, a) = _stars[i];
      final tw = 0.65 + sin(phase * pi * 2 + i * 0.7) * 0.35;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()..color = AppColors.white.withValues(alpha: a * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftStars oldDelegate) => oldDelegate.phase != phase;
}

class _SoftParticles extends CustomPainter {
  const _SoftParticles({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    const motes = <(double x, double y)>[
      (0.22, 0.18),
      (0.58, 0.24),
      (0.78, 0.36),
      (0.34, 0.52),
      (0.66, 0.58),
      (0.48, 0.74),
    ];
    for (var i = 0; i < motes.length; i++) {
      final (x, y) = motes[i];
      final drift = sin(phase * pi * 2 + i) * 3;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        1.0,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftParticles oldDelegate) => oldDelegate.phase != phase;
}

class _AmbientDust extends CustomPainter {
  const _AmbientDust({required this.phase});

  final double phase;

  static const _motes = <(double x, double y, double s)>[
    (0.15, 0.28, 0.5),
    (0.42, 0.18, 0.45),
    (0.68, 0.32, 0.55),
    (0.24, 0.48, 0.4),
    (0.56, 0.52, 0.5),
    (0.78, 0.44, 0.45),
    (0.32, 0.68, 0.4),
    (0.62, 0.74, 0.5),
    (0.48, 0.38, 0.35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _motes.length; i++) {
      final (x, y, dot) = _motes[i];
      final drift = sin(phase * pi * 2 + i * 0.9) * 2.5;
      final rise = sin(phase * pi * 2 * 0.5 + i * 1.3) * 1.5;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y + rise),
        dot,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.05 + (i % 3) * 0.015)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientDust oldDelegate) => oldDelegate.phase != phase;
}
