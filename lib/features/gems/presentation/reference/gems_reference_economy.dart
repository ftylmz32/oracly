/// Honest economy rows — starter, daily, tarot. No fake prices.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_gem_facet.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../copy/gems_copy.dart';
import '../../economy/gem_economy.dart';
import 'gems_reference_tokens.dart';

class GemsEconomySection extends StatelessWidget {
  const GemsEconomySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          GemsCopy.economyTitle,
          textAlign: TextAlign.center,
          style: OraclyChrome.sectionLabel(size: 12).copyWith(
            color: OraclyChrome.goldPrimary.withValues(alpha: 0.94),
            letterSpacing: CraftsmanshipRhythm.sectionLabelTracking,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: GemsReferenceTokens.sectionLabelToContent),
        GemsEconomyRow(
          value: '+${GemEconomy.starterGrant}',
          label: GemsCopy.reasonStarter,
          chip: GemsCopy.starterChip,
        ),
        SizedBox(height: GemsReferenceTokens.rowGap),
        GemsEconomyRow(
          value: '+${GemEconomy.dailyReward}${GemsCopy.dailyValueSuffix}',
          label: GemsCopy.reasonDailyReward,
          chip: GemsCopy.dailyChip,
          glow: 1.12,
        ),
        SizedBox(height: GemsReferenceTokens.rowGap),
        GemsEconomyRow(
          value: '-${GemEconomy.tarotReading}',
          label: GemsCopy.tarotLabel,
          chip: GemsCopy.tarotChip,
          spend: true,
        ),
      ],
    );
  }
}

class GemsEconomyRow extends StatelessWidget {
  const GemsEconomyRow({
    super.key,
    required this.value,
    required this.label,
    required this.chip,
    this.glow = 1.0,
    this.spend = false,
  });

  final String value;
  final String label;
  final String chip;
  final double glow;
  final bool spend;

  @override
  Widget build(BuildContext context) {
    final valueColor = spend
        ? OraclyChrome.cream.withValues(alpha: 0.82)
        : OraclyChrome.goldLight.withValues(alpha: 0.96);
    return OraclyGlassCard(
      borderRadius: GemsReferenceTokens.cardRadius,
      padding: GemsReferenceTokens.rowPadding,
      premium: true,
      glowStrength: spend ? 0.94 : 1.10,
      child: Row(
        children: [
          OraclyGemFacet(size: 30, glow: glow, dimmed: spend),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    height: 1.15,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: GemsReferenceTokens.chipRadius,
              color: OraclyChrome.midnight.withValues(alpha: 0.35),
              border: Border.all(
                color: OraclyChrome.gold.withValues(alpha: spend ? 0.32 : 0.48),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                chip,
                style: AppTextStyles.caption.copyWith(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
