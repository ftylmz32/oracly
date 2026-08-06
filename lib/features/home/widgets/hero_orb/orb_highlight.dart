/// OR-034 — Premium multi-layer crystal glass reflections.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'orb_constants.dart';

/// Curved glass reflections — primary, streak, specular, and fresnel rim.
class OrbHighlight extends StatelessWidget {
  const OrbHighlight({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final diameter = OrbLayout.sphereDiameter(size);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: _FresnelEdge()),
            _PrimaryReflection(diameter: diameter),
            _SecondaryStreak(diameter: diameter),
            _MicroSpecular(diameter: diameter),
          ],
        ),
      ),
    );
  }
}

/// Large upper-left curved wash — strongest at the glass edge, fading inward.
class _PrimaryReflection extends StatelessWidget {
  const _PrimaryReflection({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final sweep = diameter * 0.64;

    return Positioned(
      left: -diameter * 0.06,
      top: -diameter * 0.08,
      child: SizedBox(
        width: sweep,
        height: sweep,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.42, -0.48),
              radius: 0.92,
              colors: [
                AppColors.white.withValues(alpha: 0.46),
                AppColors.white.withValues(alpha: 0.22),
                AppColors.offWhite.withValues(alpha: 0.08),
                AppColors.goldLight.withValues(alpha: 0.03),
                AppColors.transparent,
              ],
              stops: const [0.0, 0.28, 0.48, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin bright streak hugging the sphere curvature below the primary glare.
class _SecondaryStreak extends StatelessWidget {
  const _SecondaryStreak({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: diameter * 0.10,
      top: diameter * 0.24,
      child: Transform.rotate(
        angle: -pi * 0.19,
        child: Container(
          width: diameter * 0.50,
          height: diameter * 0.035,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.elliptical(diameter * 0.25, diameter * 0.018),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.transparent,
                AppColors.white.withValues(alpha: 0.06),
                AppColors.white.withValues(alpha: 0.32),
                AppColors.white.withValues(alpha: 0.18),
                AppColors.transparent,
              ],
              stops: const [0.0, 0.18, 0.46, 0.72, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small specular hotspot at the upper-left edge.
class _MicroSpecular extends StatelessWidget {
  const _MicroSpecular({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final dot = diameter * 0.075;

    return Positioned(
      left: diameter * 0.17,
      top: diameter * 0.09,
      child: SizedBox(
        width: dot,
        height: dot,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.white.withValues(alpha: 0.95),
                AppColors.white.withValues(alpha: 0.45),
                AppColors.transparent,
              ],
              stops: const [0.0, 0.38, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle fresnel brightening along the upper-left glass rim.
class _FresnelEdge extends StatelessWidget {
  const _FresnelEdge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.88, -0.92),
          radius: 1.18,
          colors: [
            AppColors.transparent,
            AppColors.transparent,
            AppColors.white.withValues(alpha: 0.14),
            AppColors.white.withValues(alpha: 0.06),
            AppColors.transparent,
          ],
          stops: [0.0, 0.70, 0.84, 0.92, 1.0],
        ),
      ),
    );
  }
}
