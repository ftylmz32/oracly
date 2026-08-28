/// EPIC-023 — Feature launcher card: icon · title · subtitle.
library;

import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';
import 'premium_icon_container.dart';

/// Vertical feature card for grids — equal height, premium icon orb.
class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconWidget,
    this.onTap,
    this.tier = PremiumCardTier.standard,
    this.compact = false,
    this.height,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final PremiumCardTier tier;
  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact
        ? PremiumCardTokens.iconContainerSm
        : PremiumCardTokens.iconContainerMd;

    return PremiumCardShell(
      onTap: onTap,
      tier: tier,
      height: height,
      padding: compact
          ? PremiumCardTokens.paddingCompact
          : PremiumCardTokens.paddingStandard,
      showParticles: tier != PremiumCardTier.whisper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumIconContainer(
            size: iconSize,
            child: iconWidget ??
                Icon(icon, color: AppColors.goldLight, size: iconSize * 0.48),
          ),
          SizedBox(
            height: compact
                ? AppSpacing.s12
                : (height != null ? AppSpacing.s12 : AppSpacing.s16),
          ),
          if (height != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (compact ? AppTypography.caption : AppTypography.title)
                        .copyWith(
                      color: AppColors.goldLight.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.88),
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (compact ? AppTypography.caption : AppTypography.title).copyWith(
                color: AppColors.goldLight.withValues(alpha: 0.94),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.s4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.88),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
