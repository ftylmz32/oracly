/// Symbolic constellation lookup per tropical sign.
library;

import 'package:flutter/material.dart';

import 'astrology_sign_constellation_model.dart';
import 'astrology_sign_constellations_early.dart';
import 'astrology_sign_constellations_late.dart';

export 'astrology_sign_constellation_model.dart';

abstract final class AstrologySignConstellations {
  AstrologySignConstellations._();

  static AstrologySignConstellation of(String id) {
    return AstrologySignConstellationsEarly.maybe(id) ??
        AstrologySignConstellationsLate.maybe(id) ??
        AstrologySignConstellationsEarly.maybe('aries')!;
  }

  static List<Offset> worldPoints(
    AstrologySignConstellation shape,
    Offset center,
    double radius,
  ) {
    return [
      for (final n in shape.points)
        center + Offset(n.dx * radius, n.dy * radius),
    ];
  }
}
