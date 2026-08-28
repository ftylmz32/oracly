/// Yıldızname archive shell — stone, brass, candlelight, deep violet sky.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import 'star_map_archive_haze.dart';
import 'star_map_reference_tokens.dart';

class StarMapReferenceAtmosphere extends StatelessWidget {
  const StarMapReferenceAtmosphere({super.key, required this.child});

  final Widget child;

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
      child: OraclyChamberVeil(
        child: StarMapArchiveHaze(
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: 0.52,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.yildiznameArchiveBg,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.10),
                    filterQuality: FilterQuality.high,
                    fallback: ColoredBox(
                      color: StarMapReferenceTokens.archiveInk,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.36),
                      radius: 1.05,
                      colors: [
                        StarMapReferenceTokens.candleAmber.withValues(
                          alpha: 0.14,
                        ),
                        StarMapReferenceTokens.violetSky.withValues(
                          alpha: 0.12,
                        ),
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
                        StarMapReferenceTokens.archiveInk.withValues(
                          alpha: 0.24,
                        ),
                        Colors.transparent,
                        StarMapReferenceTokens.archiveInk.withValues(
                          alpha: 0.58,
                        ),
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
      ),
    );
  }
}
