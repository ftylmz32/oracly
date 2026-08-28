import 'package:flutter/material.dart';

import '../core/design_system/oracly_chrome.dart';
import '../core/design_system/oracly_glass_card.dart';
import '../core/theme/app_spacing.dart';

/// Canonical ORACLY glass card — delegates to [OraclyGlassCard].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      padding: padding,
      onTap: onTap,
      borderRadius: radius == null
          ? OraclyChrome.cardRadius
          : BorderRadius.circular(radius!),
      elevated: true,
      child: child,
    );
  }
}
