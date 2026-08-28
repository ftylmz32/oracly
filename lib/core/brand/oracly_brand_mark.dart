/// Official ORACLY logo — asset only, never redrawn geometry.
library;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../../shared/widgets/oracly_asset_image.dart';

/// Hosts the official ORACLY logo for splash, headers, and brand moments.
///
/// Source master: `assets/brand/oracly_launcher_source.png`
/// Runtime: [AppAssets.brandLogo]
class OraclyBrandMark extends StatelessWidget {
  const OraclyBrandMark({
    super.key,
    this.size = 96,
    this.forLauncher = false,
  });

  /// Layout box (square). Image uses [BoxFit.contain] to preserve aspect ratio.
  final double size;

  /// Kept for call-site compatibility; denser decode ceiling when true.
  final bool forLauncher;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final maxCache = forLauncher ? 512 : 384;
    // Decode near display pixels — not a fixed 384px bitmap for a 24px header.
    final needed = (size * dpr * 1.25).round();
    final cache = needed.clamp(48, maxCache);
    return Semantics(
      label: 'ORACLY',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: OraclyAssetImage(
          assetPath: AppAssets.brandLogo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheCapPx: cache,
          fallback: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
