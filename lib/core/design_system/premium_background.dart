/// EPIC-021 / EPIC-026 — Reusable animated cinematic background.
library;

import 'package:flutter/material.dart';

import 'cinematic_lighting/cinematic_lighting.dart';
import 'oracly_cosmic_background.dart';

/// Five-layer cinematic lighting — delegates to [OraclyCosmicBackground].
class PremiumBackground extends StatelessWidget {
  const PremiumBackground({
    super.key,
    this.child,
    this.preset = CinematicLightingPreset.neutral,
    this.showNebula = true,
    this.showStars = true,
    this.showDust = true,
    this.showVignette = true,
  });

  final Widget? child;
  final CinematicLightingPreset preset;

  /// Legacy flags — map to cosmic stack layers.
  final bool showNebula;
  final bool showStars;
  final bool showDust;
  final bool showVignette;

  @override
  Widget build(BuildContext context) {
    return OraclyCosmicBackground(
      showNebula: showNebula,
      showStars: showStars,
      showDust: showDust,
      showVignette: showVignette,
      child: child,
    );
  }
}
