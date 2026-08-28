/// OR-050 — Premium glass card for daily energy sections.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/premium_cards/premium_card_tokens.dart';
import '../../../core/design_system/premium_cards/premium_glass_card.dart';
import '../../../core/design_system/premium_cards/premium_icon_container.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Frosted glass surface — unified premium card system.
class DailyEnergyGlassCard extends StatelessWidget {
  const DailyEnergyGlassCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.padding,
    this.margin,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      margin: margin,
      padding: padding ?? AppSpacing.card,
      tier: PremiumCardTier.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppSpacing.s16,
                    color: AppColors.goldLight,
                  ),
                  SizedBox(width: AppSpacing.s8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Compact insight tile inside the four-category grid.
class DailyEnergyInsightTile extends StatelessWidget {
  const DailyEnergyInsightTile({
    super.key,
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: EdgeInsets.all(AppSpacing.insetCard),
      tier: PremiumCardTier.whisper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumIconContainer(
                size: PremiumCardTokens.iconContainerSm,
                child: Icon(icon, size: AppSpacing.s16, color: AppColors.gold),
              ),
              SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Lucky attribute chip — number, color, or crystal.
class DailyEnergyLuckyChip extends StatelessWidget {
  const DailyEnergyLuckyChip({
    super.key,
    required this.label,
    required this.value,
    this.swatch,
  });

  final String label;
  final String value;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PremiumGlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s16,
        ),
        tier: PremiumCardTier.whisper,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.s8),
            if (swatch != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatch,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                    width: AppBorderWidth.hairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: swatch!.withValues(alpha: 0.45),
                      blurRadius: AppSpacing.s8,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: AppSpacing.s24,
                  height: AppSpacing.s24,
                ),
              ),
              SizedBox(height: AppSpacing.s4),
            ],
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
