/// EPIC-008 — Chamber waiting presence — breath, not spinner.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/theme/home_observatory.dart';

/// A quiet pulsing orb — loading that feels like the chamber listening.
class ChamberWaitingOrb extends StatefulWidget {
  const ChamberWaitingOrb({
    super.key,
    this.size = AppSpacing.xxl,
    this.seed = 0,
  });

  final double size;
  final int seed;

  @override
  State<ChamberWaitingOrb> createState() => _ChamberWaitingOrbState();
}

class _ChamberWaitingOrbState extends State<ChamberWaitingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    final offset = (widget.seed % 7) * 0.09;
    _pulse = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 18000 + (widget.seed % 5) * 2300,
      ),
      value: offset,
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final channel = HomeObservatoryTime.breathe(widget.seed + 1);
        final t = sin((_pulse.value + channel * 0.12) * pi * 2);
        final glow = 0.42 + t.abs() * 0.28;
        final scale = 0.94 + t.abs() * 0.06;
        final drift = HomeObservatoryTime.particleOffset(widget.seed, _pulse.value);

        return Transform.translate(
          offset: Offset(drift.dx * 0.35, drift.dy * 0.35),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(
                    -0.08 + (widget.seed % 3) * 0.04,
                    -0.12,
                  ),
                  colors: [
                    AppColors.goldLight.withValues(alpha: glow),
                    AppColors.gold.withValues(alpha: glow * 0.55),
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.18 + t.abs() * 0.12),
                    blurRadius: 14 + t.abs() * 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
