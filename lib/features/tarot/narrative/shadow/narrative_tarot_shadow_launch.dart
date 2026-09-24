/// Phase 6E — live-launch Classical spread set (6F candidate only).
library;

import '../../domain/models/tarot_spread.dart';

/// 6E/6F launch Classical spreads — seven / celtic / Crossroads excluded.
abstract final class NarrativeTarotShadowLaunch {
  NarrativeTarotShadowLaunch._();

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
