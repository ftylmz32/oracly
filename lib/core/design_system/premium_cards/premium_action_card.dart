/// EPIC-023 — CTA-focused action card.
library;

import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import '../premium_button.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';

/// Card with headline copy and a primary [PremiumButton].
class PremiumActionCard extends StatelessWidget {
  const PremiumActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    this.onAction,
    this.icon,
    this.secondary,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      tier: PremiumCardTier.featured,
      glow: PremiumCardGlow.large,
      showShimmer: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(
              color: AppColors.goldLight.withValues(alpha: 0.94),
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.s8),
            Text(subtitle!, style: AppTypography.body),
          ],
          SizedBox(height: AppSpacing.s20),
          PremiumButton(
            label: actionLabel,
            icon: icon,
            onPressed: onAction,
            variant: PremiumButtonVariant.primary,
            isExpanded: true,
          ),
          if (secondary != null) ...[
            SizedBox(height: AppSpacing.s12),
            secondary!,
          ],
        ],
      ),
    );
  }
}
