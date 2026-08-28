/// Responsive height budget for zero-scroll Home (KN8-first).
library;

import 'package:flutter/foundation.dart';

/// Explicit section heights that sum to the content viewport.
///
/// Bottom navigation clearance is reserved *outside* these heights
/// (body bottom padding via [AppLayout.scrollBottomInset]).
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

  /// Gaps between the six content bands (five spacers).
  static const int gapCount = 5;

  /// Flex weights for flexible bands (hero / OR / today / grid).
  static const int heroFlex = 30;
  static const int orFlex = 24;
  static const int todayFlex = 16;
  static const int gridFlex = 34;
  static const int flexTotal = heroFlex + orFlex + todayFlex + gridFlex;

  /// Resolves heights from the full body [maxHeight] (before nav padding).
  static HomeMasterBudget resolve({
    required double maxHeight,
    required double navClearance,
  }) {
    final raw = maxHeight.isFinite ? maxHeight : 700.0;
    final content = (raw - navClearance).clamp(300.0, raw);

    final tight = content < 520;
    final compact = content < 600;

    final header = tight ? 42.0 : (compact ? 44.0 : 48.0);
    final gap = tight ? 4.0 : (compact ? 6.0 : 8.0);
    final premium = tight ? 48.0 : (compact ? 52.0 : 56.0);

    final chrome = header + premium + (gap * gapCount);
    final flexible = (content - chrome).clamp(160.0, content);

    double slice(int flex) => flexible * flex / flexTotal;

    final hero = slice(heroFlex);
    final orSection = slice(orFlex);
    final today = slice(todayFlex);
    // Absorb rounding into grid so the column sums exactly.
    final grid = flexible - hero - orSection - today;

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
    );
  }

  /// Sum of content bands + gaps (must equal [contentHeight]).
  double get allocated =>
      header +
      premium +
      (gap * gapCount) +
      hero +
      orSection +
      today +
      grid;
}
