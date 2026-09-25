/// Phase 7C — validate geometry specs (fail loud in tests/dev).
library;

import '../../domain/models/spread_engine.dart';
import '../../domain/models/tarot_spread.dart';
import 'tarot_spread_geometry_spec.dart';
import 'tarot_spread_visual_kind.dart';

abstract final class TarotSpreadGeometryValidate {
  TarotSpreadGeometryValidate._();

  static void assertValid(TarotSpreadGeometrySpec spec) {
    final positions = SpreadEngine.positionsFor(spec.spread);
    if (spec.slots.length != positions.length) {
      throw StateError(
        'Geometry slot count ${spec.slots.length} != '
        'position count ${positions.length} for ${spec.spread.name}',
      );
    }
    if (spec.slots.length != spec.spread.cardCount) {
      throw StateError(
        'Geometry slot count ${spec.slots.length} != '
        'cardCount ${spec.spread.cardCount} for ${spec.spread.name}',
      );
    }
    final indices = <int>{};
    final keys = <String>{};
    for (var i = 0; i < spec.slots.length; i++) {
      final slot = spec.slots[i];
      final pos = positions[i];
      if (slot.index != pos.index || slot.index != i) {
        throw StateError(
          'Slot index mismatch at $i for ${spec.spread.name}: '
          'slot=${slot.index} position=${pos.index}',
        );
      }
      if (slot.positionKey != pos.key) {
        throw StateError(
          'Position key mismatch at $i for ${spec.spread.name}: '
          'geometry=${slot.positionKey} canonical=${pos.key}',
        );
      }
      if (!indices.add(slot.index)) {
        throw StateError('Duplicate index ${slot.index}');
      }
      if (!keys.add(slot.positionKey)) {
        throw StateError('Duplicate key ${slot.positionKey}');
      }
      if (slot.nx.abs() > 1.05 || slot.ny.abs() > 1.05) {
        throw StateError(
          'Normalized coord out of bounds for ${slot.positionKey}: '
          '(${slot.nx}, ${slot.ny})',
        );
      }
    }
    _assertNoDuplicateCenters(spec);
    _assertAntiAlias(spec);
  }

  static void _assertNoDuplicateCenters(TarotSpreadGeometrySpec spec) {
    final seen = <String, int>{};
    for (final slot in spec.slots) {
      final key =
          '${slot.nx.toStringAsFixed(3)},${slot.ny.toStringAsFixed(3)}';
      final prior = seen[key];
      if (prior != null) {
        final ok = spec.kind == TarotSpreadVisualKind.celticCross &&
            ((prior == 0 && slot.index == 1) ||
                (prior == 1 && slot.index == 0));
        if (!ok) {
          throw StateError(
            'Duplicate normalized position $key in ${spec.spread.name}',
          );
        }
      } else {
        seen[key] = slot.index;
      }
    }
  }

  static void _assertAntiAlias(TarotSpreadGeometrySpec spec) {
    if (spec.spread == TarotSpreadType.crossroads) {
      if (spec.kind != TarotSpreadVisualKind.fiveDecision) {
        throw StateError('Crossroads must use fiveDecision');
      }
      if (spec.kind == TarotSpreadVisualKind.fiveLinear) {
        throw StateError('Crossroads aliased to fiveLinear');
      }
    }
    if (spec.spread == TarotSpreadType.fiveCard &&
        spec.kind != TarotSpreadVisualKind.fiveLinear) {
      throw StateError('fiveCard must use fiveLinear');
    }
  }

  /// Distinctness of fiveDecision vs fiveLinear layouts.
  static bool fiveDecisionDistinctFromFiveLinear(
    TarotSpreadGeometrySpec decision,
    TarotSpreadGeometrySpec linear,
  ) {
    if (decision.kind != TarotSpreadVisualKind.fiveDecision) return false;
    if (linear.kind != TarotSpreadVisualKind.fiveLinear) return false;
    if (decision.slotCount != linear.slotCount) return true;
    for (var i = 0; i < decision.slotCount; i++) {
      final a = decision.slots[i];
      final b = linear.slots[i];
      if ((a.nx - b.nx).abs() > 0.02 || (a.ny - b.ny).abs() > 0.02) {
        return true;
      }
      if (a.positionKey != b.positionKey) return true;
    }
    return false;
  }
}
