/// Phase 7C — TarotSpreadType → visual geometry authority.
library;

import '../../domain/models/spread_engine.dart';
import '../../domain/models/tarot_spread.dart';
import 'tarot_spread_geometry_layouts.dart';
import 'tarot_spread_geometry_slot.dart';
import 'tarot_spread_geometry_spec.dart';
import 'tarot_spread_geometry_validate.dart';
import 'tarot_spread_visual_kind.dart';

abstract final class TarotSpreadGeometryResolver {
  TarotSpreadGeometryResolver._();

  static TarotSpreadVisualKind kindFor(TarotSpreadType type) => switch (type) {
        TarotSpreadType.single => TarotSpreadVisualKind.single,
        TarotSpreadType.threeCard => TarotSpreadVisualKind.threeLinear,
        TarotSpreadType.fiveCard => TarotSpreadVisualKind.fiveLinear,
        TarotSpreadType.sevenCard => TarotSpreadVisualKind.seven,
        TarotSpreadType.celticCross => TarotSpreadVisualKind.celticCross,
        TarotSpreadType.crossroads => TarotSpreadVisualKind.fiveDecision,
      };

  /// Deterministic, pure — no clock / randomness / I/O.
  static TarotSpreadGeometrySpec resolve(TarotSpreadType type) {
    final kind = kindFor(type);
    final positions = SpreadEngine.positionsFor(type);
    final points = TarotSpreadGeometryLayouts.pointsFor(kind);
    if (points.length != positions.length) {
      throw StateError(
        'Layout point count ${points.length} != '
        'positions ${positions.length} for ${type.name} ($kind)',
      );
    }
    final spec = TarotSpreadGeometrySpec(
      spread: type,
      kind: kind,
      slots: [
        for (var i = 0; i < positions.length; i++)
          TarotSpreadGeometrySlot(
            index: positions[i].index,
            positionKey: positions[i].key,
            nx: points[i].nx,
            ny: points[i].ny,
            settledRotationRad: points[i].rotationRad,
          ),
      ],
    );
    TarotSpreadGeometryValidate.assertValid(spec);
    return spec;
  }
}
