/// OR-046 — Reference orb geometry (sphere only, no invented extras).
library;

import 'package:flutter/material.dart';

import 'orb_physics.dart';

/// Layout derived from the uploaded reference silhouette.
abstract final class OrbV2Constants {
  OrbV2Constants._();

  static const double sizeMultiplier = 1.55;

  static const Duration breatheDuration = Duration(milliseconds: 7000);

  static const double breatheScaleMin = 0.985;
  static const double breatheScaleMax = 1.015;

  static double renderSize(double size) => size * sizeMultiplier;

  static double canvasSize(double size) => renderSize(size);

  /// Sphere fills the canvas — reference is a single isolated orb.
  static double sphereDiameter(double size) => renderSize(size) * 0.94;

  static double sphereRadius(double size) => sphereDiameter(size) / 2;
}

/// Shared paint context passed between layer painters.
@immutable
class OrbV2PaintContext {
  const OrbV2PaintContext({
    required this.canvas,
    required this.center,
    required this.radius,
    required this.breathe,
    required this.layoutSize,
  });

  final Canvas canvas;
  final Offset center;
  final double radius;
  final double breathe;
  final double layoutSize;

  double get diameter => radius * 2;

  Path sphereClip() => orbV2SpherePath(center, radius);
}

/// Radial shader helper aligned to a canvas circle.
Paint orbV2RadialPaint({
  required Offset center,
  required double radius,
  required List<Color> colors,
  List<double>? stops,
  Alignment centerAlignment = Alignment.center,
  Alignment? focal,
  double focalRadius = 0.0,
  double gradientRadius = 1.0,
}) {
  return Paint()
    ..shader = RadialGradient(
      center: centerAlignment,
      focal: focal ?? centerAlignment,
      focalRadius: focalRadius,
      radius: gradientRadius,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
}
