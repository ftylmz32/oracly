/// Dream-only celestial shell — same Home/Tarot material, Dream scope.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';

class DreamReferenceAtmosphere extends StatelessWidget {
  const DreamReferenceAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OraclyCosmicBackground(
      heroGlow: true,
      showDust: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.08),
                  radius: 0.92,
                  colors: [
                    Color(0x3D2A1B5C),
                    Color(0x180C0820),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.02),
                  radius: 0.62,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.032),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
