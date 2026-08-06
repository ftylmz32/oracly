/// OR-1000 — Cinematic tarot background layer.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_decorations.dart';
import '../widgets/tarot_cinematic_background.dart';
import 'tarot_particle_layer.dart';

/// Full-screen mystical backdrop for all Tarot screens.
class TarotBackground extends StatelessWidget {
  const TarotBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  final Widget child;
  final bool showParticles;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.background),
          child: SizedBox.expand(),
        ),
        TarotCinematicBackground(child: const SizedBox.shrink()),
        if (showParticles) const TarotParticleLayer(),
        if (showParticles) const TarotGlowLayer(),
        child,
      ],
    );
  }
}
