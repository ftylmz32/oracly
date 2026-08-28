/// Astrology celestial shell - illustrated observatory atmosphere.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import 'astrology_starfield.dart';

class AstrologyReferenceAtmosphere extends StatelessWidget {
  const AstrologyReferenceAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return OraclyCosmicBackground(
        showStars: false,
        showDust: false,
        heroGlow: false,
        child: OraclyChamberVeil(child: child),
      );
    }
    return OraclyCosmicBackground(
      heroGlow: true,
      // Astrology owns its own low-cost parallax starfield.
      showStars: false,
      showDust: false,
      child: OraclyChamberVeil(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: 0.78,
                child: OraclyAssetImage(
                  assetPath: AppAssets.astrologyObservatoryBg,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.12),
                  filterQuality: FilterQuality.high,
                  fallback: const SizedBox.expand(),
                ),
              ),
            ),
            IgnorePointer(
              child: AstrologyStarfield(intensity: 0.92),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.18),
                    radius: 1.12,
                    colors: [
                      OraclyChrome.gold.withValues(alpha: 0.10),
                      OraclyChrome.violet.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.38, 1.0],
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
                      OraclyChrome.midnight.withValues(alpha: 0.18),
                      Colors.transparent,
                      OraclyChrome.midnight.withValues(alpha: 0.48),
                    ],
                    stops: const [0.0, 0.40, 1.0],
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
