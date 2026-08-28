/// OR-006 / EPIC-023 — Feature card — delegates to premium card system.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/premium_cards/premium_card_tokens.dart';
import '../../../core/design_system/premium_cards/premium_compact_card.dart';
import '../../../core/design_system/premium_cards/premium_feature_card.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';

/// Dark glass feature tile — unified [PremiumFeatureCard] / [PremiumCompactCard].
class MysticFeatureCard extends StatelessWidget {
  const MysticFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.iconAsset,
    this.onTap,
    this.compact = true,
    this.tier = HomeVisualTier.primary,
    this.focusZone,
  });

  final IconData icon;
  final String? iconAsset;
  final String title;
  final VoidCallback? onTap;
  final bool compact;
  final HomeVisualTier tier;
  final HomeFocusZone? focusZone;

  PremiumCardTier get _cardTier => switch (tier) {
        HomeVisualTier.featured => PremiumCardTier.featured,
        HomeVisualTier.primary => PremiumCardTier.standard,
        HomeVisualTier.whisper => PremiumCardTier.whisper,
      };

  Widget? get _iconWidget {
    if (iconAsset == null) return null;
    return OraclyAssetImage(
      assetPath: iconAsset!,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      fallback: Icon(icon, color: Colors.amber, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact || tier == HomeVisualTier.whisper) {
      return PremiumCompactCard(
        icon: icon,
        iconWidget: _iconWidget,
        title: title,
        onTap: onTap,
        height: HomeComposition.exploreRowHeight,
      );
    }

    return PremiumFeatureCard(
      icon: icon,
      iconWidget: _iconWidget,
      title: title,
      onTap: onTap,
      tier: _cardTier,
      compact: false,
    );
  }
}
