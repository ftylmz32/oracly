/// OR-CORE-003 — Gradient tokens and legacy compatibility aliases.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'oracly_brand_signature.dart';

/// Matte gradients for premium surfaces.
abstract final class AppGradients {
  AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment(-0.2, -1),
    end: Alignment(0.3, 1.1),
    colors: [
      AppColors.secondary,
      AppColors.background,
      AppColors.background,
    ],
    stops: [0, 0.45, 1],
  );

  static const LinearGradient matteCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceElevated, AppColors.surface],
  );

  static const LinearGradient matteSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceElevated, AppColors.surface],
  );

  static const LinearGradient goldBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold, AppColors.gold],
  );

  // ── Legacy compatibility aliases ──

  static LinearGradient glass = OraclySignatureChamber.crystalBody();
}
