/// Phase 5D — reconstruct positionKey from legacy snapshots (no label inference).
library;

import '../../../core/domain/models/reading.dart';
import '../domain/models/spread_engine.dart';
import '../domain/models/tarot_spread.dart';

abstract final class TarotPositionKeyCompat {
  TarotPositionKeyCompat._();

  /// Prefer stored key; else runtime position at [snapshot.positionIndex].
  static String? resolve({
    required String? persistedSpread,
    required ReadingCardSnapshot snapshot,
  }) {
    final stored = snapshot.positionKey?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    final type = TarotSpreadType.fromPersisted(persistedSpread);
    if (type == null) return null;
    return SpreadEngine.positionAt(type, snapshot.positionIndex)?.key;
  }
}
