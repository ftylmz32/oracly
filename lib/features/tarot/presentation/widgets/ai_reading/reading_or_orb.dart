/// OR-1060 — Small glowing OR orb for AI reading header.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

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
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final glow = 0.5 + sin(_breath.value * pi) * 0.5;
        return Container(
          width: widget.size + 12,
          height: widget.size + 12,
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
              width: widget.size,
              height: widget.size,
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
                    fontSize: widget.size * 0.32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
