/// Honest "met before" ids from real reading history — never fake unlocks.
library;

import '../../../../core/domain/models/reading.dart';
import '../../deck/oracly_tarot_bridge.dart';

abstract final class DestemSeen {
  DestemSeen._();

  static Set<String> fromReadings(Iterable<ReadingModel> readings) {
    final ids = <String>{};
    for (final reading in readings) {
      _add(ids, reading.cardId);
      for (final card in reading.cards) {
        _add(ids, card.cardId);
      }
    }
    return ids;
  }

  static void _add(Set<String> ids, int ritualId) {
    final card = OraclyTarotBridge.byRitualId(ritualId);
    if (card != null) ids.add(card.id);
  }
}
