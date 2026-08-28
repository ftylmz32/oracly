/// Compact cards for Günlük Ödüller — gift card · claim chrome.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/daily_rewards_copy.dart';
import 'daily_rewards_reference_tokens.dart';

class DailyRewardsTodayCard extends StatelessWidget {
  const DailyRewardsTodayCard({
    super.key,
    required this.claimed,
    required this.amount,
    this.onClaim,
    this.busy = false,
  });

  final bool claimed;
  final int amount;
  final VoidCallback? onClaim;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      borderRadius: DailyRewardsReferenceTokens.cardRadius,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      premium: true,
      glowStrength: 1.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DailyRewardsCopy.giftTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: OraclyChrome.goldLight.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 48,
                color: OraclyChrome.violet.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$amount',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: OraclyChrome.goldLight.withValues(alpha: 0.96),
                      ),
                    ),
                    Text(
                      DailyRewardsCopy.gemUnit,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!claimed)
                OraclyGoldButton(
                  label: DailyRewardsCopy.claimShort,
                  onPressed: busy ? null : onClaim,
                ),
            ],
          ),
          if (claimed) ...[
            const SizedBox(height: 10),
            Text(
              DailyRewardsCopy.claimedLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
