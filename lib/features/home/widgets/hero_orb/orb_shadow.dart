/// OR-031B — Layer 9: ground contact shadow.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'orb_constants.dart';

/// Soft shadow anchoring the sphere on the home screen.
class OrbShadow extends StatelessWidget {
  const OrbShadow({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final width = OrbLayout.sphereDiameter(size) * 0.60;
    final height = OrbLayout.renderSize(size) * 0.052;

    return Positioned(
      left: 0,
      right: 0,
      bottom: OrbLayout.sphereInset(size) * 0.15,
      child: Center(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.elliptical(width * 0.5, height * 0.5),
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.background.withValues(alpha: 0.65),
                  AppColors.purple.withValues(alpha: 0.16),
                  AppColors.transparent,
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
