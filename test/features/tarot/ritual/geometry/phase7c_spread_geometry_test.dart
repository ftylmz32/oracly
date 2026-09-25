/// Phase 7C — spread visual geometry unit tests (no provider).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_projection.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_resolver.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_validate.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_visual_kind.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads.dart';

void main() {
  group('Phase 7C mapping', () {
    test('spread → visual kind', () {
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.single),
        TarotSpreadVisualKind.single,
      );
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.threeCard),
        TarotSpreadVisualKind.threeLinear,
      );
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.fiveCard),
        TarotSpreadVisualKind.fiveLinear,
      );
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.sevenCard),
        TarotSpreadVisualKind.seven,
      );
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.celticCross),
        TarotSpreadVisualKind.celticCross,
      );
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.crossroads),
        TarotSpreadVisualKind.fiveDecision,
      );
    });
  });

  group('Phase 7C position binding', () {
    test('threeCard keys', () {
      final s = TarotSpreadGeometryResolver.resolve(TarotSpreadType.threeCard);
      expect(
        s.slots.map((e) => e.positionKey).toList(),
        ['past', 'present', 'future'],
      );
    });

    test('fiveCard keys', () {
      final s = TarotSpreadGeometryResolver.resolve(TarotSpreadType.fiveCard);
      expect(s.slots.map((e) => e.positionKey).toList(), [
        'situation',
        'hidden_influence',
        'challenge',
        'strength',
        'direction',
      ]);
    });

    test('crossroads keys', () {
      final s = TarotSpreadGeometryResolver.resolve(TarotSpreadType.crossroads);
      expect(s.slots.map((e) => e.positionKey).toList(), [
        'option_a',
        'option_b',
        'tension',
        'counsel',
        'direction',
      ]);
    });
  });

  group('Phase 7C anti-alias', () {
    test('crossroads distinct from fiveCard', () {
      final cr = TarotSpreadGeometryResolver.resolve(TarotSpreadType.crossroads);
      final five = TarotSpreadGeometryResolver.resolve(TarotSpreadType.fiveCard);
      expect(cr.kind, TarotSpreadVisualKind.fiveDecision);
      expect(five.kind, TarotSpreadVisualKind.fiveLinear);
      expect(
        TarotSpreadGeometryValidate.fiveDecisionDistinctFromFiveLinear(
          cr,
          five,
        ),
        isTrue,
      );
      expect(cr.spread.name, isNot('fiveCard'));
      expect(kSignatureCrossroads.offeredInLivePicker, isFalse);
    });
  });

  group('Phase 7C integrity + flight', () {
    test('all spreads validate and are deterministic', () {
      for (final type in TarotSpreadType.values) {
        final a = TarotSpreadGeometryResolver.resolve(type);
        final b = TarotSpreadGeometryResolver.resolve(type);
        expect(a.slotCount, type.cardCount);
        for (var i = 0; i < a.slotCount; i++) {
          expect(a.slots[i].nx, b.slots[i].nx);
          expect(a.slots[i].ny, b.slots[i].ny);
          expect(a.slots[i].positionKey, b.slots[i].positionKey);
        }
      }
    });

    test('flight targets follow draw index for three and five', () {
      for (final type in [
        TarotSpreadType.threeCard,
        TarotSpreadType.fiveCard,
      ]) {
        final spec = TarotSpreadGeometryResolver.resolve(type);
        for (var i = 0; i < spec.slotCount; i++) {
          final t = TarotSpreadFlightProjection.nextTarget(
            spec: spec,
            nextIndex: i,
          );
          expect(t, isNotNull);
          expect(
            t,
            TarotSpreadFlightProjection.targetFor(spec.slotAt(i)),
          );
        }
      }
    });

    test('single has no flight target', () {
      final spec = TarotSpreadGeometryResolver.resolve(TarotSpreadType.single);
      expect(
        TarotSpreadFlightProjection.nextTarget(spec: spec, nextIndex: 0),
        isNull,
      );
    });

    test('old spacing=82 algorithm removed from table scene state', () {
      final src = File(
        'lib/features/tarot/ritual/table/tarot_table_scene_state.dart'
            .replaceAll('/', Platform.pathSeparator),
      ).readAsStringSync();
      expect(src.contains('spacing = 82'), isFalse);
      expect(src.contains('TarotSpreadFlightProjection'), isTrue);
      expect(src.contains('TarotSpreadGeometryResolver'), isTrue);
    });
  });
}
