/// One quiet gem line. The crystal stays V2.1; the wallet stays elsewhere.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_gem_icon.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../gems/copy/gems_copy.dart';
import '../../../gems/economy/gem_economy.dart';
import '../../../tarot/economy/tarot_economy.dart';

class PremiumReferenceGemNote extends StatelessWidget {
  const PremiumReferenceGemNote({super.key});

  @override
  Widget build(BuildContext context) {
    final cost = TarotEconomy.readingCost;
    if (cost <= 0) return const SizedBox.shrink();
    return OraclyPressable(
      onTap: () => OraclyNavigationService.openGems(context),
      child: Semantics(
        button: true,
        label: GemsCopy.openGemsAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const OraclyGemIcon(size: 48, glow: 0.8),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  PremiumCopy.gemNote(GemEconomy.tarotReading),
                  softWrap: true,
                  style: ReadingTypography.secondary(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
