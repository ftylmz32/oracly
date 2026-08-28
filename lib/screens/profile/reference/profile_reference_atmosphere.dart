/// Profile chamber shell — warm private study over midnight, not a public sky.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/design_system/oracly_cosmic_background.dart';
import '../../../shared/widgets/oracly_asset_image.dart';

class ProfileReferenceAtmosphere extends StatelessWidget {
  const ProfileReferenceAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return OraclyCosmicBackground(
      heroGlow: false,
      showStars: false,
      showNebula: false,
      showDust: false,
      child: OraclyChamberVeil(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!light)
              IgnorePointer(
                child: Opacity(
                  opacity: 0.34,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.profileJournalHero,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.28),
                    filterQuality: FilterQuality.medium,
                    fallback: const SizedBox.expand(),
                  ),
                ),
              ),
            if (!light)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.35),
                      radius: 1.15,
                      colors: [
                        const Color(0xFFC4A574).withValues(alpha: 0.08),
                        OraclyChrome.violet.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
            if (!light)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OraclyChrome.midnight.withValues(alpha: 0.28),
                        Colors.transparent,
                        OraclyChrome.midnight.withValues(alpha: 0.62),
                        OraclyChrome.midnight.withValues(alpha: 0.92),
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
