/// OR-1000 — Premium glass card for tarot content.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/design_system/oracly_glass_card.dart';
import '../../../core/theme/app_spacing.dart';

/// Frosted glass surface — unified [OraclyGlassCard] system.
class TarotGlassCard extends StatelessWidget {
  const TarotGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = OraclyGlassCard(
      padding: padding ?? AppSpacing.card,
      onTap: onTap,
      borderRadius: OraclyChrome.heroRadius,
      elevated: true,
      child: child,
    );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
