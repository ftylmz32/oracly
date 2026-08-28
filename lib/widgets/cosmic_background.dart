import 'package:flutter/material.dart';

import '../core/design_system/oracly_cosmic_background.dart';

/// Legacy wrapper — use [OraclyCosmicBackground] or [OraclyScaffold] directly.
class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showHeroGlow = false,
  });

  final Widget child;
  final bool showParticles;
  final bool showHeroGlow;

  @override
  Widget build(BuildContext context) {
    return OraclyCosmicBackground(
      showDust: showParticles,
      heroGlow: showHeroGlow,
      child: child,
    );
  }
}
