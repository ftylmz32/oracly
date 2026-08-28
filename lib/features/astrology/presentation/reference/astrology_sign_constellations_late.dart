/// Symbolic constellation stars + edges (Libra–Pisces).
/// Artwork only — not astronomical coordinates.
library;

import 'package:flutter/material.dart';

import 'astrology_sign_constellation_model.dart';

abstract final class AstrologySignConstellationsLate {
  AstrologySignConstellationsLate._();

  static AstrologySignConstellation? maybe(String id) {
    return switch (id) {
      'libra' => const AstrologySignConstellation(
          points: [
            Offset(-0.62, 0.05),
            Offset(0.62, 0.05),
            Offset(0.0, -0.55),
            Offset(-0.22, -0.18),
            Offset(0.22, -0.18),
            Offset(0.0, 0.48),
          ],
          edges: [(0, 3), (3, 2), (2, 4), (4, 1), (3, 5), (4, 5)],
        ),
      'scorpio' => const AstrologySignConstellation(
          points: [
            Offset(-0.6, 0.28),
            Offset(-0.32, -0.4),
            Offset(0.0, -0.12),
            Offset(0.28, 0.22),
            Offset(0.52, 0.48),
            Offset(0.62, 0.08),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5)],
        ),
      'sagittarius' => const AstrologySignConstellation(
          points: [
            Offset(-0.55, 0.28),
            Offset(-0.22, -0.12),
            Offset(0.12, -0.48),
            Offset(0.48, -0.18),
            Offset(0.58, 0.32),
            Offset(0.18, 0.42),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (3, 5)],
        ),
      'capricorn' => const AstrologySignConstellation(
          points: [
            Offset(-0.58, 0.42),
            Offset(-0.35, -0.05),
            Offset(-0.08, -0.52),
            Offset(0.28, -0.18),
            Offset(0.55, 0.32),
            Offset(0.12, 0.38),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5), (1, 5)],
        ),
      'aquarius' => const AstrologySignConstellation(
          points: [
            Offset(-0.68, 0.08),
            Offset(-0.35, -0.38),
            Offset(0.0, -0.08),
            Offset(0.35, -0.38),
            Offset(0.68, 0.08),
            Offset(0.0, 0.42),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (3, 5)],
        ),
      'pisces' => const AstrologySignConstellation(
          points: [
            Offset(-0.55, 0.22),
            Offset(-0.28, -0.42),
            Offset(0.0, -0.08),
            Offset(0.28, -0.42),
            Offset(0.55, 0.22),
            Offset(0.0, 0.48),
          ],
          edges: [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (4, 5)],
        ),
      _ => null,
    };
  }
}
