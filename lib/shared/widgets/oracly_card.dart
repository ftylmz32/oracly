/// OR-002.2 — Premium reusable card shell for Oracly.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/premium_cards/premium_card_tokens.dart';
import '../../core/design_system/premium_cards/premium_glass_card.dart';
import '../../core/theme/app_radius.dart';

/// Premium matte card — delegates to [PremiumGlassCard].
class OraclyCard extends StatelessWidget {
  const OraclyCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.showBorder = true,
    this.showShadow = true,
    this.gradient,
    this.backgroundColor,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final bool showShadow;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  PremiumCardGlow get _glow {
    if (!showShadow) return PremiumCardGlow.none;
    return PremiumCardGlow.medium;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius ?? AppRadius.lg,
      glow: _glow,
      gradient: backgroundColor != null ? null : gradient,
      width: width,
      height: height,
      child: child,
    );
  }
}
