/// EPIC-023 — Informational text card.
library;

import 'package:flutter/material.dart';

import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import 'premium_card_tokens.dart';
import 'premium_glass_card.dart';
import 'premium_icon_container.dart';

/// Title + body + optional badge — memory, insights, notes.
class PremiumInfoCard extends StatelessWidget {
  const PremiumInfoCard({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.iconWidget,
    this.badge,
    this.onTap,
  });

  final String title;
  final String body;
  final IconData? icon;
  final Widget? iconWidget;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null || iconWidget != null)
                PremiumIconContainer(
                  size: PremiumCardTokens.iconContainerSm,
                  child: iconWidget ??
                      Icon(icon, color: AppColors.goldLight, size: 20),
                ),
              if (icon != null || iconWidget != null)
                SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title,
                ),
              ),
              if (badge != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.round,
                    color: AppColors.surface.withValues(alpha: 0.45),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s4,
                    ),
                    child: Text(badge!, style: AppTypography.caption),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          Text(
            body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}
