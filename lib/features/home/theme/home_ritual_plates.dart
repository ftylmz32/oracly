/// One photographic plate per ritual window. Hours stay in
/// [OraclyRitualAtmosphere].
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/universe/oracly_ritual_time.dart';

abstract final class HomeRitualPlates {
  HomeRitualPlates._();

  static String of(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => AppAssets.homeHeroMorning,
        OraclyRitualTime.afternoon => AppAssets.homeHeroNoon,
        OraclyRitualTime.evening => AppAssets.homeHeroEvening,
        OraclyRitualTime.night => AppAssets.homeHeroNight,
      };

  /// Short trace card. Night keeps the crescent; day keeps the horizon.
  static Alignment focus(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => const Alignment(0.08, -0.02),
        OraclyRitualTime.afternoon => const Alignment(0.18, 0.22),
        OraclyRitualTime.evening => const Alignment(0.10, 0.12),
        OraclyRitualTime.night => const Alignment(-0.06, -0.78),
      };
}
