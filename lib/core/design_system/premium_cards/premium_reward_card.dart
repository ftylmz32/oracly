/// EPIC-023 — Premium / reward / gem upsell card.
library;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../premium_button.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';

/// Gold-accent reward card — premium upsell, achievements, gems.
class PremiumRewardCard extends StatelessWidget {
  const PremiumRewardCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.illustration,
    this.onAction,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String actionLabel;
  final Widget? illustration;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      onTap: onTap ?? onAction,
      tier: PremiumCardTier.featured,
      glow: PremiumCardGlow.hero,
      showParticles: true,
      showShimmer: true,
      gradient: AppGradients.premium,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTypography.caption.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.s12),
              Text(
                title,
                style: AppTypography.headingM.copyWith(
                  color: AppColors.goldLight,
                ),
              ),
              SizedBox(height: AppSpacing.s8),
              Text(
                description,
                style: AppTypography.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.s20),
              PremiumButton(
                label: actionLabel,
                onPressed: onAction,
                variant: PremiumButtonVariant.premium,
                size: PremiumButtonSize.small,
              ),
            ],
          ),
          if (illustration != null)
            Positioned(
              right: -AppSpacing.s8,
              bottom: -AppSpacing.s8,
              child: illustration!,
            ),
        ],
      ),
    );
  }
}
