/// Photoreal plate paths for campaign share cards — Flutter owns all text.
library;

import '../../../core/constants/app_assets.dart';
import '../models/shareable_discovery.dart';

abstract final class DiscoveryShareCardAssets {
  DiscoveryShareCardAssets._();

  static String? plateFor(DiscoveryShareKind kind) => switch (kind) {
        DiscoveryShareKind.coffee => AppAssets.coffeeRitualHero,
        DiscoveryShareKind.tarot => AppAssets.homeTarot,
        DiscoveryShareKind.astrology => AppAssets.homeAstrology,
        DiscoveryShareKind.starMap => AppAssets.yildiznameHero,
        DiscoveryShareKind.dailyInsight => AppAssets.dailyMoonPhotoreal,
        DiscoveryShareKind.palm => AppAssets.palmRitualHero,
        DiscoveryShareKind.soulMate => null,
      };
}
