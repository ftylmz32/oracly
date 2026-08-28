/// OR-050 — Daily Energy Details shared constants.
library;

import '../../core/design_system/app_layout.dart';

/// Hero tags and layout tokens for the daily energy details flow.
abstract final class DailyEnergyHeroTags {
  DailyEnergyHeroTags._();

  static const String moonIllustration = 'daily_energy_moon_hero';
}

abstract final class DailyEnergyLayout {
  DailyEnergyLayout._();

  static const double maxContentWidth = AppLayout.maxContentWidth;
  static const double detailOrbSize = 168;
}
