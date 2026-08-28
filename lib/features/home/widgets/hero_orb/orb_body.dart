/// OR-031B — Layer 3: deep glass sphere with thick glowing purple ring.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import 'orb_constants.dart';

/// Crystal glass shell — layered depth, thick illuminated purple ring.
class OrbBody extends StatelessWidget {
  const OrbBody({super.key, required this.size});

  final double size;

  static const RadialGradient _sphereVolume = RadialGradient(
    center: Alignment(-0.22, -0.26),
    focal: Alignment(-0.44, -0.50),
    focalRadius: 0.06,
    radius: 0.98,
    colors: [
      Color(0xE6F0D77A),
      Color(0xCCB794FF),
      Color(0xB39B6DFF),
      Color(0xCC23153C),
      Color(0xE612071F),
      Color(0xF00B0615),
    ],
    stops: [0.0, 0.14, 0.34, 0.58, 0.80, 1.0],
  );

  static const RadialGradient _innerDepth = RadialGradient(
    center: Alignment(0.24, 0.32),
    radius: 0.94,
    colors: [
      AppColors.transparent,
      Color(0x559B6DFF),
      Color(0x9912071F),
      Color(0xCC0B0615),
    ],
    stops: [0.28, 0.62, 0.84, 1.0],
  );

  static const RadialGradient _innerVolume = RadialGradient(
    center: Alignment(-0.06, -0.04),
    radius: 0.76,
    colors: [
      Color(0x30F0D77A),
      AppColors.transparent,
      Color(0x5512071F),
    ],
    stops: [0.0, 0.46, 1.0],
  );

  static const RadialGradient _bottomVignette = RadialGradient(
    center: Alignment(0.10, 0.76),
    radius: 0.70,
    colors: [
      AppColors.transparent,
      Color(0x8812071F),
      Color(0xCC0B0615),
    ],
    stops: [0.28, 0.68, 1.0],
  );

  static const RadialGradient _edgeRefraction = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      AppColors.transparent,
      AppColors.transparent,
      Color(0x44B794FF),
      Color(0x55FFFFFF),
    ],
    stops: [0.0, 0.82, 0.93, 1.0],
  );

  static const RadialGradient _glassSheen = RadialGradient(
    center: Alignment(-0.34, -0.40),
    radius: 0.48,
    colors: [
      Color(0x55FFFFFF),
      Color(0x22F5F2FA),
      AppColors.transparent,
    ],
    stops: [0.0, 0.18, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final diameter = OrbLayout.sphereDiameter(size);
    final ringInset = OrbLayout.outerRingWidth(size);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _sphereVolume,
              boxShadow: [
                ...AppShadows.soft,
                BoxShadow(
                  color: AppColors.glowPurple.withValues(alpha: 0.40),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.55),
                  blurRadius: AppSpacing.lg,
                  offset: Offset(0, diameter * 0.05),
                ),
              ],
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _bottomVignette,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _innerDepth,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _innerVolume,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ringInset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.purpleGlow.withValues(alpha: 0.45),
                    AppColors.purpleLight.withValues(alpha: 0.30),
                    AppColors.transparent,
                  ],
                  stops: const [0.68, 0.82, 0.90, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleGlow.withValues(alpha: 0.50),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.purpleLight.withValues(alpha: 0.28),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ringInset * 0.72),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.purpleLight.withValues(alpha: 0.55),
                  width: AppBorderWidth.thin + AppBorderWidth.hairline,
                ),
                gradient: RadialGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.purpleGlow.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _edgeRefraction,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _glassSheen,
            ),
          ),
        ],
      ),
    );
  }
}
