/// Phase 7D — who owns the active physical card face.
///
/// Invariant: one physical card → one visual representation.
library;

import '../tarot_ritual_stage.dart';
import 'tarot_table_phase.dart';

abstract final class TarotTableActorOwnership {
  TarotTableActorOwnership._();

  /// Actor is mounted only while it owns the live physical card.
  static bool ownsActiveCard({
    required TarotTablePhase phase,
    required TarotRitualStage ritualStage,
    required int cardCount,
    required int placedCount,
  }) {
    if (phase == TarotTablePhase.intention ||
        phase == TarotTablePhase.spread ||
        phase == TarotTablePhase.preparing) {
      return false;
    }
    // Multi-card: once every slot is settled, slots own all faces.
    if (cardCount > 1 && placedCount >= cardCount) return false;
    if (phase == TarotTablePhase.draw) return true;
    if (ritualStage == TarotRitualStage.draw ||
        ritualStage == TarotRitualStage.reveal ||
        ritualStage == TarotRitualStage.place) {
      if (phase == TarotTablePhase.reading && cardCount > 1) return false;
      return true;
    }
    // Single-card reading: actor remains the sole physical face.
    if (phase == TarotTablePhase.reading && cardCount <= 1) return true;
    return false;
  }
}
