/// OR-200 — Reference photorealistic base layer (hero_orb_premium.png).
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/performance/oracly_decode_cache.dart';

/// Static reference reconstruction — crystal, pedestal, rings, logo, nebula.
class OrbBaseLayer extends StatelessWidget {
  const OrbBaseLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logical = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 390.0;
        final cacheW = oraclyDecodeCachePx(
          logical,
          MediaQuery.devicePixelRatioOf(context),
        );
        return Image.asset(
          AppAssets.heroOrbPremium,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          cacheWidth: cacheW,
        );
      },
    );
  }
}
