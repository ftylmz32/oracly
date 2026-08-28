/// EPIC-024 — Birth chart hero artwork.
library;

import 'package:flutter/material.dart';

import 'hero_art_canvas.dart';
import 'hero_art_painters.dart';
import 'hero_art_tokens.dart';

/// Premium natal wheel with constellation overlay and celestial lines.
class HeroBirthChart extends StatelessWidget {
  const HeroBirthChart({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HeroArtCanvas(
      size: size,
      theme: HeroArtTheme.birthChart,
      seed: 5,
      artwork: (phase) => BirthChartArtworkPainter(phase: phase),
    );
  }
}
