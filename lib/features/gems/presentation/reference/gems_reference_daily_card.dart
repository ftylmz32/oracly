/// Daily reward entry + honesty footnote for Mücevherler.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_gem_facet.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/gems_copy.dart';
import 'gems_reference_tokens.dart';

class GemsDailyRewardCard extends StatelessWidget {
  const GemsDailyRewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: GemsCopy.dailyRewardLink,
      child: OraclyGlassCard(
        borderRadius: GemsReferenceTokens.cardRadius,
        padding: GemsReferenceTokens.rowPadding,
        premium: true,
        glowStrength: 1.12,
        onTap: () => OraclyNavigationService.openDailyRewards(context),
        child: Row(
          children: [
            const OraclyGemFacet(size: 30, glow: 1.08),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GemsCopy.dailyRewardLink,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    GemsCopy.dailyRewardHint,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: OraclyChrome.goldLight.withValues(alpha: 0.82),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class GemsHonestyNote extends StatelessWidget {
  const GemsHonestyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      GemsCopy.shopHonesty,
      textAlign: TextAlign.center,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.68),
        height: 1.35,
      ),
    );
  }
}
