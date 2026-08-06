/// OR-1000 / OR-1010 — Mystical focal orb for tarot ritual screens.
library;

import 'package:flutter/material.dart';

import '../theme/tarot_tokens.dart';
import 'tarot_crystal_orb.dart';

/// Tarot crystal orb — tarot-specific, not the Home hero orb.
class TarotOrb extends StatelessWidget {
  const TarotOrb({
    super.key,
    this.size = TarotTokens.ritualOrbSize,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return TarotCrystalOrb(size: size);
  }
}
