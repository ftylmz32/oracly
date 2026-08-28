/// EPIC-023 — Premium glass card shell.
///
/// Default path uses [OraclyGlassCard]. Advanced shimmer/particle paths keep
/// [PremiumCardShell].
library;

import 'package:flutter/material.dart';

import '../oracly_chrome.dart';
import '../oracly_glass_card.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';

/// Standard glass premium card — use for any custom child content.
class PremiumGlassCard extends StatelessWidget {
  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.glow = PremiumCardGlow.medium,
    this.tier = PremiumCardTier.standard,
    this.showCorners = true,
    this.showShimmer = false,
    this.showParticles = false,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final PremiumCardGlow glow;
  final PremiumCardTier tier;
  final bool showCorners;
  final bool showShimmer;
  final bool showParticles;
  final Gradient? gradient;
  final double? width;
  final double? height;

  bool get _useCanonical =>
      !showShimmer && !showParticles && gradient == null;

  @override
  Widget build(BuildContext context) {
    if (_useCanonical) {
      final card = OraclyGlassCard(
        padding: padding,
        onTap: onTap,
        borderRadius: borderRadius ??
            PremiumCardTokens.radiusForTier(tier),
        premium: tier == PremiumCardTier.featured ||
            tier == PremiumCardTier.hero ||
            glow == PremiumCardGlow.hero ||
            glow == PremiumCardGlow.large,
        elevated: tier != PremiumCardTier.whisper,
        width: width,
        height: height,
        child: child,
      );
      if (margin == null) return card;
      return Padding(padding: margin!, child: card);
    }

    return PremiumCardShell(
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius ?? OraclyChrome.cardRadius,
      glow: glow,
      tier: tier,
      showCorners: showCorners,
      showShimmer: showShimmer,
      showParticles: showParticles,
      gradient: gradient,
      width: width,
      height: height,
      child: child,
    );
  }
}
