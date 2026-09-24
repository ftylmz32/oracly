/// Phase 6F — Classical spreads eligible for live Narrative V2 (not shadow).
library;

import '../../domain/models/tarot_spread.dart';

/// Live Classical launch set — seven / celtic / Crossroads excluded.
abstract final class NarrativeTarotLiveSpreads {
  NarrativeTarotLiveSpreads._();

  static const spreads = <TarotSpreadType>{
    TarotSpreadType.single,
    TarotSpreadType.threeCard,
    TarotSpreadType.fiveCard,
  };

  static bool isLiveLaunchCandidate(TarotSpreadType type) =>
      spreads.contains(type);

  /// Exact Narrative machine spread id for a launch Classical type.
  static String narrativeSpreadId(TarotSpreadType type) => switch (type) {
        TarotSpreadType.single => 'classical.single',
        TarotSpreadType.threeCard => 'classical.threeCard',
        TarotSpreadType.fiveCard => 'classical.fiveCard',
        _ => throw ArgumentError('not a live-launch Classical spread: $type'),
      };
}
