/// OR-033 — Cinematic layered energy aura behind the hero orb.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'orb_constants.dart';

/// Layered magical aura — gradient-driven, softly suspended energy field.
class OrbEffects extends StatelessWidget {
  const OrbEffects({super.key, required this.size});

  final double size;

  static const Alignment _violetCloudCenter = Alignment(-0.20, -0.15);

  @override
  Widget build(BuildContext context) {
    final render = OrbLayout.renderSize(size);
    final suspend = Offset(0, render * 0.028);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        _EnergyAuraLayer(
          diameter: render * 1.90,
          offset: suspend,
          gradient: RadialGradient(
            radius: 1.0,
            colors: [
              AppColors.purple.withValues(alpha: 0.07),
              AppColors.purple.withValues(alpha: 0.04),
              AppColors.purpleLight.withValues(alpha: 0.02),
              AppColors.transparent,
            ],
            stops: const [0.0, 0.38, 0.68, 1.0],
          ),
        ),
        _EnergyAuraLayer(
          diameter: render * 1.55,
          offset: Offset(suspend.dx * 0.7, suspend.dy * 1.1),
          gradient: RadialGradient(
            center: _violetCloudCenter,
            radius: 0.96,
            colors: [
              AppColors.purpleDark.withValues(alpha: 0.14),
              AppColors.purple.withValues(alpha: 0.10),
              AppColors.purpleGlow.withValues(alpha: 0.05),
              AppColors.transparent,
            ],
            stops: const [0.0, 0.32, 0.62, 1.0],
          ),
        ),
        _EnergyAuraLayer(
          diameter: render * 1.18,
          offset: Offset(0, suspend.dy * 0.65),
          gradient: RadialGradient(
            radius: 0.90,
            colors: [
              AppColors.purpleLight.withValues(alpha: 0.38),
              AppColors.purpleGlow.withValues(alpha: 0.30),
              AppColors.purple.withValues(alpha: 0.14),
              AppColors.purple.withValues(alpha: 0.05),
              AppColors.transparent,
            ],
            stops: const [0.0, 0.22, 0.48, 0.72, 1.0],
          ),
        ),
        _EnergyAuraLayer(
          diameter: render * 0.92,
          offset: Offset(0, suspend.dy * 0.35),
          gradient: RadialGradient(
            radius: 0.72,
            colors: [
              AppColors.goldLight.withValues(alpha: 0.09),
              AppColors.goldGlow.withValues(alpha: 0.05),
              AppColors.transparent,
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
      ],
    );
  }
}

class _EnergyAuraLayer extends StatelessWidget {
  const _EnergyAuraLayer({
    required this.diameter,
    required this.gradient,
    required this.offset,
  });

  final double diameter;
  final RadialGradient gradient;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: offset,
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
