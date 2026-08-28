/// Shared glass card shell for reference premium widgets.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_glass_card.dart';

class PremiumReferenceCardShell extends StatelessWidget {
  const PremiumReferenceCardShell({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = AppRadius.s20,
    this.onTap,
    this.glowStrength = 1.0,
    this.selected = false,
    this.premium = false,
  });

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double glowStrength;
  final bool selected;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      height: height,
      width: width,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      selected: selected,
      premium: premium,
      glowStrength: glowStrength,
      child: child,
    );
  }
}
