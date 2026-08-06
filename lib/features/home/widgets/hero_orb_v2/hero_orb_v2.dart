/// OR-100 — Premium hero orb image asset widget.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';

/// Hero orb rendered from the premium reference asset (no CustomPainter).
class HeroOrbV2 extends StatelessWidget {
  const HeroOrbV2({
    super.key,
    this.size = AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
  });

  final double size;

  static const double _renderScale = 1.55;

  @override
  Widget build(BuildContext context) {
    final renderSize = size * _renderScale;

    return SizedBox(
      width: renderSize,
      height: renderSize,
      child: RepaintBoundary(
        child: Image.asset(
          AppAssets.heroOrbPremium,
          width: renderSize,
          height: renderSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
