/// Symbolic constellation stars + edges (Aries–Virgo).
/// Artwork only — not astronomical coordinates.
library;

import 'package:flutter/material.dart';

import 'astrology_sign_constellation_model.dart';

abstract final class AstrologySignConstellationsEarly {
  AstrologySignConstellationsEarly._();

  static AstrologySignConstellation? maybe(String id) {
    return switch (id) {
      'taurus' => const AstrologySignConstellation(
          points: [
            Offset(-0.62, 0.18),
            Offset(-0.28, -0.42),
            Offset(0.08, -0.52),
            Offset(0.42, -0.28),
            Offset(0.62, 0.22),
            Offset(0.0, 0.48),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (3, 5)],
        ),
      'gemini' => const AstrologySignConstellation(
          points: [
            Offset(-0.42, -0.55),
            Offset(-0.42, 0.05),
            Offset(-0.42, 0.52),
            Offset(0.42, -0.55),
            Offset(0.42, 0.05),
            Offset(0.42, 0.52),
          ],
          edges: [(0, 1), (1, 2), (3, 4), (4, 5), (0, 3), (2, 5)],
        ),
      'cancer' => const AstrologySignConstellation(
          points: [
            Offset(-0.38, -0.22),
            Offset(0.38, -0.22),
            Offset(-0.58, 0.32),
            Offset(0.58, 0.32),
            Offset(0.0, 0.58),
            Offset(0.0, -0.52),
          ],
          edges: [(0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (0, 5), (1, 5)],
        ),
      'leo' => const AstrologySignConstellation(
          points: [
            Offset(-0.58, 0.22),
            Offset(-0.22, -0.48),
            Offset(0.22, -0.52),
            Offset(0.55, -0.12),
            Offset(0.42, 0.42),
            Offset(-0.05, 0.55),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)],
        ),
      'virgo' => const AstrologySignConstellation(
          points: [
            Offset(-0.55, 0.42),
            Offset(-0.28, -0.12),
            Offset(0.0, -0.55),
            Offset(0.28, -0.08),
            Offset(0.52, 0.38),
            Offset(0.12, 0.22),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5), (1, 5)],
        ),
      'aries' => const AstrologySignConstellation(
          points: [
            Offset(-0.68, 0.18),
            Offset(-0.35, -0.48),
            Offset(0.0, -0.22),
            Offset(0.35, -0.48),
            Offset(0.68, 0.18),
            Offset(0.0, 0.52),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (2, 5)],
        ),
      _ => null,
    };
  }
}
