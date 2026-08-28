/// Soft velvet oval under the fan — table cloth, not a UI panel.
library;

import 'package:flutter/material.dart';

import '../deck/tarot_deck_table_atmosphere.dart';

class CardSelectionVelvet extends StatelessWidget {
  const CardSelectionVelvet({super.key, this.intensity = 1});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return TarotDeckTableAtmosphere(
      width: 340,
      height: 138,
      intensity: intensity,
      candleBias: const Alignment(-0.42, -0.48),
    );
  }
}
