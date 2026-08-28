/// EPIC-024 — Dream hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Moonlit dream portal with soft clouds and calm motion.
class HeroDream extends StatelessWidget {
  const HeroDream({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.dream,
      seed: 3,
      artwork: (phase) => DreamArtworkPainter(phase: phase),
    );
  }
}
