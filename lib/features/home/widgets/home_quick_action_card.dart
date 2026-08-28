/// EPIC-022 / EPIC-023 — Quick action tile — delegates to [PremiumFeatureCard].
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/premium_cards/premium_card_tokens.dart';
import '../../../core/design_system/premium_cards/premium_feature_card.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../theme/home_composition.dart';

/// Large premium card for the 2-column quick actions grid.
class HomeQuickActionCard extends StatelessWidget {
  const HomeQuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconAsset,
    this.onTap,
  });

  final IconData icon;
  final String? iconAsset;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      tier: PremiumCardTier.featured,
      height: HomeComposition.quickActionCardHeight,
      iconWidget: iconAsset != null
          ? OraclyAssetImage(
              assetPath: iconAsset!,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              fallback: Icon(icon, size: 26),
            )
          : null,
    );
  }
}
