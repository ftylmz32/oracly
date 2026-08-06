/// OR-1040 — Darker atmospheric background for card selection.
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';

class CardSelectionBackground extends StatefulWidget {
  const CardSelectionBackground({super.key, this.sacred = 0});

  final double sacred;

  @override
  State<CardSelectionBackground> createState() => _CardSelectionBackgroundState();
}

class _CardSelectionBackgroundState extends State<CardSelectionBackground>
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
        final driftScale = 1 - widget.sacred * 0.82;
        final breath = 0.5 + sin(t * pi * 2) * 0.5 * driftScale;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: OraclySignatureChamber.selection),
            Positioned(
              top: 120 + sin(t * pi * 2) * 10 * driftScale,
              left: -50,
              child: _FogBlob(
                size: 260 + breath * 16,
                color: AppColors.purpleDark.withValues(
                  alpha: (OraclySignatureMaterials.particleAlpha * 3.3 + breath * 0.05) *
                      (1 - widget.sacred * 0.58),
                ),
              ),
            ),
            Positioned(
              bottom: 80 + sin(t * pi * 2 + 1.2) * 8 * driftScale,
              right: -60,
              child: _FogBlob(
                size: 300 + breath * 20,
                color: AppColors.purple.withValues(
                  alpha: (0.14 + breath * 0.04) * (1 - widget.sacred * 0.65),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.28),
                    radius: 1.05 - widget.sacred * 0.12,
                    colors: [
                      AppColors.purpleGlow.withValues(alpha: widget.sacred * 0.04),
                      AppColors.transparent,
                      Colors.black.withValues(alpha: 0.52 + widget.sacred * 0.24),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
            ColoredBox(color: Colors.black.withValues(alpha: 0.18 + widget.sacred * 0.16)),
          ],
        );
      },
    );
  }
}

class _FogBlob extends StatelessWidget {
  const _FogBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
