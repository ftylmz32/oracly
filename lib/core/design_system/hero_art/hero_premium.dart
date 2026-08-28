/// EPIC-024 — Premium membership hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Royal premium hero with floating crown light and luxury glow.
class HeroPremium extends StatelessWidget {
  const HeroPremium({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.premium,
      seed: 7,
      particleDensity: 28,
      artwork: (phase) => PremiumArtworkPainter(phase: phase),
    );
  }
}
