/// Feature atmospheres for every async surface — never unrelated art.
library;

import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../loading_cinema/oracly_loading_kind.dart';
import '../oracly_chrome.dart';

/// Shared DNA + feature identity for loading / empty / error / offline / retry.
abstract final class OraclyAsyncAtmosphere {
  OraclyAsyncAtmosphere._();

  static String plate(OraclyLoadingKind kind) => switch (kind) {
        OraclyLoadingKind.coffee => AppAssets.coffeeRitualHero,
        OraclyLoadingKind.tarot => AppAssets.tarotHero,
        OraclyLoadingKind.astrology => AppAssets.astrologyInstrumentPlate,
        OraclyLoadingKind.yildizname => AppAssets.yildiznameHero,
        OraclyLoadingKind.soulMate => AppAssets.homeSoulMate,
        OraclyLoadingKind.orPresence => AppAssets.heroOrbPremium,
        OraclyLoadingKind.chamber => AppAssets.dailyMoonPhotoreal,
      };

  static bool warm(OraclyLoadingKind kind) => switch (kind) {
        OraclyLoadingKind.coffee => true,
        OraclyLoadingKind.soulMate => true,
        _ => false,
      };

  /// Amber for recoverable error/retry; cream for offline; gold for empty.
  static Color ring(OraclyLoadingKind kind, {required bool offline}) {
    if (offline) {
      return OraclyChrome.cream.withValues(alpha: 0.42);
    }
    return switch (kind) {
      OraclyLoadingKind.coffee => const Color(0xFFC9A46C),
      OraclyLoadingKind.tarot => OraclyChrome.goldLight,
      OraclyLoadingKind.astrology => OraclyChrome.gold.withValues(alpha: 0.85),
      OraclyLoadingKind.yildizname => OraclyChrome.goldLight,
      OraclyLoadingKind.soulMate => OraclyChrome.goldLight,
      OraclyLoadingKind.orPresence => OraclyChrome.gold,
      OraclyLoadingKind.chamber => const Color(0xFFC9A46C),
    };
  }
}
