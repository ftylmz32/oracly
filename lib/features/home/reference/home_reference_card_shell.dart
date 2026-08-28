/// Shared glass card shell for reference home widgets.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/oracly_glass_card.dart';

/// Dark glass surface with gold hairline — reference card chrome.
class HomeReferenceCardShell extends StatelessWidget {
  const HomeReferenceCardShell({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = AppRadius.s24,
    this.onTap,
    this.premium = false,
    this.elevated = false,
    this.glowStrength = 1.0,
  });

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool premium;
  final bool elevated;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      height: height,
      width: width,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      premium: premium,
      elevated: elevated,
      glowStrength: glowStrength,
      child: child,
    );
  }
}
