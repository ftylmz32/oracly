/// Shared glass card shell for reference settings widgets.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/oracly_glass_card.dart';

class SettingsReferenceCardShell extends StatelessWidget {
  const SettingsReferenceCardShell({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.s20,
    this.onTap,
    this.selected = false,
    this.glowStrength = 1.0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool selected;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      selected: selected,
      glowStrength: glowStrength,
      child: child,
    );
  }
}
