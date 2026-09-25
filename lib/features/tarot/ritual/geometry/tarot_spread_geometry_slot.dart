/// Phase 7C — one normalized visual slot in a spread geometry.
library;

import 'package:flutter/foundation.dart';

@immutable
class TarotSpreadGeometrySlot {
  const TarotSpreadGeometrySlot({
    required this.index,
    required this.positionKey,
    required this.nx,
    required this.ny,
    this.settledRotationRad = 0,
  });

  /// Draw / position index (0-based).
  final int index;

  /// Canonical [TarotPosition.key] — never invented here.
  final String positionKey;

  /// Normalized X in [-1, 1], center = 0.
  final double nx;

  /// Normalized Y in [-1, 1], center = 0 (up negative in screen space after projection).
  final double ny;

  /// Aesthetic settled rotation only — not reversed-card 180°.
  final double settledRotationRad;
}

/// Raw layout point before binding to a [TarotPosition].
@immutable
class TarotSpreadLayoutPoint {
  const TarotSpreadLayoutPoint(this.nx, this.ny, [this.rotationRad = 0]);

  final double nx;
  final double ny;
  final double rotationRad;
}
