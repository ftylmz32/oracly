/// OR-002.2 — Premium reusable card shell for Oracly.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'oracly_pressable.dart';

/// Premium matte card used across Tarot, AI, profile, and shop surfaces.
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

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lg;
    final decoration = _decorationFor(
      radius: radius,
      showBorder: showBorder,
      showShadow: showShadow,
      gradient: gradient,
      backgroundColor: backgroundColor,
    );
    final content = Padding(
      padding: padding ?? AppSpacing.card,
      child: child,
    );

    final card = Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.zero,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: content,
    );

    if (onTap == null) return card;

    return OraclyPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  static BoxDecoration _decorationFor({
    required BorderRadius radius,
    required bool showBorder,
    required bool showShadow,
    Gradient? gradient,
    Color? backgroundColor,
  }) {
    final premium = AppDecorations.premiumCard(borderRadius: radius);

    return premium.copyWith(
      color: backgroundColor,
      gradient: backgroundColor != null
          ? null
          : gradient ?? premium.gradient,
      border: showBorder ? premium.border : null,
      boxShadow: showShadow ? premium.boxShadow : null,
    );
  }
}
