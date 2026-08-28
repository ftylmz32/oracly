/// Four honest spread choices — not occult arithmetic.
library;

import '../../../../../core/feature_flags/feature_flag_runtime.dart';
import '../../../../../core/feature_flags/product_feature_flags.dart';
import '../../../copy/tarot_l10n.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../domain/models/tarot_spread.dart';

class TarotEntrySpreadChoice {
  const TarotEntrySpreadChoice({
    required this.type,
    required this.blurb,
  });

  final TarotSpreadType type;
  final String blurb;

  String get title {
    return TarotL10n.spreadBanner(type);
  }

  static List<TarotEntrySpreadChoice> offered() {
    final includeSevenCard = FeatureFlagRuntime.isEnabled(
      ProductFeatureFlags.tarot7Card.key,
    );
    return [
      TarotEntrySpreadChoice(
        type: TarotSpreadType.single,
        blurb: TarotPolishCopy.spreadSingleBlurb,
      ),
      TarotEntrySpreadChoice(
        type: TarotSpreadType.threeCard,
        blurb: TarotPolishCopy.spreadThreeBlurb,
      ),
      TarotEntrySpreadChoice(
        type: TarotSpreadType.fiveCard,
        blurb: TarotPolishCopy.spreadFiveBlurb,
      ),
      if (includeSevenCard)
        TarotEntrySpreadChoice(
          type: TarotSpreadType.sevenCard,
          blurb: TarotPolishCopy.spreadSevenBlurb,
        ),
    ];
  }
}
