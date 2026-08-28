/// EPIC-020 / EPIC-026 — Unified premium atmosphere for every ORACLY screen.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/cinematic_lighting/cinematic_lighting.dart';
import '../../core/design_system/premium_background.dart' as ds;
import '../../features/home/widgets/home_cinematic_background.dart';
import '../../core/theme/oracly_visual_rebirth.dart';

/// Ambient backdrop — delegates to feature mood while sharing cinematic lighting.
class OraclyRebirthAtmosphere extends StatelessWidget {
  const OraclyRebirthAtmosphere({
    super.key,
    required this.ambience,
  });

  final OraclyAmbience ambience;

  @override
  Widget build(BuildContext context) {
    return switch (ambience) {
      OraclyAmbience.home => const HomeCosmicBackground(),
      OraclyAmbience.tarot => const CinematicLightingStack(
          preset: CinematicLightingPreset.tarot,
        ),
      OraclyAmbience.premium => const CinematicLightingStack(
          preset: CinematicLightingPreset.premium,
        ),
      OraclyAmbience.dream => const CinematicLightingStack(
          preset: CinematicLightingPreset.dream,
        ),
      OraclyAmbience.celestial => const CinematicLightingStack(
          preset: CinematicLightingPreset.celestial,
        ),
      OraclyAmbience.companion => const CinematicLightingStack(
          preset: CinematicLightingPreset.companion,
        ),
      OraclyAmbience.neutral => const ds.PremiumBackground(
          preset: CinematicLightingPreset.neutral,
        ),
    };
  }
}
