/// Premium exclusive chamber shell — velvet warmth, gold depth, never a sky.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class PremiumReferenceAtmosphere extends StatelessWidget {
  const PremiumReferenceAtmosphere({super.key, required this.child});

  final Widget child;

  static const _ink = Color(0xFF050308);
  static const _champagne = Color(0xFFDCC9A3);
  static const _plum = Color(0xFF1C0E18);

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return OraclyCosmicBackground(
        heroGlow: false,
        showStars: false,
        showDust: false,
        child: OraclyChamberVeil(child: child),
      );
    }
    return OraclyCosmicBackground(
      heroGlow: false,
      showStars: false,
      showDust: false,
      showNebula: false,
      child: OraclyChamberVeil(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: 0.36,
                child: OraclyAssetImage(
                  assetPath: AppAssets.premiumChamberHero,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.22),
                  filterQuality: FilterQuality.medium,
                  fallback: const ColoredBox(color: _ink),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.15, -0.38),
                    radius: 1.12,
                    colors: [
                      _champagne.withValues(alpha: 0.10),
                      _plum.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.36, 1.0],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _ink.withValues(alpha: 0.34),
                      Colors.transparent,
                      _ink.withValues(alpha: 0.58),
                      _ink.withValues(alpha: 0.92),
                    ],
                    stops: const [0.0, 0.28, 0.62, 1.0],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
