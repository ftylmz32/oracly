/// EPIC-024 — Tarot hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Floating premium tarot cards in ancient purple atmosphere.
class HeroTarot extends StatelessWidget {
  const HeroTarot({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.tarot,
      seed: 2,
      particleDensity: 26,
      artwork: (phase) => TarotArtworkPainter(phase: phase),
    );
  }
}
