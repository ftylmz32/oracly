import 'package:flutter/material.dart';

import 'orb_models.dart';
import 'spirit_orb_body_layers.dart';
import 'spirit_orb_effect_layers.dart';

class SpiritOrbPainter extends CustomPainter {
  SpiritOrbPainter({
    required this.sphereRadius,
    required this.coreGlow,
    required this.hazeOpacity,
    required this.ringAngle,
    required this.drift,
    required this.wisps,
    required this.particles,
  });

  final double sphereRadius;
  final double coreGlow;
  final double hazeOpacity;
  final double ringAngle;
  final double drift;
  final List<OrbWisp> wisps;
  final List<OrbParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = sphereRadius;
    SpiritOrbBodyLayers.paint(canvas, c, r, coreGlow: coreGlow, hazeOpacity: hazeOpacity);
    SpiritOrbEffectLayers.paint(
      canvas,
      c,
      r,
      drift: drift,
      ringAngle: ringAngle,
      wisps: wisps,
      particles: particles,
    );
  }

  @override
  bool shouldRepaint(covariant SpiritOrbPainter old) =>
      old.coreGlow != coreGlow ||
      old.hazeOpacity != hazeOpacity ||
      old.ringAngle != ringAngle ||
      old.drift != drift;
}
