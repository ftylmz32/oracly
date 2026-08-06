/// OR-200 — Hero Orb asset precaching.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';

/// Ensures the reference PNG is decoded once and reused across frames.
abstract final class OrbCache {
  OrbCache._();

  static bool _precached = false;

  static Future<void> precache(BuildContext context) async {
    if (_precached) return;
    await precacheImage(
      const AssetImage(AppAssets.heroOrbPremium),
      context,
    );
    _precached = true;
  }

  @visibleForTesting
  static void resetForTest() => _precached = false;
}
