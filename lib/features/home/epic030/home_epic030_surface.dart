/// EPIC-030 — Approved glass card surface for Home sections.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_pressable.dart';

/// Dark glass card — gold hairline, dual shadow, optional premium gradient.
class HomeEpic030Surface extends StatelessWidget {
  const HomeEpic030Surface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.s20,
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
    final borderAlpha = premium ? 0.30 : 0.24;
    final goldGlowAlpha = premium ? 0.12 : 0.08;

    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: premium
              ? [
                  AppColors.surfaceElevated.withValues(alpha: 0.78),
                  AppColors.purple.withValues(alpha: 0.32),
                  AppColors.purpleDark.withValues(alpha: 0.48),
                ]
              : [
                  AppColors.surfaceElevated.withValues(alpha: 0.76),
                  AppColors.surface.withValues(alpha: 0.60),
                  AppColors.purpleDark.withValues(alpha: 0.44),
                ],
          stops: premium ? const [0.0, 0.45, 1.0] : const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: borderAlpha),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.38),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: goldGlowAlpha),
            blurRadius: 22,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.14),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );

    final sized = SizedBox(width: width, height: height, child: body);
    if (onTap == null) return sized;

    return OraclyPressable(
      onTap: onTap,
      borderRadius: borderRadius,
      glowShift: true,
      child: sized,
    );
  }
}
