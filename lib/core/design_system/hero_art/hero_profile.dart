/// EPIC-024 — Profile hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Celestial identity ring with constellation decoration and gold accents.
class HeroProfile extends StatelessWidget {
  const HeroProfile({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.profile,
      seed: 8,
      showOrbits: false,
      particleDensity: 14,
      artwork: (phase) => ProfileArtworkPainter(phase: phase),
    );
  }
}
