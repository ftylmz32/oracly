/// Phase 7C.1 — projected settled-tile bounds (fails on pre-fix center math).
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_projection.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_projection_validate.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_resolver.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_visual_kind.dart';
import 'package:oracly_new/features/tarot/theme/tarot_tokens.dart';

/// Reconstructs the 7C START HEAD settled center (ignored tile extent).
Offset _legacyCenterOf({
  required double nx,
  required double ny,
  required Size field,
}) {
  return Offset(
    field.width * 0.5 + nx * field.width * 0.42,
    field.height * 0.5 + ny * field.height * 0.38,
  );
}

void main() {
  group('7C.1 START HEAD clipping regression', () {
    test(
      'legacy fiveDecision @390 top tile extends above field (defect proof)',
      () {
        // Exact class of defect on 66fa914: centerOf ignored tile height.
        const width = 390.0;
        // Pre-7C.1 fieldHeight formula for fiveDecision.
        final fieldH = (width * 0.52).clamp(96.0, 210.0);
        final field = Size(width, fieldH);
        final cols = 2.35;
        final maxW = (width / cols).clamp(34.0, 72.0);
        final maxH = (fieldH * 0.58).clamp(56.0, 120.0);
        var cardW = maxW;
        var cardH = cardW / TarotTokens.ritualCardAspectRatio;
        if (cardH > maxH) {
          cardH = maxH;
          cardW = cardH * TarotTokens.ritualCardAspectRatio;
        }
        final tileH = cardH + 18.0;
        const ny = -0.58; // option_a / option_b top row
        final legacy = _legacyCenterOf(nx: -0.58, ny: ny, field: field);
        final legacyTop = legacy.dy - tileH / 2;
        expect(
          legacyTop,
          lessThan(0),
          reason: 'START HEAD math must clip top tiles — proves 7C.1 need',
        );

        // Remediation: extent-aware projection keeps tiles inside.
        final spec =
            TarotSpreadGeometryResolver.resolve(TarotSpreadType.crossroads);
        final pack =
            TarotSpreadGeometryProjectionValidate.layout(spec, width);
        for (final r in pack.rects) {
          expect(r.top, greaterThanOrEqualTo(-0.51));
          expect(r.bottom, lessThanOrEqualTo(pack.field.height + 0.51));
          expect(r.left, greaterThanOrEqualTo(-0.51));
          expect(r.right, lessThanOrEqualTo(pack.field.width + 0.51));
        }
      },
    );
  });

  group('7C.1 projected bounds matrix', () {
    for (final type in [
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
      TarotSpreadType.crossroads,
      TarotSpreadType.sevenCard,
      TarotSpreadType.celticCross,
    ]) {
      test('${type.name} contained + overlap rules @ 320/390/412', () {
        TarotSpreadGeometryProjectionValidate.assertAllTargetWidths(type);
      });
    }

    test('aspect ratio preserved for settled cards', () {
      for (final w in TarotSpreadGeometryProjectionValidate.widths) {
        for (final kind in [
          TarotSpreadVisualKind.threeLinear,
          TarotSpreadVisualKind.fiveLinear,
          TarotSpreadVisualKind.fiveDecision,
        ]) {
          final h = TarotSpreadSettledProjection.fieldHeightFor(kind, w);
          final card = TarotSpreadSettledProjection.cardSizeFor(
            kind: kind,
            fieldWidth: w,
            fieldHeight: h,
          );
          expect(
            card.width / card.height,
            closeTo(TarotTokens.ritualCardAspectRatio, 0.001),
          );
        }
      }
    });

    test('celtic allows only present×challenge intentional overlap', () {
      final spec =
          TarotSpreadGeometryResolver.resolve(TarotSpreadType.celticCross);
      final pack =
          TarotSpreadGeometryProjectionValidate.layout(spec, 390);
      expect(pack.rects[0].overlaps(pack.rects[1]), isTrue);
      // Non-cross pairs among staff and cross limbs must not collide.
      for (var i = 0; i < pack.rects.length; i++) {
        for (var j = i + 1; j < pack.rects.length; j++) {
          if ((i == 0 && j == 1)) continue;
          expect(
            pack.rects[i]
                .deflate(0.51)
                .overlaps(pack.rects[j].deflate(0.51)),
            isFalse,
            reason: 'unexpected overlap $i×$j',
          );
        }
      }
    });
  });
}
