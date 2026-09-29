/// Home ritual lighting — presentation only. Time windows stay in
/// [OraclyRitualAtmosphere].
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/universe/oracly_ritual_time.dart';

/// One period's Home atmosphere. Values are intentionally far apart.
@immutable
class HomeRitualVisual {
  const HomeRitualVisual({
    required this.time,
    required this.heroPlateOpacity,
    required this.luminanceAlpha,
    required this.warmAlpha,
    required this.coolAlpha,
    required this.goldAlpha,
    required this.violetAlpha,
    required this.roseAlpha,
    required this.nightDepthAlpha,
    required this.vignetteAlpha,
    required this.starBias,
    required this.pageWashAlpha,
    required this.skyTop,
    required this.skyBottom,
    required this.textScrim,
    required this.lightCenter,
  });

  final OraclyRitualTime time;

  /// How strongly [AppAssets.homeHeroMoon] reads. Night is full strength.
  final double heroPlateOpacity;
  final double luminanceAlpha;
  final double warmAlpha;
  final double coolAlpha;
  final double goldAlpha;
  final double violetAlpha;
  final double roseAlpha;
  final double nightDepthAlpha;
  final double vignetteAlpha;

  /// 1 keeps the celestial field open. Daytime lowers it.
  final double starBias;

  /// Strength of the Home-only wash over the shared cosmic base.
  final double pageWashAlpha;
  final Color skyTop;
  final Color skyBottom;
  final Color textScrim;
  final Alignment lightCenter;
}

/// Canonical Home profiles. Do not recompute ritual hours here.
abstract final class HomeRitualVisuals {
  HomeRitualVisuals._();

  static HomeRitualVisual of(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => morning,
        OraclyRitualTime.afternoon => afternoon,
        OraclyRitualTime.evening => evening,
        OraclyRitualTime.night => night,
      };

  /// Mystical dawn — moon is texture, not the scene.
  static const morning = HomeRitualVisual(
    time: OraclyRitualTime.morning,
    heroPlateOpacity: 0.26,
    luminanceAlpha: 0.58,
    warmAlpha: 0.50,
    coolAlpha: 0.08,
    goldAlpha: 0.36,
    violetAlpha: 0.10,
    roseAlpha: 0.42,
    nightDepthAlpha: 0.18,
    vignetteAlpha: 0.32,
    starBias: 0.16,
    pageWashAlpha: 0.62,
    skyTop: Color(0xFF5C4034),
    skyBottom: Color(0xFF241610),
    textScrim: Color(0xFF140E0C),
    lightCenter: Alignment(0.0, -0.94),
  );

  /// Clear antique-gold daylight inside the same dark sanctuary.
  static const afternoon = HomeRitualVisual(
    time: OraclyRitualTime.afternoon,
    heroPlateOpacity: 0.12,
    luminanceAlpha: 0.46,
    warmAlpha: 0.30,
    coolAlpha: 0.30,
    goldAlpha: 0.32,
    violetAlpha: 0.22,
    roseAlpha: 0.06,
    nightDepthAlpha: 0.08,
    vignetteAlpha: 0.24,
    starBias: 0.08,
    pageWashAlpha: 0.74,
    skyTop: Color(0xFF3A4562),
    skyBottom: Color(0xFF121820),
    textScrim: Color(0xFF10141C),
    lightCenter: Alignment(0.0, -0.28),
  );

  /// Twilight — moon returns, amber and magenta take the sky.
  static const evening = HomeRitualVisual(
    time: OraclyRitualTime.evening,
    heroPlateOpacity: 0.64,
    luminanceAlpha: 0.28,
    warmAlpha: 0.40,
    coolAlpha: 0.16,
    goldAlpha: 0.44,
    violetAlpha: 0.40,
    roseAlpha: 0.32,
    nightDepthAlpha: 0.46,
    vignetteAlpha: 0.50,
    starBias: 0.55,
    pageWashAlpha: 0.50,
    skyTop: Color(0xFF6A3850),
    skyBottom: Color(0xFF1A1018),
    textScrim: Color(0xFF140C12),
    lightCenter: Alignment(0.42, -0.18),
  );

  /// Current observatory. Moon plate leads; wash stays out of the way.
  static const night = HomeRitualVisual(
    time: OraclyRitualTime.night,
    heroPlateOpacity: 1,
    luminanceAlpha: 0.10,
    warmAlpha: 0.06,
    coolAlpha: 0.40,
    goldAlpha: 0.12,
    violetAlpha: 0.46,
    roseAlpha: 0.04,
    nightDepthAlpha: 0.82,
    vignetteAlpha: 0.62,
    starBias: 1,
    pageWashAlpha: 0.14,
    skyTop: AppColors.chamberViolet,
    skyBottom: AppColors.nearBlack,
    textScrim: AppColors.nearBlack,
    lightCenter: Alignment(0.55, -0.22),
  );
}
