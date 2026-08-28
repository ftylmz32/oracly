/// Profile hero plate — private study chamber, fixed 16:7. No layout jump.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../shared/widgets/oracly_asset_image.dart';

class ProfileReferenceHeroPlate extends StatelessWidget {
  const ProfileReferenceHeroPlate({super.key});

  static const double aspectRatio = 16 / 7;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OraclyAssetImage(
            assetPath: AppAssets.profileJournalHero,
            fit: BoxFit.cover,
            // Keep journal + brass instruments in the 16:7 band.
            alignment: const Alignment(0.0, -0.08),
            filterQuality: FilterQuality.high,
            fallback: ColoredBox(
              color: OraclyChrome.midnight.withValues(alpha: 0.9),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.transparent,
                  OraclyChrome.midnight.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.55, -0.15),
                  radius: 1.15,
                  colors: [
                    const Color(0xFFC4A574).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
