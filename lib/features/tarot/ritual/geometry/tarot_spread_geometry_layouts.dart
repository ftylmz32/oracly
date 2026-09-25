/// Phase 7C — const normalized layouts per [TarotSpreadVisualKind].
library;

import 'tarot_spread_geometry_slot.dart';
import 'tarot_spread_visual_kind.dart';

abstract final class TarotSpreadGeometryLayouts {
  TarotSpreadGeometryLayouts._();

  static const _crossRad = 1.5707963267948966; // π/2

  static const single = [
    TarotSpreadLayoutPoint(0, 0),
  ];

  /// past → present → future (shallow arc).
  static const threeLinear = [
    TarotSpreadLayoutPoint(-0.78, 0.06),
    TarotSpreadLayoutPoint(0, 0),
    TarotSpreadLayoutPoint(0.78, 0.06),
  ];

  /// Classical five progression (responsive shallow field).
  static const fiveLinear = [
    TarotSpreadLayoutPoint(-0.90, 0.14),
    TarotSpreadLayoutPoint(-0.45, 0.04),
    TarotSpreadLayoutPoint(0, 0),
    TarotSpreadLayoutPoint(0.45, 0.04),
    TarotSpreadLayoutPoint(0.90, 0.14),
  ];

  /// Crossroads decision: A/B → tension → counsel/direction.
  static const fiveDecision = [
    TarotSpreadLayoutPoint(-0.58, -0.58), // option_a
    TarotSpreadLayoutPoint(0.58, -0.58), // option_b
    TarotSpreadLayoutPoint(0, -0.02), // tension
    TarotSpreadLayoutPoint(-0.58, 0.58), // counsel
    TarotSpreadLayoutPoint(0.58, 0.58), // direction
  ];

  /// Readable two-row field (not a seven-wide strip).
  static const seven = [
    TarotSpreadLayoutPoint(-0.78, -0.42),
    TarotSpreadLayoutPoint(-0.26, -0.42),
    TarotSpreadLayoutPoint(0.26, -0.42),
    TarotSpreadLayoutPoint(0.78, -0.42),
    TarotSpreadLayoutPoint(-0.58, 0.48),
    TarotSpreadLayoutPoint(0, 0.48),
    TarotSpreadLayoutPoint(0.58, 0.48),
  ];

  /// Celtic cross + staff (presentation-only; not live-wired).
  static const celticCross = [
    TarotSpreadLayoutPoint(0, 0), // present
    TarotSpreadLayoutPoint(0, 0, _crossRad), // challenge (intentional cross)
    TarotSpreadLayoutPoint(0, 0.55), // distant_past
    TarotSpreadLayoutPoint(-0.55, 0), // recent_past
    TarotSpreadLayoutPoint(0, -0.55), // crown
    TarotSpreadLayoutPoint(0.55, 0), // near_future
    TarotSpreadLayoutPoint(0.92, 0.88), // self
    TarotSpreadLayoutPoint(0.92, 0.32), // environment
    TarotSpreadLayoutPoint(0.92, -0.32), // hopes
    TarotSpreadLayoutPoint(0.92, -0.88), // outcome
  ];

  static List<TarotSpreadLayoutPoint> pointsFor(TarotSpreadVisualKind kind) {
    return switch (kind) {
      TarotSpreadVisualKind.single => single,
      TarotSpreadVisualKind.threeLinear => threeLinear,
      TarotSpreadVisualKind.fiveLinear => fiveLinear,
      TarotSpreadVisualKind.fiveDecision => fiveDecision,
      TarotSpreadVisualKind.seven => seven,
      TarotSpreadVisualKind.celticCross => celticCross,
    };
  }
}
