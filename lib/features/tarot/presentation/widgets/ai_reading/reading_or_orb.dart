/// OR-1060 — Small glowing OR orb for AI reading header.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';

class ReadingOrOrb extends StatefulWidget {
  const ReadingOrOrb({super.key, this.size = 36});

  final double size;

  @override
  State<ReadingOrOrb> createState() => _ReadingOrOrbState();
}

class _ReadingOrOrbState extends State<ReadingOrOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.5);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    if (still) return _OrbVisual(size: widget.size, glow: 0.5);
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final glow = 0.5 + sin(_breath.value * pi) * 0.5;
        return _OrbVisual(size: widget.size, glow: glow);
      },
    );
  }
}

class _OrbVisual extends StatelessWidget {
  const _OrbVisual({required this.size, required this.glow});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleGlow.withValues(alpha: 0.35 + glow * 0.25),
            blurRadius: 16 + glow * 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.22 + glow * 0.18),
            blurRadius: 10 + glow * 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.goldLight.withValues(alpha: 0.85),
                AppColors.purple.withValues(alpha: 0.75),
                AppColors.purpleDark,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.45),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              'OR',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: size * 0.32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
