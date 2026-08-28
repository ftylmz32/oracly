/// Small photoreal empty-state plate — never cartoon, never a blank void.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/chamber_hero_stage.dart';
import '../../core/design_system/oracly_chrome.dart';
import 'oracly_asset_image.dart';

class OraclyEmptyAtmosphere extends StatelessWidget {
  const OraclyEmptyAtmosphere({
    super.key,
    required this.assetPath,
    this.size = 112,
    this.warm = false,
  });

  final String assetPath;
  final double size;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ChamberHeroStage(
        warm: warm,
        glow: 0.92,
        child: ClipOval(
          child: OraclyAssetImage(
            assetPath: assetPath,
            width: size * 0.78,
            height: size * 0.78,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            cacheCapPx: 512,
            fallback: ColoredBox(
              color: OraclyChrome.midnight,
              child: Icon(
                Icons.nights_stay_outlined,
                size: size * 0.22,
                color: OraclyChrome.gold.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
