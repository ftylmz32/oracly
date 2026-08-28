/// OR-400 / OR-406 / EPIC-024 — Tarot home hero centerpiece.
library;

import 'package:flutter/material.dart';

import '../../../../../core/design_system/hero_art/hero_art.dart';
import '../../../theme/tarot_tokens.dart';

/// Tarot hero artwork — floating cards in ancient atmosphere.
class TarotHomeOrbAmbience extends StatelessWidget {
  const TarotHomeOrbAmbience({
    super.key,
    this.size = TarotTokens.homeOrbSize,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final artSize = size * 1.35;
    return HeroTarot(size: artSize);
  }
}
