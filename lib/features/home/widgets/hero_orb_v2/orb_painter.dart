/// OR-046 — CustomPainter engine (reference sphere only).
library;

import 'package:flutter/material.dart';

import 'orb_constants.dart';
import 'orb_layers.dart';

/// Canvas renderer matched to the uploaded reference orb.
class HeroOrbV2Painter extends CustomPainter {
  HeroOrbV2Painter({
    required this.layoutSize,
    required this.breathe,
  });

  final double layoutSize;
  final double breathe;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = OrbV2Constants.sphereRadius(layoutSize);
    final ctx = OrbV2PaintContext(
      canvas: canvas,
      center: center,
      radius: radius,
      breathe: breathe,
      layoutSize: layoutSize,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(_breathingScale());
    canvas.translate(-center.dx, -center.dy);

    OrbV2Layers.paintAll(ctx);

    canvas.restore();
  }

  double _breathingScale() {
    return OrbV2Constants.breatheScaleMin +
        breathe * (OrbV2Constants.breatheScaleMax - OrbV2Constants.breatheScaleMin);
  }

  @override
  bool shouldRepaint(covariant HeroOrbV2Painter oldDelegate) {
    return oldDelegate.layoutSize != layoutSize || oldDelegate.breathe != breathe;
  }
}
