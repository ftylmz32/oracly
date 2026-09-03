/// Responsive Home densities — cinematic preferred sizes; scroll when needed.
library;

import 'package:flutter/material.dart';

import '../master/home_master_budget.dart';

/// Budgets preferred section sizes from the master visual reference.
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
    required this.dreamExtensionHeight,
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
  final double dreamExtensionHeight;
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

  static const int coreGridRows = 2;
  static const double discoveriesBand = HomeMasterBudget.discoveriesBand;

  static double _t(double maxHeight) =>
      ((maxHeight - 700) / 240).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Preferred cinematic sizes from screen height hint.
  static HomeViewportLayout resolve(double maxHeight) {
    final compact = maxHeight < 720;
    final t = compact ? 0.25 : _t(maxHeight);

    final gap = compact ? 12.0 : _lerp(14, 16, t);
    final header = compact ? 48.0 : _lerp(50, 54, t);
    final hero = compact ? 168.0 : _lerp(176, 196, t);
    final orGuide = compact ? 118.0 : _lerp(124, 140, t);
    // Ritual card only — section label is drawn above by HomeTodayTrace.
    final today = compact ? 118.0 : _lerp(122, 136, t);
    final premium = compact ? 76.0 : _lerp(80, 92, t);
    final moduleGap = compact ? 10.0 : _lerp(11, 13, t);
    final tile = (compact ? 108.0 : _lerp(112, 124, t)).clamp(104.0, 128.0);
    final dreamExt = compact ? 72.0 : _lerp(76, 84, t);
    final gridSlot = discoveriesBand +
        tile * coreGridRows +
        moduleGap * (coreGridRows - 1) +
        moduleGap +
        dreamExt;
    final padV = compact ? 12.0 : 14.0;
    final heroArt = (hero - padV * 2).clamp(112.0, _lerp(132, 160, t));

    return HomeViewportLayout(
      headerHeight: header,
      headerToGreeting: 0,
      greetingToHero: gap,
      heroToOr: gap,
      orToToday: gap,
      heroToModules: gap,
      modulesToPremium: gap,
      greetingHeight: 0,
      todayMomentHeight: today,
      orGuideHeight: orGuide,
      premiumHeight: premium,
      heroSlotHeight: hero,
      gridSlotHeight: gridSlot,
      dreamExtensionHeight: dreamExt,
      heroArtSize: heroArt,
      heroPadding: EdgeInsets.zero,
      energyFontSize: compact ? 26.0 : _lerp(28, 32, t),
      moduleTileHeight: tile,
      moduleGap: moduleGap,
      modulePadding: EdgeInsets.zero,
      moduleIconWell: compact ? 42.0 : _lerp(46, 54, t),
      moduleIconSize: compact ? 24.0 : _lerp(26, 32, t),
      premiumPadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      premiumCrownSize: compact ? 32.0 : _lerp(34, 40, t),
      greetingTitleSize: compact ? 18.0 : _lerp(19, 22, t),
      greetingSubtitleSize: compact ? 11.0 : _lerp(11.5, 12.5, t),
    );
  }

  /// Total preferred content stack height (five gaps between six bands).
  double get preferredContentHeight =>
      headerHeight +
      greetingToHero +
      heroSlotHeight +
      heroToOr +
      orGuideHeight +
      orToToday +
      todayMomentHeight +
      HomeMasterBudget.todaySectionOverhead +
      heroToModules +
      gridSlotHeight +
      modulesToPremium +
      premiumHeight;
}
