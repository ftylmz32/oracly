/// Phase 7C.1 — project normalized slots into settled / flight spaces.
///
/// Settled projection accounts for the **rendered tile extent** so Positioned
/// cards cannot silently clip under [Clip.hardEdge].
library;

import 'dart:ui';

import '../../theme/tarot_tokens.dart';
import 'tarot_spread_geometry_slot.dart';
import 'tarot_spread_geometry_spec.dart';
import 'tarot_spread_visual_kind.dart';

/// Settled-area projection (LayoutBuilder field → screen Rect / Offset).
abstract final class TarotSpreadSettledProjection {
  TarotSpreadSettledProjection._();

  /// Label + gap above the card face inside [RitualSpreadSlotTile].
  static const labelChromeAllowance = 18.0;

  static double fieldHeightFor(TarotSpreadVisualKind kind, double width) {
    final h = switch (kind) {
      TarotSpreadVisualKind.single => 0.0,
      TarotSpreadVisualKind.threeLinear => width * 0.42,
      TarotSpreadVisualKind.fiveLinear => width * 0.38,
      TarotSpreadVisualKind.fiveDecision => width * 0.60,
      TarotSpreadVisualKind.seven => width * 0.56,
      TarotSpreadVisualKind.celticCross => width * 0.72,
    };
    return h.clamp(110.0, 260.0);
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
      TarotSpreadVisualKind.fiveDecision => 2.45,
      TarotSpreadVisualKind.seven => 4.3,
      TarotSpreadVisualKind.celticCross => 4.2,
    };
    // Cap tile height by kind density so extent-aware centers cannot collide.
    final maxTileFrac = switch (kind) {
      TarotSpreadVisualKind.single => 0.72,
      TarotSpreadVisualKind.threeLinear => 0.70,
      TarotSpreadVisualKind.fiveLinear => 0.68,
      TarotSpreadVisualKind.fiveDecision => 0.32,
      TarotSpreadVisualKind.seven => 0.33,
      TarotSpreadVisualKind.celticCross => 0.16,
    };
    final maxTileW = (fieldWidth / cols).clamp(28.0, 72.0);
    final maxTileH = (fieldHeight * maxTileFrac).clamp(48.0, 140.0);
    final maxCardH = (maxTileH - labelChromeAllowance).clamp(30.0, 120.0);
    var w = maxTileW;
    var h = w / TarotTokens.ritualCardAspectRatio;
    if (h > maxCardH) {
      h = maxCardH;
      w = h * TarotTokens.ritualCardAspectRatio;
    }
    return Size(w, h);
  }

  /// Deterministic settled render extent (card + label chrome).
  static Size tileSizeFor(Size cardSize) => Size(
        cardSize.width,
        cardSize.height + labelChromeAllowance,
      );

  /// Center of the rendered tile — span is field minus tile extent.
  static Offset centerOf(
    TarotSpreadGeometrySlot slot,
    Size field,
    Size tileSize,
  ) {
    final cx = field.width * 0.5;
    final cy = field.height * 0.5;
    final usableHalfW = (field.width - tileSize.width) / 2;
    final usableHalfH = (field.height - tileSize.height) / 2;
    if (usableHalfW <= 0 || usableHalfH <= 0) {
      return Offset(cx, cy);
    }
    return Offset(
      cx + slot.nx * usableHalfW,
      cy + slot.ny * usableHalfH,
    );
  }

  /// Full rendered tile rect in field coordinates.
  static Rect rectFor(
    TarotSpreadGeometrySlot slot,
    Size field,
    Size tileSize,
  ) {
    final c = centerOf(slot, field, tileSize);
    return Rect.fromCenter(
      center: c,
      width: tileSize.width,
      height: tileSize.height,
    );
  }
}

/// Flight-actor projection (same normalized slots → CardFlightActor Offset).
abstract final class TarotSpreadFlightProjection {
  TarotSpreadFlightProjection._();

  static const halfWidth = 100.0;
  static const halfHeight = 36.0;
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
