/// OR-046 — Reference sacred-geometry lattice in the core.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../orb_constants.dart';

/// Gold wireframe visible in the reference core.
abstract final class OrbV2LayerLattice {
  OrbV2LayerLattice._();

  static const List<double> _hexSteps = [
    0.0,
    pi / 3,
    2 * pi / 3,
    pi,
    4 * pi / 3,
    5 * pi / 3,
  ];

  static void paint(OrbV2PaintContext ctx) {
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.sphereClip());

    final r = ctx.radius * 0.36;
    final nodes = _hexSteps
        .map((a) => ctx.center + Offset(cos(a) * r, sin(a) * r))
        .toList(growable: false);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ctx.radius * 0.0032
      ..color = AppColors.goldLight.withValues(alpha: 0.72);

    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ctx.radius * 0.0028
      ..color = AppColors.gold.withValues(alpha: 0.42);

    for (var i = 0; i < nodes.length; i++) {
      ctx.canvas.drawLine(nodes[i], nodes[(i + 1) % nodes.length], rimPaint);
      ctx.canvas.drawLine(ctx.center, nodes[i], spokePaint);
    }

    for (final node in nodes) {
      ctx.canvas.drawCircle(
        node,
        ctx.radius * 0.009,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.88),
      );
    }

    ctx.canvas.drawCircle(
      ctx.center,
      ctx.radius * 0.010,
      Paint()..color = AppColors.goldLight,
    );

    ctx.canvas.restore();
  }
}
