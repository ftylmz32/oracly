/// EPIC-024 — Home crystal orb hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Large crystal orb — internal energy, aura, and breathing motion.
class HeroOrb extends StatelessWidget {
  const HeroOrb({
    super.key,
    this.size = 220,
    this.onTap,
  });

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final art = HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.orb,
      seed: 1,
      artwork: (phase) => OrbArtworkPainter(phase: phase),
    );

    if (onTap == null) return art;

    return GestureDetector(onTap: onTap, child: art);
  }
}
