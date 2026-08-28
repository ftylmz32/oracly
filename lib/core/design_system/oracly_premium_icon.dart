/// Premium icon language — gold wells matching the approved reference.
library;

import 'package:flutter/material.dart';

import 'app_borders.dart';
import 'app_colors.dart';
import 'app_glows.dart';
import 'app_icons.dart';
import 'app_layout.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Rounded square gold icon well — feature tiles, list rows, reflection cards.
class OraclyPremiumIconWell extends StatelessWidget {
  const OraclyPremiumIconWell({
    super.key,
    required this.child,
    this.size = AppLayout.referenceIconWell,
    this.borderRadius = AppRadius.s24,
    this.glowing = false,
  });

  final Widget child;
  final double size;
  final BorderRadius borderRadius;
  final bool glowing;

  factory OraclyPremiumIconWell.icon({
    Key? key,
    required IconData icon,
    double size = AppLayout.referenceIconWell,
    double iconSize = AppLayout.referenceIconSize,
    BorderRadius borderRadius = AppRadius.s24,
    bool glowing = false,
  }) {
    return OraclyPremiumIconWell(
      key: key,
      size: size,
      borderRadius: borderRadius,
      glowing: glowing,
      child: Icon(
        icon,
        size: iconSize,
        color: AppColors.goldLight.withValues(alpha: 0.92),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: glowing ? 0.20 : 0.14),
            AppColors.surfaceElevated.withValues(alpha: 0.52),
            AppColors.purpleDark.withValues(alpha: 0.38),
          ],
        ),
        border: AppBorders.premiumBox(strength: glowing ? 1.1 : 0.85),
        boxShadow: glowing
            ? AppGlows.small(strength: 1.0)
            : [
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.10),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Center(child: child),
    );
  }
}

/// Circular glowing icon — zodiac tabs, avatar accents, orb wells.
class OraclyPremiumIconCircle extends StatelessWidget {
  const OraclyPremiumIconCircle({
    super.key,
    required this.child,
    this.size = AppSpacing.s40,
    this.selected = false,
  });

  final Widget child;
  final double size;
  final bool selected;

  factory OraclyPremiumIconCircle.icon({
    Key? key,
    required IconData icon,
    double size = AppSpacing.s40,
    double iconSize = AppIconSizes.md,
    bool selected = false,
  }) {
    return OraclyPremiumIconCircle(
      key: key,
      size: size,
      selected: selected,
      child: Icon(
        icon,
        size: iconSize,
        color: AppColors.goldLight.withValues(
          alpha: selected ? 0.96 : 0.82,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  AppColors.gold.withValues(alpha: 0.28),
                  AppColors.purpleDark.withValues(alpha: 0.62),
                ]
              : [
                  AppColors.surfaceElevated.withValues(alpha: 0.72),
                  AppColors.surface.withValues(alpha: 0.55),
                ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: selected ? 0.48 : 0.24),
          width: selected ? AppBorders.thin : AppBorders.hairline,
        ),
        boxShadow: selected
            ? AppGlows.medium(strength: 0.9)
            : AppGlows.small(strength: 0.6),
      ),
      child: Center(child: child),
    );
  }
}
