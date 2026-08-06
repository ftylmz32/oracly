/// OR-042 — Spherical canvas helpers (perfect circle geometry only).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Mathematically perfect circular clip path for the crystal boundary.
Path orbV2SpherePath(Offset center, double radius) {
  return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
}

/// Soft volumetric fog blob — always a perfect circle.
void orbV2DrawFogBlob(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required List<Color> colors,
  required List<double> stops,
  Alignment focalAlignment = Alignment.center,
  double blurSigma = 0,
  double gradientRadius = 1.0,
}) {
  final paint = Paint()
    ..shader = RadialGradient(
      center: focalAlignment,
      radius: gradientRadius,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
  if (blurSigma > 0) {
    paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurSigma);
  }
  canvas.drawCircle(center, radius, paint);
}

/// Radial glow confined to a perfect circle — internal light only.
void orbV2DrawRadialGlow(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required List<Color> colors,
  List<double>? stops,
  Alignment centerAlignment = Alignment.center,
  Alignment? focal,
  double focalRadius = 0,
  double gradientRadius = 1.0,
}) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        center: centerAlignment,
        focal: focal ?? centerAlignment,
        focalRadius: focalRadius,
        radius: gradientRadius,
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );
}

/// Radial shader confined to a shell band on a perfect circle.
Paint orbV2ShellBandPaint({
  required Offset center,
  required double radius,
  required List<Color> colors,
  required List<double> stops,
  Alignment bandBias = Alignment.center,
}) {
  return Paint()
    ..shader = RadialGradient(
      center: bandBias,
      radius: 1.0,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
}
