/// Standalone star-field overlay — reuse on any cosmic surface.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../theme/oracly_quiet_motion.dart';

/// Soft twinkling stars + optional gold dust — ignore-pointer atmosphere.
class OraclyStarField extends StatefulWidget {
  const OraclyStarField({
    super.key,
    this.showDust = true,
    this.intensity = 1.0,
  });

  final bool showDust;
  final double intensity;

  @override
  State<OraclyStarField> createState() => _OraclyStarFieldState();
}

class _OraclyStarFieldState extends State<OraclyStarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _motion, rest: 0.35);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    Widget field(double phase) => IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _FieldPainter(
                phase: phase,
                intensity: widget.intensity,
                showDust: widget.showDust,
              ),
              size: Size.infinite,
            ),
          ),
        );
    return still
        ? field(0.35)
        : AnimatedBuilder(
            animation: _motion,
            builder: (_, _) => field(_motion.value),
          );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter({
    required this.phase,
    required this.intensity,
    required this.showDust,
  });

  final double phase;
  final double intensity;
  final bool showDust;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.06, 0.10, 0.35, 0.11),
    (0.18, 0.06, 0.30, 0.09),
    (0.32, 0.14, 0.38, 0.12),
    (0.52, 0.08, 0.32, 0.10),
    (0.72, 0.12, 0.35, 0.11),
    (0.88, 0.06, 0.30, 0.09),
    (0.14, 0.38, 0.32, 0.10),
    (0.44, 0.52, 0.35, 0.09),
    (0.68, 0.68, 0.30, 0.08),
    (0.84, 0.82, 0.38, 0.10),
    (0.26, 0.24, 0.28, 0.07),
    (0.58, 0.32, 0.30, 0.08),
  ];

  static const _dust = <(double x, double y)>[
    (0.10, 0.22),
    (0.24, 0.44),
    (0.40, 0.30),
    (0.58, 0.58),
    (0.76, 0.36),
    (0.90, 0.64),
    (0.34, 0.72),
    (0.62, 0.18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final (x, y, r, a) = _stars[i];
      final tw = 0.55 + sin(phase * pi * 2 + i * 0.55) * 0.45;
      final useGold = i.isEven;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()
          ..color = (useGold ? AppColors.goldLight : Colors.white)
              .withValues(alpha: a * tw * intensity),
      );
    }
    if (!showDust) return;
    for (var i = 0; i < _dust.length; i++) {
      final (x, y) = _dust[i];
      final drift = sin(phase * pi * 2 + i) * 2.5;
      final alpha = 0.10 + sin(phase * pi * 2 + i * 0.7) * 0.05;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        0.7,
        Paint()
          ..color = AppColors.gold.withValues(alpha: alpha * intensity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.phase != phase ||
      old.intensity != intensity ||
      old.showDust != showDust;
}
