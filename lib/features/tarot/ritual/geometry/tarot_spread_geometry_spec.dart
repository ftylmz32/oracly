/// Phase 7C — immutable resolved geometry for one spread type.
library;

import 'package:flutter/foundation.dart';

import '../../domain/models/tarot_spread.dart';
import 'tarot_spread_geometry_slot.dart';
import 'tarot_spread_visual_kind.dart';

@immutable
class TarotSpreadGeometrySpec {
  const TarotSpreadGeometrySpec({
    required this.spread,
    required this.kind,
    required this.slots,
  });

  final TarotSpreadType spread;
  final TarotSpreadVisualKind kind;
  final List<TarotSpreadGeometrySlot> slots;

  int get slotCount => slots.length;

  TarotSpreadGeometrySlot slotAt(int index) {
    if (index < 0 || index >= slots.length) {
      throw StateError(
        'Geometry slot $index out of range for ${spread.name} '
        '(count=${slots.length})',
      );
    }
    return slots[index];
  }

  TarotSpreadGeometrySlot? trySlotAt(int index) {
    if (index < 0 || index >= slots.length) return null;
    return slots[index];
  }
}
