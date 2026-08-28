/// Mode + state glow — opacity and warmth only, never a second layout.
library;

import 'package:flutter/material.dart';

import '../../../premium/models/personalization_models.dart';
import 'companion_or_atmosphere_palettes.dart';
import 'companion_or_presence.dart';

class CompanionOrAtmosphere {
  const CompanionOrAtmosphere({
    required this.glow,
    required this.core,
    required this.edge,
    required this.wash,
    required this.blur,
    required this.spread,
    required this.breath,
    required this.glowMin,
    required this.glowSpan,
    required this.showDust,
  });

  final Color glow;
  final Color core;
  final Color edge;
  final double wash;
  final double blur;
  final double spread;
  final Duration breath;
  final double glowMin;
  final double glowSpan;
  final bool showDust;

  static CompanionOrAtmosphere of(
    AiPersonality personality,
    CompanionOrPresence presence,
  ) {
    final mode = OrModePalette.of(personality);
    final state = OrStatePalette.of(presence);
    return CompanionOrAtmosphere(
      glow: Color.lerp(mode.glow, state.tint, state.tintMix) ?? mode.glow,
      core: mode.core,
      edge: Color.lerp(mode.edge, state.edge, state.edgeMix) ?? mode.edge,
      wash: (mode.wash * state.washMul).clamp(0.02, 0.12),
      blur: mode.blur * state.blurMul,
      spread: mode.spread * state.spreadMul,
      breath: state.breath,
      glowMin: state.glowMin,
      glowSpan: state.glowSpan,
      showDust: mode.showDust,
    );
  }
}
