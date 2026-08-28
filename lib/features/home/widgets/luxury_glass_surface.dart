import 'package:flutter/material.dart';

import '../../../core/design_system/premium_cards/premium_card_tokens.dart';
import '../../../core/design_system/premium_cards/premium_glass_card.dart';

/// Premium glass surface — delegates to [PremiumGlassCard].
class LuxuryGlassSurface extends StatelessWidget {
  const LuxuryGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 32,
    this.height,
    this.elevated = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double? height;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: padding,
      onTap: onTap,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      tier: elevated ? PremiumCardTier.featured : PremiumCardTier.standard,
      glow: elevated ? PremiumCardGlow.large : PremiumCardGlow.medium,
      child: child,
    );
  }
}
