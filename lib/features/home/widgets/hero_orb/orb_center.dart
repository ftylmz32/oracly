/// OR-035 — Living magical energy core inside the crystal sphere.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'orb_constants.dart';

/// Volumetric gold nucleus — layered plasma that illuminates the glass interior.
class OrbCenter extends StatelessWidget {
  const OrbCenter({super.key, required this.size});

  final double size;

  static const Alignment _energyBias = Alignment(-0.14, -0.16);

  /// Layer A — large warm energy cloud with soft purple rim reflection.
  static const RadialGradient _energyCloud = RadialGradient(
    center: _energyBias,
    radius: 1.0,
    colors: [
      Color(0x28F0D77A),
      Color(0x22D4AF37),
      Color(0x18E8A838),
      Color(0x129B6DFF),
      AppColors.transparent,
    ],
    stops: [0.0, 0.34, 0.56, 0.78, 1.0],
  );

  /// Layer B — golden plasma body.
  static const RadialGradient _goldenPlasma = RadialGradient(
    center: Alignment(-0.10, -0.12),
    radius: 0.90,
    colors: [
      Color(0xAAF0D77A),
      Color(0x88D4AF37),
      Color(0x55E8A838),
      Color(0x22D4AF37),
      AppColors.transparent,
    ],
    stops: [0.0, 0.28, 0.52, 0.72, 1.0],
  );

  /// Layer C — white-hot heart: white → ivory → gold.
  static const RadialGradient _whiteHotCenter = RadialGradient(
    center: Alignment(-0.18, -0.20),
    radius: 0.74,
    colors: [
      AppColors.white,
      Color(0xEEF5F2FA),
      Color(0xCCF0D77A),
      Color(0x66D4AF37),
      AppColors.transparent,
    ],
    stops: [0.0, 0.16, 0.40, 0.64, 1.0],
  );

  /// Layer D — tiny asymmetric nucleus.
  static const RadialGradient _tinyNucleus = RadialGradient(
    center: Alignment(-0.22, -0.24),
    radius: 0.62,
    colors: [
      AppColors.white,
      Color(0xAAFFFFFF),
      Color(0x44F0D77A),
      AppColors.transparent,
    ],
    stops: [0.0, 0.36, 0.58, 1.0],
  );

  /// Asymmetric specular kiss — breaks perfect radial symmetry.
  static const RadialGradient _asymmetricHighlight = RadialGradient(
    center: Alignment(-0.35, -0.42),
    radius: 0.55,
    colors: [
      Color(0x66FFFFFF),
      Color(0x22FFFFFF),
      AppColors.transparent,
    ],
    stops: [0.0, 0.42, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final outer = OrbLayout.coreOuter(size);
    final inner = OrbLayout.coreInner(size);
    final nucleus = OrbLayout.coreNucleus(size);
    final illuminate = outer * 1.22;
    final plasma = outer * 0.78;

    return SizedBox(
      width: illuminate,
      height: illuminate,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: illuminate,
            height: illuminate,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _energyCloud,
              ),
            ),
          ),
          SizedBox(
            width: plasma,
            height: plasma,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _goldenPlasma,
              ),
            ),
          ),
          SizedBox(
            width: inner,
            height: inner,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _whiteHotCenter,
              ),
            ),
          ),
          SizedBox(
            width: nucleus,
            height: nucleus,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _tinyNucleus,
              ),
            ),
          ),
          Positioned(
            left: illuminate * 0.20,
            top: illuminate * 0.14,
            child: SizedBox(
              width: illuminate * 0.14,
              height: illuminate * 0.14,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _asymmetricHighlight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
