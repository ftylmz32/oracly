/// Phase 7C.1 — projected settled-tile bounds validation (presentation-only).
library;

import 'dart:ui';

import '../../domain/models/tarot_spread.dart';
import 'tarot_spread_geometry_projection.dart';
import 'tarot_spread_geometry_resolver.dart';
import 'tarot_spread_geometry_spec.dart';
import 'tarot_spread_visual_kind.dart';

/// Validates that projected *rendered* tiles stay inside the geometry field.
abstract final class TarotSpreadGeometryProjectionValidate {
  TarotSpreadGeometryProjectionValidate._();

  static const epsilon = 0.51;

  /// Canonical widths for containment proofs.
  static const widths = [320.0, 390.0, 412.0];

  static ({Size field, Size card, Size tile, List<Rect> rects}) layout(
    TarotSpreadGeometrySpec spec,
    double width,
  ) {
    final fieldH =
        TarotSpreadSettledProjection.fieldHeightFor(spec.kind, width);
    final field = Size(width, fieldH);
    final card = TarotSpreadSettledProjection.cardSizeFor(
      kind: spec.kind,
      fieldWidth: width,
      fieldHeight: fieldH,
    );
    final tile = TarotSpreadSettledProjection.tileSizeFor(card);
    final rects = [
      for (final slot in spec.slots)
        TarotSpreadSettledProjection.rectFor(slot, field, tile),
    ];
    return (field: field, card: card, tile: tile, rects: rects);
  }

  static void assertContained(
    TarotSpreadGeometrySpec spec,
    double width, {
    double eps = epsilon,
  }) {
    final pack = layout(spec, width);
    final field = pack.field;
    for (var i = 0; i < pack.rects.length; i++) {
      final r = pack.rects[i];
      if (r.left < -eps ||
          r.top < -eps ||
          r.right > field.width + eps ||
          r.bottom > field.height + eps) {
        throw StateError(
          'Projected tile $i (${spec.slots[i].positionKey}) out of bounds '
          'for ${spec.spread.name} @ ${width.toInt()}: '
          'rect=$r field=${field.width}x${field.height}',
        );
      }
    }
  }

  /// Overlap check. Celtic present/challenge (indices 0,1) may intentionally cross.
  static void assertNoUnintendedOverlap(
    TarotSpreadGeometrySpec spec,
    double width, {
    double eps = epsilon,
  }) {
    final pack = layout(spec, width);
    final rects = pack.rects;
    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        if (_allowedOverlap(spec, i, j)) continue;
        final a = rects[i].deflate(eps);
        final b = rects[j].deflate(eps);
        if (a.overlaps(b)) {
          throw StateError(
            'Unintended overlap $i/${spec.slots[i].positionKey} × '
            '$j/${spec.slots[j].positionKey} for ${spec.spread.name} '
            '@ ${width.toInt()}',
          );
        }
      }
    }
  }

  /// Only Celtic present (0) × challenge (1) may intentionally overlap.
  static bool _allowedOverlap(
    TarotSpreadGeometrySpec spec,
    int i,
    int j,
  ) {
    if (spec.kind != TarotSpreadVisualKind.celticCross) return false;
    return (i == 0 && j == 1) || (i == 1 && j == 0);
  }

  static void assertAllTargetWidths(TarotSpreadType type) {
    final spec = TarotSpreadGeometryResolver.resolve(type);
    if (spec.kind == TarotSpreadVisualKind.single) return;
    for (final w in widths) {
      assertContained(spec, w);
      assertNoUnintendedOverlap(spec, w);
    }
  }
}
