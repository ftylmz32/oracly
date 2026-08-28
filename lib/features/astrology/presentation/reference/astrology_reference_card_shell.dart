/// Shared glass card shell for reference astrology widgets.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_glass_card.dart';

class AstrologyReferenceCardShell extends StatelessWidget {
  const AstrologyReferenceCardShell({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = AppRadius.s24,
    this.onTap,
    this.glowStrength = 1.0,
    this.premium = false,
  });

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double glowStrength;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      height: height,
      width: width,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      glowStrength: glowStrength,
      premium: premium,
      child: child,
    );
  }
}
