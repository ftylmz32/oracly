/// EPIC-023 — Large hero card with prominent illustration slot.
library;

import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';

/// Hero card — illustration ~40% height, title stack below or overlaid.
class PremiumHeroCard extends StatelessWidget {
  const PremiumHeroCard({
    super.key,
    this.illustration,
    required this.child,
    this.title,
    this.subtitle,
    this.padding,
    this.margin,
    this.onTap,
    this.height,
    this.showParticles = true,
  });

  final Widget? illustration;
  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? height;
  final bool showParticles;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      padding: padding ?? PremiumCardTokens.paddingHero,
      margin: margin,
      onTap: onTap,
      tier: PremiumCardTier.hero,
      glow: PremiumCardGlow.hero,
      showParticles: showParticles,
      showShimmer: true,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (illustration != null)
            Flexible(
              flex: PremiumCardTokens.illustrationFlex,
              child: Center(child: illustration),
            ),
          if (title != null) ...[
            SizedBox(height: AppSpacing.s12),
            Text(
              title!,
              style: AppTypography.title.copyWith(
                color: AppColors.goldLight.withValues(alpha: 0.94),
              ),
            ),
          ],
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.s4),
            Text(subtitle!, style: AppTypography.caption),
          ],
          if (illustration != null || title != null)
            SizedBox(height: AppSpacing.s12),
          child,
        ],
      ),
    );
  }
}
