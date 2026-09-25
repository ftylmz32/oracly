/// Settled placement slots — geometry-aware (Phase 7C / 7C.1).
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
        final tileSize = TarotSpreadSettledProjection.tileSizeFor(cardSize);
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
                  tileSize: tileSize,
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
    required Size tileSize,
  }) {
    final slot = spec.slotAt(slotIndex);
    final rect =
        TarotSpreadSettledProjection.rectFor(slot, field, tileSize);
    final pos = SpreadEngine.positionAt(spread, slotIndex)!;
    final card = slotIndex < placed.length ? placed[slotIndex] : null;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: RitualSpreadSlotTile(
        label: pos.label,
        card: card,
        cardSize: cardSize,
        settledRotationRad: slot.settledRotationRad,
      ),
    );
  }
}
