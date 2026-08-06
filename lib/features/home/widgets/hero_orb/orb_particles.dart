/// OR-031B — Layer 6: floating gold particles inside the sphere.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Subtle gold specks — depth and magic without distraction.
class OrbParticles extends StatelessWidget {
  const OrbParticles({super.key, required this.size});

  final double size;

  static const List<(double x, double y, double s, double a)> _specks = [
    (0.56, 0.42, 0.026, 0.62),
    (0.62, 0.50, 0.032, 0.55),
    (0.52, 0.46, 0.022, 0.50),
    (0.66, 0.56, 0.028, 0.46),
    (0.46, 0.38, 0.020, 0.48),
    (0.70, 0.44, 0.024, 0.42),
    (0.40, 0.50, 0.018, 0.40),
    (0.54, 0.60, 0.020, 0.44),
    (0.36, 0.36, 0.016, 0.38),
    (0.64, 0.34, 0.018, 0.42),
    (0.48, 0.32, 0.014, 0.36),
    (0.42, 0.58, 0.016, 0.40),
    (0.72, 0.52, 0.014, 0.36),
    (0.34, 0.44, 0.015, 0.38),
    (0.58, 0.66, 0.012, 0.34),
    (0.30, 0.52, 0.012, 0.32),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        for (final speck in _specks)
          Positioned(
            left: size * speck.$1,
            top: size * speck.$2,
            child: Container(
              width: size * speck.$3,
              height: size * speck.$3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldLight.withValues(alpha: speck.$4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: speck.$4 * 0.5),
                    blurRadius: size * speck.$3,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
