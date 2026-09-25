/// Full-screen mystical table environment — continuous across phases.
///
/// Phase 7B: canonical LIVE Tarot table background. Static layers only —
/// celestial [CustomPainter.shouldRepaint] stays false. No ambient loop.
library;

import 'package:flutter/material.dart';

import '../../theme/tarot_tokens.dart';
import 'tarot_table_background_layers.dart';

class TarotTableBackground extends StatelessWidget {
  const TarotTableBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: TarotTokens.tableVoid),
        TarotTableNavyWash(),
        TarotTableCelestialRing(),
        TarotTableCandleSpill(),
        TarotTableVioletBloom(),
        TarotTableVignette(),
      ],
    );
  }
}
