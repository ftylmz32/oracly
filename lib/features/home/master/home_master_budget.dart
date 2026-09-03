/// Home section floors — guidance only; never force-fit by crushing.
library;

import 'package:flutter/foundation.dart';

/// Readable minimums used by preferred layout math.
@immutable
final class HomeMasterBudget {
  const HomeMasterBudget({
    required this.header,
    required this.gap,
    required this.hero,
    required this.orSection,
    required this.today,
    required this.grid,
    required this.premium,
    required this.contentHeight,
    required this.navClearance,
    required this.fitsReadableGrid,
  });

  final double header;
  final double gap;
  final double hero;
  final double orSection;
  final double today;
  final double grid;
  final double premium;
  final double contentHeight;
  final double navClearance;
  final bool fitsReadableGrid;

  static const int gapCount = 5;
  static const double discoveriesBand = 30.0;

  /// Core discovery is 3×2 (reference). Dream sits as a secondary extension.
  static const int gridRows = 2;
  static const double minModuleTile = 104.0;
  static const double todaySectionOverhead = 30.0;
  static const double todayCardMin = 100.0;
  static const double minHeroOrHeight = 118.0;
  static const double compositionSafety = 8.0;

  /// Diagnostic: whether preferred floors fit without scroll.
  static HomeMasterBudget resolve({
    required double maxHeight,
    required double navClearance,
  }) {
    final raw = maxHeight.isFinite ? maxHeight : 700.0;
    final content =
        (raw - navClearance - compositionSafety).clamp(300.0, raw);

    final header = 50.0;
    final gap = 14.0;
    final premium = 80.0;
    final hero = 176.0;
    final orSection = 124.0;
    final today = todayCardMin + todaySectionOverhead;
    final grid = discoveriesBand +
        minModuleTile * gridRows +
        gap * (gridRows - 1) +
        gap +
        76.0;

    final allocated = header +
        premium +
        (gap * gapCount) +
        hero +
        orSection +
        today +
        grid;

    return HomeMasterBudget(
      header: header,
      gap: gap,
      hero: hero,
      orSection: orSection,
      today: today,
      grid: grid,
      premium: premium,
      contentHeight: content,
      navClearance: navClearance,
      fitsReadableGrid: content >= allocated,
    );
  }

  double get allocated =>
      header +
      premium +
      (gap * gapCount) +
      hero +
      orSection +
      today +
      grid;
}
