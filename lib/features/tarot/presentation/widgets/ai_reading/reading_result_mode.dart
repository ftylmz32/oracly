/// Presentation result mode — Narrative V2 vs legacy (Phase 7E).
///
/// Uses [NarrativeTarotLiveGate] routing truth — never card-count guessing.
library;

import '../../../domain/models/tarot_spread.dart';
import '../../../narrative/live/narrative_tarot_live_gate.dart';

enum ReadingResultMode { narrativeV2, legacy }

abstract final class ReadingResultModeResolver {
  ReadingResultModeResolver._();

  static ReadingResultMode of(TarotSpreadType? spread) {
    if (spread == null) return ReadingResultMode.legacy;
    return NarrativeTarotLiveGate.shouldUseNarrative(spread)
        ? ReadingResultMode.narrativeV2
        : ReadingResultMode.legacy;
  }

  static bool isNarrativeV2(TarotSpreadType? spread) =>
      of(spread) == ReadingResultMode.narrativeV2;
}
