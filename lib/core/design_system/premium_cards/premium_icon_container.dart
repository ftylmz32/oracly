/// EPIC-023 / EPIC-027 — Circular gradient icon container with micro motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_glows.dart';
import '../app_radius.dart';
import '../app_shadows.dart';
import '../micro_details/micro_detail_painters.dart';
import '../micro_details/micro_detail_tokens.dart';
import 'premium_card_tokens.dart';

/// Premium icon orb — gradient, gold rim, glow, reflection, subtle float.
class PremiumIconContainer extends StatefulWidget {
  const PremiumIconContainer({
    super.key,
    required this.child,
    this.size = PremiumCardTokens.iconContainerMd,
    this.glowing = false,
    this.seed = 0,
  });

  final Widget child;
  final double size;
  final bool glowing;
  final int seed;

  @override
  State<PremiumIconContainer> createState() => _PremiumIconContainerState();
}

class _PremiumIconContainerState extends State<PremiumIconContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.iconFloatCycle,
      value: (widget.seed.abs() % 100) / 100,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final phase = Curves.easeInOut.transform(_float.value);
        final floatY = math.sin(phase * math.pi * 2) *
            MicroDetailTokens.iconFloatAmplitude;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment(-0.4 + phase * 0.08, -1),
                end: Alignment(0.5, 1),
                colors: [
                  AppColors.surfaceElevated,
                  AppColors.surface,
                  AppColors.backgroundSecondary,
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(
                  alpha: widget.glowing ? 0.48 : 0.32,
                ),
                width: AppBorderWidth.hairline,
              ),
              boxShadow: [
                ...(widget.glowing
                    ? AppGlows.small(strength: 0.9 + phase * 0.2)
                    : AppShadows.soft),
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.06 + phase * 0.04),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: IconReflectionPainter(phase: phase),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
