/// EPIC-024 — Astrology hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Golden zodiac wheel with constellations and orbiting stars.
class HeroAstrology extends StatelessWidget {
  const HeroAstrology({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.astrology,
      seed: 4,
      artwork: (phase) => AstrologyArtworkPainter(phase: phase),
    );
  }
}
