/// EPIC-020 — Luxury glass surface — delegates to [PremiumGlassCard].
library;

import 'package:flutter/material.dart';

import '../../core/design_system/premium_cards/premium_card_tokens.dart';
import '../../core/design_system/premium_cards/premium_glass_card.dart';
import '../../core/theme/oracly_visual_rebirth.dart';
import '../../core/widgets/oracly_signature_motifs.dart';

/// Handcrafted premium card — glass, gradient, gold hairline, soft glow.
class OraclyLuxurySurface extends StatelessWidget {
  const OraclyLuxurySurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.tier = OraclyLuxuryTier.primary,
    this.showCorners = true,
    this.showGlow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final OraclyLuxuryTier tier;
  final bool showCorners;
  final bool showGlow;

  PremiumCardTier get _tier => switch (tier) {
        OraclyLuxuryTier.featured => PremiumCardTier.featured,
        OraclyLuxuryTier.primary => PremiumCardTier.standard,
        OraclyLuxuryTier.whisper => PremiumCardTier.whisper,
      };

  PremiumCardGlow get _glow => switch (tier) {
        OraclyLuxuryTier.featured => PremiumCardGlow.hero,
        OraclyLuxuryTier.primary => PremiumCardGlow.large,
        OraclyLuxuryTier.whisper => PremiumCardGlow.small,
      };

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      margin: margin,
      padding: padding ?? OraclyVisualRebirth.screenPadding,
      onTap: onTap,
      borderRadius: borderRadius ?? OraclyVisualRebirth.cardRadius,
      tier: _tier,
      glow: showGlow ? _glow : PremiumCardGlow.none,
      showCorners: showCorners,
      showShimmer: tier == OraclyLuxuryTier.featured,
      child: Stack(
        children: [
          if (showCorners)
            const Positioned.fill(
              child: OraclySignatureCornerOrnaments(
                inset: 10,
                size: 12,
                asPositionedFill: false,
              ),
            ),
          child,
        ],
      ),
    );
  }
}

enum OraclyLuxuryTier {
  featured,
  primary,
  whisper,
}
