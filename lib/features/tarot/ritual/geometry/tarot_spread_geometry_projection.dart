/// Phase 7C — project normalized slots into settled / flight coordinate spaces.
library;

import 'dart:ui';

import '../../theme/tarot_tokens.dart';
import 'tarot_spread_geometry_slot.dart';
import 'tarot_spread_geometry_spec.dart';
import 'tarot_spread_visual_kind.dart';

/// Settled-area projection (LayoutBuilder field → screen Offset).
abstract final class TarotSpreadSettledProjection {
  TarotSpreadSettledProjection._();

  static double fieldHeightFor(TarotSpreadVisualKind kind, double width) {
    final h = switch (kind) {
      TarotSpreadVisualKind.single => 0.0,
      TarotSpreadVisualKind.threeLinear => width * 0.40,
      TarotSpreadVisualKind.fiveLinear => width * 0.36,
      TarotSpreadVisualKind.fiveDecision => width * 0.52,
      TarotSpreadVisualKind.seven => width * 0.50,
      TarotSpreadVisualKind.celticCross => width * 0.56,
    };
    return h.clamp(96.0, 210.0);
  }

  static Size cardSizeFor({
    required TarotSpreadVisualKind kind,
    required double fieldWidth,
    required double fieldHeight,
  }) {
    final cols = switch (kind) {
      TarotSpreadVisualKind.single => 1.0,
      TarotSpreadVisualKind.threeLinear => 3.15,
      TarotSpreadVisualKind.fiveLinear => 5.25,
      TarotSpreadVisualKind.fiveDecision => 2.35,
      TarotSpreadVisualKind.seven => 4.2,
      TarotSpreadVisualKind.celticCross => 3.8,
    };
    final maxW = (fieldWidth / cols).clamp(34.0, 72.0);
    final maxH = (fieldHeight * 0.58).clamp(56.0, 120.0);
    var w = maxW;
    var h = w / TarotTokens.ritualCardAspectRatio;
    if (h > maxH) {
      h = maxH;
      w = h * TarotTokens.ritualCardAspectRatio;
    }
    return Size(w, h);
  }

  static Offset centerOf(
    TarotSpreadGeometrySlot slot,
    Size field,
  ) {
    final cx = field.width * 0.5;
    final cy = field.height * 0.5;
    final halfW = field.width * 0.42;
    final halfH = field.height * 0.38;
    return Offset(cx + slot.nx * halfW, cy + slot.ny * halfH);
  }
}

/// Flight-actor projection (same normalized slots → CardFlightActor Offset).
abstract final class TarotSpreadFlightProjection {
  TarotSpreadFlightProjection._();

  /// Lateral span of the flight placement field (logical px).
  static const halfWidth = 100.0;

  /// Vertical nuance from [TarotSpreadGeometrySlot.ny].
  static const halfHeight = 36.0;

  /// Base lift above the deck center (CardFlightActor space).
  static const lift = -200.0;

  static Offset targetFor(TarotSpreadGeometrySlot slot) {
    return Offset(
      slot.nx * halfWidth,
      lift + slot.ny * halfHeight,
    );
  }

  static Offset? nextTarget({
    required TarotSpreadGeometrySpec spec,
    required int nextIndex,
  }) {
    if (spec.kind == TarotSpreadVisualKind.single) return null;
    final slot = spec.trySlotAt(nextIndex);
    if (slot == null) return null;
    return targetFor(slot);
  }
}
