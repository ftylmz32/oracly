/// Hero atmosphere — light moves; portrait stays still.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../theme/home_ritual_visuals.dart';

class HomeReferenceHeroAtmosphere extends StatelessWidget {
  const HomeReferenceHeroAtmosphere({
    super.key,
    required this.t,
    required this.visual,
  });

  final double t;
  final HomeRitualVisual visual;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(t * math.pi * 2);
    final gold = (visual.goldAlpha + wave.abs() * 0.02).clamp(0.0, 0.55);
    final violet = (visual.violetAlpha + wave.abs() * 0.015).clamp(0.0, 0.55);
    final center = Alignment(
      visual.lightCenter.x + wave * 0.04,
      visual.lightCenter.y + math.cos(t * math.pi * 2) * 0.02,
    );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  visual.skyTop.withValues(alpha: visual.luminanceAlpha),
                  AppColors.amberSoft.withValues(alpha: visual.warmAlpha * 0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.38, 0.76],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: 1.05,
                colors: [
                  AppColors.goldLight.withValues(alpha: gold),
                  AppColors.midnightNavy.withValues(alpha: visual.coolAlpha),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.85),
                radius: 0.85,
                colors: [
                  AppColors.accentPink.withValues(alpha: visual.roseAlpha),
                  AppColors.primaryPurple.withValues(alpha: violet * 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  visual.textScrim,
                  visual.textScrim.withValues(alpha: 0.78),
                  visual.skyBottom.withValues(alpha: visual.nightDepthAlpha * 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.26, 0.48, 0.78],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  AppColors.nearBlack.withValues(alpha: visual.vignetteAlpha),
                ],
                stops: const [0.58, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
