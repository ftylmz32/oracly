/// EPIC-024 — AI companion hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Sacred crystal chamber with glowing orb and floating runes.
class HeroAI extends StatelessWidget {
  const HeroAI({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.ai,
      seed: 6,
      particleDensity: 16,
      artwork: (phase) => AiArtworkPainter(phase: phase),
    );
  }
}
