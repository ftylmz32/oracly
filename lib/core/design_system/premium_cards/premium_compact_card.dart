/// EPIC-023 — Compact tile for horizontal explore rows.
library;

import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../app_typography.dart';
import '../app_colors.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';
import 'premium_icon_container.dart';

/// Small premium tile — icon + title, whisper tier.
class PremiumCompactCard extends StatelessWidget {
  const PremiumCompactCard({
    super.key,
    required this.icon,
    required this.title,
    this.iconWidget,
    this.onTap,
    this.height = 132,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      onTap: onTap,
      tier: PremiumCardTier.whisper,
      height: height,
      padding: PremiumCardTokens.paddingCompact,
      showCorners: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PremiumIconContainer(
            size: PremiumCardTokens.iconContainerSm,
            child: iconWidget ??
                Icon(icon, color: AppColors.gold, size: 22),
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.goldLight.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
