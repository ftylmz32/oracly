/// TAROT V2 — gem cost shown before a paid reading starts.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_gem_facet.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/tarot_polish_copy.dart';

class TarotEpic031CostHint extends StatelessWidget {
  const TarotEpic031CostHint({super.key, required this.cost});

  final int cost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const OraclyGemFacet(size: 14, glow: 0.88),
          const SizedBox(width: 6),
          Text(
            TarotPolishCopy.gemCost(cost),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: OraclyChrome.goldLight.withValues(alpha: 0.88),
              letterSpacing: 0.35,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
