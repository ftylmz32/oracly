/// Cinematic entry atmosphere — photoreal chamber plate, soft veil.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class SoulMateEntryHero extends StatelessWidget {
  const SoulMateEntryHero({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 21 / 9,
      child: ClipRRect(
        borderRadius: OraclyChrome.heroRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const OraclyAssetImage(
              assetPath: AppAssets.homeSoulMate,
              fit: BoxFit.cover,
              alignment: Alignment(0, -0.16),
              filterQuality: FilterQuality.high,
              fallback: ColoredBox(color: Color(0xFF0A0614)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
