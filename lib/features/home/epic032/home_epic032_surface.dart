/// EPIC-032 — Approved glass card surface (delegates to canonical glass).
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/oracly_glass_card.dart';

/// Dark glass card — delegates to [OraclyGlassCard] for unified premium depth.
class HomeEpic032Surface extends StatelessWidget {
  const HomeEpic032Surface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.s24,
    this.premium = false,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final bool premium;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
      premium: premium,
      glowStrength: premium ? 1.15 : 1.0,
      onTap: onTap,
      child: child,
    );
  }
}
