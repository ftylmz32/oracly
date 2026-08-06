/// OR-300 — Shared render context for orb overlay layers.
library;

import 'package:flutter/material.dart';

import 'orb_constants.dart';

/// Immutable snapshot passed to overlay painters each frame.
@immutable
class OrbRenderContext {
  const OrbRenderContext({
    required this.layoutSize,
    required this.canvasSize,
    required this.innerGlowOpacity,
    required this.ringClockwiseAngle,
    required this.ringCounterClockwiseAngle,
    required this.particlePhase,
  });

  final double layoutSize;
  final double canvasSize;
  final double innerGlowOpacity;
  final double ringClockwiseAngle;
  final double ringCounterClockwiseAngle;
  final double particlePhase;

  Offset get sphereCenter => OrbConstants.sphereCenter(layoutSize);

  double get sphereRadius => OrbConstants.sphereRadius(layoutSize);

  Path sphereClip() {
    return Path()..addOval(
      Rect.fromCircle(center: sphereCenter, radius: sphereRadius),
    );
  }

  Offset normOffset(Offset norm) =>
      Offset(canvasSize * norm.dx, canvasSize * norm.dy);

  double normScalar(double norm) => canvasSize * norm;

  /// Static overlay context (no motion channels).
  factory OrbRenderContext.static({
    required double layoutSize,
    required double canvasSize,
  }) {
    return OrbRenderContext(
      layoutSize: layoutSize,
      canvasSize: canvasSize,
      innerGlowOpacity: 1,
      ringClockwiseAngle: 0,
      ringCounterClockwiseAngle: 0,
      particlePhase: 0,
    );
  }
}
