/// OR-1000 — Premium glass card for tarot content.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../theme/tarot_theme.dart';

/// Frosted glass surface — matches Home glassmorphism language.
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
    final card = Container(
      margin: margin,
      decoration: TarotTheme.glassCard(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Padding(
            padding: padding ?? AppSpacing.card,
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return card;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        child: card,
      ),
    );
  }
}
