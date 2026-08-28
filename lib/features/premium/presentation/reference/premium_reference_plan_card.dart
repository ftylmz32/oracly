/// Single premium plan card — select quietly; primary CTA lives below.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import 'premium_reference_card_shell.dart';
import 'premium_reference_tokens.dart';

class PremiumReferencePlanCard extends StatelessWidget {
  const PremiumReferencePlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlanModel plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumReferenceCardShell(
      selected: selected,
      borderRadius: PremiumReferenceTokens.planRadius,
      padding: PremiumReferenceTokens.planPadding,
      onTap: onTap,
      glowStrength: selected ? 1.12 : 0.92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SelectionIndicator(selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldLight.withValues(alpha: 0.94),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.kind.periodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            plan.price,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.96)
                  : AppColors.gold.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              letterSpacing: CraftsmanshipRhythm.labelTracking,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: 0.35),
          width: AppBorderWidth.thin,
        ),
        color: selected
            ? AppColors.gold.withValues(alpha: 0.22)
            : AppColors.transparent,
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 13,
              color: AppColors.goldLight.withValues(alpha: 0.94),
            )
          : null,
    );
  }
}
