/// EPIC-023 — Horizontal row card: icon · text · chevron.
library;

import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';
import 'premium_icon_container.dart';

/// Row-layout navigation card — profile, settings, feature lists.
class PremiumHorizontalCard extends StatelessWidget {
  const PremiumHorizontalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconWidget,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      onTap: onTap,
      tier: PremiumCardTier.standard,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s16,
      ),
      margin: EdgeInsets.only(bottom: AppSpacing.s16),
      child: Row(
        children: [
          PremiumIconContainer(
            size: PremiumCardTokens.iconContainerMd,
            child: iconWidget ??
                Icon(icon, color: AppColors.goldLight, size: 24),
          ),
          SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title),
                SizedBox(height: AppSpacing.s4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                AppIcons.chevron,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
        ],
      ),
    );
  }
}
