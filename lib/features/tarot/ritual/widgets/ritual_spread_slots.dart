/// Settled placement slots — geometry-aware (Phase 7C).
library;

import 'package:flutter/material.dart';

import '../../domain/models/spread_engine.dart';
import '../../domain/models/tarot_spread.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../geometry/tarot_spread_geometry_projection.dart';
import '../geometry/tarot_spread_geometry_resolver.dart';
import '../geometry/tarot_spread_geometry_spec.dart';
import '../geometry/tarot_spread_visual_kind.dart';
import 'ritual_spread_slot_tile.dart';

class RitualSpreadSlots extends StatelessWidget {
  const RitualSpreadSlots({
    super.key,
    required this.placed,
    required this.spread,
  });

  final List<RevealCardData> placed;
  final TarotSpreadType spread;

  @override
  Widget build(BuildContext context) {
    if (spread.cardCount <= 1) return const SizedBox.shrink();
    final spec = TarotSpreadGeometryResolver.resolve(spread);
    if (spec.kind == TarotSpreadVisualKind.single) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        final fieldH =
            TarotSpreadSettledProjection.fieldHeightFor(spec.kind, width);
        final field = Size(width, fieldH);
        final cardSize = TarotSpreadSettledProjection.cardSizeFor(
          kind: spec.kind,
          fieldWidth: width,
          fieldHeight: fieldH,
        );
        return SizedBox(
          width: width,
          height: fieldH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final slot in spec.slots)
                _positionedSlot(
                  spec: spec,
                  slotIndex: slot.index,
                  field: field,
                  cardSize: cardSize,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _positionedSlot({
    required TarotSpreadGeometrySpec spec,
    required int slotIndex,
    required Size field,
    required Size cardSize,
  }) {
    final slot = spec.slotAt(slotIndex);
    final center = TarotSpreadSettledProjection.centerOf(slot, field);
    final pos = SpreadEngine.positionAt(spread, slotIndex)!;
    final card = slotIndex < placed.length ? placed[slotIndex] : null;
    final tileW = cardSize.width;
    final tileH = cardSize.height + 18;
    return Positioned(
      left: center.dx - tileW / 2,
      top: center.dy - tileH / 2,
      width: tileW,
      height: tileH,
      child: RitualSpreadSlotTile(
        label: pos.label,
        card: card,
        cardSize: cardSize,
        settledRotationRad: slot.settledRotationRad,
      ),
    );
  }
}
