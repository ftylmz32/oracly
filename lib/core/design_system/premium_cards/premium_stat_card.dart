/// EPIC-023 — Stat / metric display card.
library;

import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';

/// Centered value + label — energy, streaks, counts.
class PremiumStatCard extends StatelessWidget {
  const PremiumStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      onTap: onTap,
      tier: PremiumCardTier.whisper,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.goldLight, size: 20),
            SizedBox(height: AppSpacing.s8),
          ],
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.headingM.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          SizedBox(height: AppSpacing.s4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
