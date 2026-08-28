/// OR-200 — Hero Orb asset precaching (decode-capped, never full 4K).
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/performance/oracly_decode_cache.dart';

/// Ensures the reference PNG is decoded once at display size and reused.
abstract final class OrbCache {
  OrbCache._();

  static bool _precached = false;

  static Future<void> precache(BuildContext context) async {
    if (_precached) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logical = MediaQuery.sizeOf(context).shortestSide.clamp(280.0, 420.0);
    final width = oraclyDecodeCachePx(logical, dpr) ?? 1024;
    await precacheImage(
      ResizeImage(
        const AssetImage(AppAssets.heroOrbPremium),
        width: width,
      ),
      context,
    );
    _precached = true;
  }

  @visibleForTesting
  static void resetForTest() => _precached = false;
}
