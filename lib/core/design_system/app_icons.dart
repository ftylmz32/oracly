/// EPIC-021 — Semantic icon registry and sizes.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';

/// Approved icon sizes — tied to spacing scale.
abstract final class AppIconSizes {
  AppIconSizes._();

  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double hero = 48;
}

/// Semantic icons used across Oracly features.
abstract final class AppIcons {
  AppIcons._();

  static const IconData home = Icons.home_rounded;
  static const IconData tarot = Icons.style_rounded;
  static const IconData dream = Icons.nights_stay_rounded;
  static const IconData companion = Icons.auto_awesome_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData settings = Icons.tune_rounded;
  static const IconData premium = Icons.workspace_premium_rounded;
  static const IconData gems = Icons.hexagon_rounded;
  static const IconData memory = Icons.bookmark_rounded;
  static const IconData energy = Icons.bolt_rounded;
  static const IconData moon = Icons.dark_mode_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData chevron = Icons.chevron_right_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData empty = Icons.nights_stay_rounded;
}

/// Thin gold icon with soft glow — ORACLY icon language.
class OraclyIcon extends StatelessWidget {
  const OraclyIcon(
    this.icon, {
    super.key,
    this.size = AppIconSizes.md + 2,
    this.color,
    this.glow = true,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      size: size,
      color: color ?? AppColors.goldLight,
    );

    if (!glow) return child;

    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadows.iconGlow),
      child: child,
    );
  }
}
