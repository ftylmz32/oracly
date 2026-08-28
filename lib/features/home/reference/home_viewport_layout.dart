/// Responsive Home densities — scroll-friendly preferred sizes.
library;

import 'package:flutter/material.dart';

/// Budgets preferred section sizes for natural vertical scroll.
/// Short screens scroll; sections are never crushed into Expanded flex.
final class HomeViewportLayout {
  const HomeViewportLayout({
    required this.headerHeight,
    required this.headerToGreeting,
    required this.greetingToHero,
    required this.heroToOr,
    required this.orToToday,
    required this.heroToModules,
    required this.modulesToPremium,
    required this.greetingHeight,
    required this.todayMomentHeight,
    required this.orGuideHeight,
    required this.premiumHeight,
    required this.heroSlotHeight,
    required this.gridSlotHeight,
    required this.heroArtSize,
    required this.heroPadding,
    required this.energyFontSize,
    required this.moduleTileHeight,
    required this.moduleGap,
    required this.modulePadding,
    required this.moduleIconWell,
    required this.moduleIconSize,
    required this.premiumPadding,
    required this.premiumCrownSize,
    required this.greetingTitleSize,
    required this.greetingSubtitleSize,
  });

  final double headerHeight;
  final double headerToGreeting;
  final double greetingToHero;
  final double heroToOr;
  final double orToToday;
  final double heroToModules;
  final double modulesToPremium;
  final double greetingHeight;
  final double todayMomentHeight;
  final double orGuideHeight;
  final double premiumHeight;
  final double heroSlotHeight;
  final double gridSlotHeight;
  final double heroArtSize;
  final EdgeInsets heroPadding;
  final double energyFontSize;
  final double moduleTileHeight;
  final double moduleGap;
  final EdgeInsets modulePadding;
  final double moduleIconWell;
  final double moduleIconSize;
  final EdgeInsets premiumPadding;
  final double premiumCrownSize;
  final double greetingTitleSize;
  final double greetingSubtitleSize;

  static double _t(double maxHeight) =>
      ((maxHeight - 700) / 240).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Preferred sizes from screen height hint (not a zero-scroll fit budget).
  static HomeViewportLayout resolve(double maxHeight) {
    final compact = maxHeight < 720;
    final t = compact ? 0.2 : _t(maxHeight);

    const discoveriesBand = 34.0;
    final gap = compact ? 12.0 : _lerp(13, 16, t);
    final header = compact ? 46.0 : _lerp(48, 52, t);
    final hero = compact ? 168.0 : _lerp(176, 192, t);
    final orGuide = compact ? 120.0 : _lerp(124, 138, t);
    final todayCard = compact ? 118.0 : _lerp(122, 136, t);
    final premium = compact ? 74.0 : _lerp(78, 88, t);
    final moduleGap = compact ? 9.0 : _lerp(10, 12, t);
    // Readable minimum — never crush tiles on short phones.
    final tile = (compact ? 100.0 : _lerp(104, 114, t)).clamp(96.0, 120.0);
    // Seven doors → three rows in a 3-column wrap.
    const rowCount = 3;
    final gridSlot =
        tile * rowCount + moduleGap * (rowCount - 1) + discoveriesBand;
    final padV = compact ? 12.0 : 14.0;
    final heroArt = (hero - padV * 2).clamp(108.0, _lerp(128, 156, t));

    return HomeViewportLayout(
      headerHeight: header,
      headerToGreeting: 0,
      greetingToHero: gap,
      heroToOr: gap,
      orToToday: gap,
      heroToModules: gap,
      modulesToPremium: gap,
      greetingHeight: 0,
      todayMomentHeight: todayCard,
      orGuideHeight: orGuide,
      premiumHeight: premium,
      heroSlotHeight: hero,
      gridSlotHeight: gridSlot,
      heroArtSize: heroArt,
      heroPadding: EdgeInsets.zero,
      energyFontSize: compact ? 26.0 : _lerp(28, 32, t),
      moduleTileHeight: tile,
      moduleGap: moduleGap,
      modulePadding: EdgeInsets.zero,
      moduleIconWell: compact ? 40.0 : _lerp(44, 52, t),
      moduleIconSize: compact ? 22.0 : _lerp(24, 30, t),
      premiumPadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      premiumCrownSize: compact ? 32.0 : _lerp(34, 40, t),
      greetingTitleSize: compact ? 17.0 : _lerp(18, 20, t),
      greetingSubtitleSize: compact ? 10.0 : _lerp(10.5, 11.5, t),
    );
  }
}
